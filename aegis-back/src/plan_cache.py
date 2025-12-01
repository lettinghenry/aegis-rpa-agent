"""
Plan Cache for AEGIS RPA Backend.

This module implements a caching mechanism for execution plans to minimize
unnecessary calls to the ADK agent. It uses embedding-based similarity
matching with cosine similarity and LRU eviction policy.
"""

import json
import hashlib
from datetime import datetime, timedelta
from typing import Optional, Dict, Tuple
from pathlib import Path
from collections import OrderedDict

from src.models import ExecutionPlan
from src.config import get_config


class PlanCache:
    """
    Cache for storing and retrieving execution plans based on instruction similarity.
    
    Uses embedding-based similarity matching with cosine similarity threshold of 0.95.
    Implements LRU eviction policy with configurable max size and TTL.
    """
    
    def __init__(
        self,
        cache_dir: Optional[Path] = None,
        max_size: Optional[int] = None,
        ttl_hours: int = 24,
        similarity_threshold: float = 0.95
    ):
        """
        Initialize the Plan Cache.
        
        Args:
            cache_dir: Directory for cache storage (defaults to config.CACHE_DIR)
            max_size: Maximum number of cached plans (defaults to config.MAX_CACHE_SIZE)
            ttl_hours: Time-to-live for cached plans in hours
            similarity_threshold: Minimum similarity score for cache hit
        """
        config = get_config()
        if cache_dir is None:
            self.cache_dir = config.CACHE_DIR
        else:
            # Convert to Path if string is provided (for backward compatibility)
            self.cache_dir = Path(cache_dir) if isinstance(cache_dir, str) else cache_dir
        self.max_size = max_size or config.MAX_CACHE_SIZE
        self.ttl = timedelta(hours=ttl_hours)
        self.similarity_threshold = similarity_threshold
        
        # In-memory cache: OrderedDict for LRU behavior
        # Key: instruction hash, Value: (ExecutionPlan, embedding, timestamp)
        self._cache: OrderedDict[str, Tuple[ExecutionPlan, list, datetime]] = OrderedDict()
        
        # Ensure cache directory exists
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        
        # Load existing cache from disk
        self._load_cache()
    
    def get_cached_plan(self, instruction: str) -> Optional[ExecutionPlan]:
        """
        Retrieve cached plan if similar instruction exists.
        
        Computes embedding for the instruction and searches for similar
        cached instructions using cosine similarity. Returns cached plan
        if similarity exceeds threshold and plan hasn't expired.
        
        Args:
            instruction: The task instruction to search for
            
        Returns:
            ExecutionPlan if cache hit, None otherwise
        """
        # Clean up expired entries first
        self._cleanup_expired()
        
        if not instruction or not instruction.strip():
            return None
        
        # Compute embedding for the instruction
        query_embedding = self._compute_embedding(instruction)
        
        # Search for similar instruction in cache
        best_match_key = None
        best_similarity = 0.0
        
        for cache_key, (plan, cached_embedding, timestamp) in self._cache.items():
            similarity = self.compute_similarity(query_embedding, cached_embedding)
            
            if similarity > best_similarity:
                best_similarity = similarity
                best_match_key = cache_key
        
        # Check if best match exceeds threshold
        if best_similarity >= self.similarity_threshold and best_match_key:
            # Move to end for LRU (most recently used)
            self._cache.move_to_end(best_match_key)
            plan, _, _ = self._cache[best_match_key]
            return plan
        
        return None
    
    def store_plan(self, instruction: str, plan: ExecutionPlan) -> None:
        """
        Store execution plan with instruction key.
        
        Computes embedding for the instruction and stores the plan with
        LRU eviction if cache is full.
        
        Args:
            instruction: The task instruction
            plan: The execution plan to cache
        """
        if not instruction or not instruction.strip():
            return
        
        # Compute embedding and hash for the instruction
        embedding = self._compute_embedding(instruction)
        cache_key = self._compute_hash(instruction)
        
        # Store in cache with timestamp
        self._cache[cache_key] = (plan, embedding, datetime.now())
        
        # Move to end for LRU (most recently used)
        self._cache.move_to_end(cache_key)
        
        # Evict oldest entry if cache exceeds max size
        if len(self._cache) > self.max_size:
            # Remove oldest (first) item
            self._cache.popitem(last=False)
        
        # Persist to disk
        self._save_cache()
    
    def compute_similarity(
        self,
        embedding1: list,
        embedding2: list
    ) -> float:
        """
        Calculate similarity score between two embeddings using cosine similarity.
        
        Cosine similarity = (A · B) / (||A|| * ||B||)
        
        Args:
            embedding1: First embedding vector (or instruction string for convenience)
            embedding2: Second embedding vector (or instruction string for convenience)
            
        Returns:
            Similarity score between 0 and 1
        """
        # Support both embeddings and strings for convenience
        if isinstance(embedding1, str):
            embedding1 = self._compute_embedding(embedding1)
        if isinstance(embedding2, str):
            embedding2 = self._compute_embedding(embedding2)
        
        if not embedding1 or not embedding2:
            return 0.0
        
        if len(embedding1) != len(embedding2):
            return 0.0
        
        # Compute dot product
        dot_product = sum(a * b for a, b in zip(embedding1, embedding2))
        
        # Compute magnitudes
        magnitude1 = sum(a * a for a in embedding1) ** 0.5
        magnitude2 = sum(b * b for b in embedding2) ** 0.5
        
        # Avoid division by zero
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
        
        # Compute cosine similarity
        similarity = dot_product / (magnitude1 * magnitude2)
        
        # Clamp to [0, 1] range (handle floating point errors)
        return max(0.0, min(1.0, similarity))
    
    def clear_cache(self) -> None:
        """Clear all cached plans from memory and disk."""
        self._cache.clear()
        self._save_cache()
    
    def _compute_embedding(self, text: str) -> list:
        """
        Compute embedding vector for text.
        
        For now, uses a simple TF-IDF-like approach with character n-grams.
        In production, this should use a proper embedding model (e.g., Sentence-BERT).
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector as list of floats
        """
        # Normalize text
        text = text.lower().strip()
        
        # Simple character n-gram based embedding (placeholder)
        # In production, replace with proper embedding model
        n = 3  # trigrams
        ngrams = {}
        
        # Extract n-grams
        for i in range(len(text) - n + 1):
            ngram = text[i:i+n]
            ngrams[ngram] = ngrams.get(ngram, 0) + 1
        
        # Create fixed-size embedding (128 dimensions)
        embedding_size = 128
        embedding = [0.0] * embedding_size
        
        # Hash n-grams to embedding dimensions
        for ngram, count in ngrams.items():
            hash_val = hash(ngram) % embedding_size
            embedding[hash_val] += count
        
        # Normalize embedding
        magnitude = sum(x * x for x in embedding) ** 0.5
        if magnitude > 0:
            embedding = [x / magnitude for x in embedding]
        
        return embedding
    
    def _compute_hash(self, text: str) -> str:
        """
        Compute hash for text to use as cache key.
        
        Args:
            text: Text to hash
            
        Returns:
            Hash string
        """
        return hashlib.sha256(text.encode()).hexdigest()
    
    def _cleanup_expired(self) -> None:
        """Remove expired entries from cache."""
        now = datetime.now()
        expired_keys = []
        
        for key, (_, _, timestamp) in self._cache.items():
            if now - timestamp > self.ttl:
                expired_keys.append(key)
        
        for key in expired_keys:
            del self._cache[key]
        
        if expired_keys:
            self._save_cache()
    
    def _save_cache(self) -> None:
        """Persist cache to disk."""
        cache_file = self.cache_dir / "plan_cache.json"
        
        # Convert cache to serializable format
        cache_data = {}
        for key, (plan, embedding, timestamp) in self._cache.items():
            cache_data[key] = {
                "plan": plan.model_dump(mode='json'),
                "embedding": embedding,
                "timestamp": timestamp.isoformat()
            }
        
        # Write to file
        with open(cache_file, 'w') as f:
            json.dump(cache_data, f, indent=2)
    
    def _load_cache(self) -> None:
        """Load cache from disk."""
        cache_file = self.cache_dir / "plan_cache.json"
        
        if not cache_file.exists():
            return
        
        try:
            with open(cache_file, 'r') as f:
                cache_data = json.load(f)
            
            # Reconstruct cache
            for key, data in cache_data.items():
                plan = ExecutionPlan(**data["plan"])
                embedding = data["embedding"]
                timestamp = datetime.fromisoformat(data["timestamp"])
                
                self._cache[key] = (plan, embedding, timestamp)
            
            # Clean up expired entries
            self._cleanup_expired()
            
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            # If cache file is corrupted, start fresh
            print(f"Warning: Failed to load cache from disk: {e}")
            self._cache.clear()
