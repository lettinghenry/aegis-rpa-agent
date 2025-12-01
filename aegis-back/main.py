"""
AEGIS RPA Backend - Main Application Entry Point

This module initializes and configures the FastAPI application,
registers API routes and WebSocket endpoints, and manages the
application lifecycle.

Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5
"""

import os
import logging
import asyncio
from typing import Optional
from datetime import datetime

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from src.models import (
    TaskInstructionRequest,
    TaskInstructionResponse,
    HistoryResponse,
    ErrorResponse,
    ExecutionSession,
    SessionSummary
)
from src.preprocessing import PreProcessor
from src.plan_cache import PlanCache
from src.adk_agent import ADKAgentManager
from src.session_manager import SessionManager
from src.history_store import HistoryStore
from src.websocket_manager import WebSocketManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI application
app = FastAPI(
    title="AEGIS RPA Backend",
    description="Cognitive, intent-driven RPA automation engine powered by Google ADK and Gemini",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global service instances
preprocessor: Optional[PreProcessor] = None
plan_cache: Optional[PlanCache] = None
adk_agent: Optional[ADKAgentManager] = None
session_manager: Optional[SessionManager] = None
history_store: Optional[HistoryStore] = None
websocket_manager: Optional[WebSocketManager] = None

# Request queue for sequential processing
request_queue: asyncio.Queue = asyncio.Queue()
execution_task: Optional[asyncio.Task] = None


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "AEGIS RPA Backend",
        "version": "0.1.0"
    }


@app.post("/api/start_task", response_model=TaskInstructionResponse, status_code=status.HTTP_200_OK)
async def start_task(request: TaskInstructionRequest):
    """
    Submit a new task instruction for execution.
    
    This endpoint receives a natural language task instruction, validates it,
    creates an execution session, and queues it for processing.
    
    Args:
        request: TaskInstructionRequest containing the instruction
    
    Returns:
        TaskInstructionResponse with session_id and status
    
    Raises:
        HTTPException 422: If instruction validation fails
        HTTPException 500: If session creation fails
    
    Validates: Requirement 7.1
    """
    try:
        logger.info(f"Received task instruction: {request.instruction}")
        
        # Pre-process and validate instruction
        validation_result, sanitized_instruction = preprocessor.validate_and_sanitize(request.instruction)
        
        if not validation_result.is_valid:
            logger.warning(f"Instruction validation failed: {validation_result.error_message}")
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=validation_result.error_message
            )
        
        # Create execution session
        session_id = session_manager.create_session(sanitized_instruction)
        logger.info(f"Created session {session_id} for instruction: {sanitized_instruction}")
        
        # Queue the session for execution
        await request_queue.put(session_id)
        
        return TaskInstructionResponse(
            session_id=session_id,
            status="pending",
            message="Task queued for execution"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to start task: {str(e)}"
        )


@app.get("/api/history", response_model=HistoryResponse, status_code=status.HTTP_200_OK)
async def get_history(limit: int = 100):
    """
    Retrieve execution history.
    
    Returns a list of all execution sessions ordered by timestamp descending.
    
    Args:
        limit: Maximum number of sessions to return (default: 100)
    
    Returns:
        HistoryResponse containing list of session summaries
    
    Raises:
        HTTPException 500: If history retrieval fails
    
    Validates: Requirement 7.2
    """
    try:
        logger.info(f"Retrieving execution history (limit: {limit})")
        
        sessions = history_store.get_all_sessions(limit=limit)
        
        return HistoryResponse(
            sessions=sessions,
            total=len(sessions)
        )
        
    except Exception as e:
        logger.error(f"Error retrieving history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve history: {str(e)}"
        )


@app.get("/api/history/{session_id}", response_model=ExecutionSession, status_code=status.HTTP_200_OK)
async def get_session_details(session_id: str):
    """
    Retrieve detailed information for a specific execution session.
    
    Args:
        session_id: Unique session identifier
    
    Returns:
        ExecutionSession with complete session details including all subtasks
    
    Raises:
        HTTPException 404: If session not found
        HTTPException 500: If retrieval fails
    
    Validates: Requirement 7.3
    """
    try:
        logger.info(f"Retrieving session details for: {session_id}")
        
        # Try to get from session manager first (for active sessions)
        session = session_manager.get_session(session_id)
        
        # If not in active sessions, try history store
        if not session:
            session = history_store.get_session_details(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Session {session_id} not found"
            )
        
        return session
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving session details: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve session details: {str(e)}"
        )


@app.delete("/api/execution/{session_id}", status_code=status.HTTP_200_OK)
async def cancel_execution(session_id: str):
    """
    Cancel an ongoing execution session.
    
    Args:
        session_id: Unique session identifier
    
    Returns:
        Success message
    
    Raises:
        HTTPException 404: If session not found
        HTTPException 400: If session already completed/cancelled
        HTTPException 500: If cancellation fails
    
    Validates: Requirement 7.4
    """
    try:
        logger.info(f"Cancelling execution for session: {session_id}")
        
        # Get session to check status
        session = session_manager.get_session(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Session {session_id} not found"
            )
        
        # Check if session can be cancelled
        if session.status in ["completed", "failed", "cancelled"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel session with status: {session.status}"
            )
        
        # Cancel the session
        success = session_manager.cancel_session(session_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to cancel session"
            )
        
        # Send window restore command via WebSocket
        await websocket_manager.send_window_state(session_id, "normal")
        
        return {
            "message": f"Session {session_id} cancelled successfully",
            "session_id": session_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error cancelling execution: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to cancel execution: {str(e)}"
        )


@app.websocket("/ws/execution/{session_id}")
async def websocket_execution(websocket: WebSocket, session_id: str):
    """
    WebSocket endpoint for real-time execution status updates.
    
    Accepts WebSocket connections and streams status updates as the
    execution progresses through subtasks.
    
    Args:
        websocket: WebSocket connection
        session_id: Unique session identifier
    
    Validates: Requirement 7.5
    """
    await websocket_manager.connect(websocket, session_id)
    
    try:
        # Keep connection alive and listen for client messages
        while True:
            # Wait for messages from client (e.g., ping/pong)
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
                logger.debug(f"Received WebSocket message from {session_id}: {data}")
            except asyncio.TimeoutError:
                # Send ping to keep connection alive
                await websocket.send_json({"type": "ping", "timestamp": datetime.now().isoformat()})
            
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for session: {session_id}")
        await websocket_manager.disconnect(session_id)
    except Exception as e:
        logger.error(f"WebSocket error for session {session_id}: {e}")
        await websocket_manager.disconnect(session_id)


async def process_execution_queue():
    """
    Background task that processes queued execution requests sequentially.
    
    This ensures that only one task executes at a time, preventing
    conflicts in desktop automation.
    """
    logger.info("Starting execution queue processor")
    
    while True:
        try:
            # Wait for next session in queue
            session_id = await request_queue.get()
            logger.info(f"Processing session from queue: {session_id}")
            
            # Get session
            session = session_manager.get_session(session_id)
            if not session:
                logger.error(f"Session {session_id} not found in queue processor")
                continue
            
            # Check plan cache
            cached_plan = plan_cache.get_cached_plan(session.instruction)
            
            if cached_plan:
                logger.info(f"Using cached plan for session {session_id}")
                # TODO: Execute cached plan
                # For now, proceed with ADK agent
            
            # Execute instruction using ADK agent
            try:
                async for status_update in adk_agent.execute_instruction(
                    session.instruction,
                    session_id
                ):
                    # Update session with status
                    session_manager.update_session(session_id, status_update)
                    
                    # Broadcast update via WebSocket
                    await websocket_manager.broadcast_update(session_id, status_update)
                    
                    # Check if execution completed or failed
                    if status_update.overall_status in ["completed", "failed"]:
                        # Save to history
                        updated_session = session_manager.get_session(session_id)
                        if updated_session:
                            history_store.save_session(updated_session)
                        break
                
            except Exception as e:
                logger.error(f"Error executing session {session_id}: {e}")
                # Mark session as failed
                session.status = "failed"
                session.completed_at = datetime.now()
                session_manager.update_session(session_id, None)
                history_store.save_session(session)
            
            # Mark task as done in queue
            request_queue.task_done()
            
        except Exception as e:
            logger.error(f"Error in execution queue processor: {e}")
            await asyncio.sleep(1)  # Prevent tight loop on errors


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup"""
    global preprocessor, plan_cache, adk_agent, session_manager, history_store, websocket_manager, execution_task
    
    logger.info("🚀 AEGIS RPA Backend starting up...")
    
    try:
        # Initialize services
        preprocessor = PreProcessor()
        logger.info("✓ PreProcessor initialized")
        
        plan_cache = PlanCache()
        logger.info("✓ PlanCache initialized")
        
        adk_agent = ADKAgentManager()
        adk_agent.initialize_agent()
        logger.info("✓ ADK Agent initialized")
        
        session_manager = SessionManager()
        logger.info("✓ SessionManager initialized")
        
        history_store = HistoryStore()
        logger.info("✓ HistoryStore initialized")
        
        websocket_manager = WebSocketManager()
        logger.info("✓ WebSocketManager initialized")
        
        # Start background execution queue processor
        execution_task = asyncio.create_task(process_execution_queue())
        logger.info("✓ Execution queue processor started")
        
        logger.info("🎉 AEGIS RPA Backend startup complete!")
        
    except Exception as e:
        logger.error(f"❌ Failed to start AEGIS RPA Backend: {e}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup resources on application shutdown"""
    global execution_task
    
    logger.info("🛑 AEGIS RPA Backend shutting down...")
    
    try:
        # Cancel background task
        if execution_task:
            execution_task.cancel()
            try:
                await execution_task
            except asyncio.CancelledError:
                pass
        
        # Close all WebSocket connections
        if websocket_manager:
            # Disconnect all sessions
            for session_id in list(websocket_manager.connections.keys()):
                await websocket_manager.disconnect(session_id)
        
        logger.info("✓ Cleanup complete")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {e}")


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal server error",
            "details": str(exc)
        }
    )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
