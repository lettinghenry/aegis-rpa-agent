"""
AEGIS RPA Backend - Main Application Entry Point

This module initializes and configures the FastAPI application,
registers API routes and WebSocket endpoints, and manages the
application lifecycle.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

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


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "AEGIS RPA Backend",
        "version": "0.1.0"
    }


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup"""
    print("🚀 AEGIS RPA Backend starting up...")
    # TODO: Initialize ADK agent, session manager, etc.


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup resources on application shutdown"""
    print("🛑 AEGIS RPA Backend shutting down...")
    # TODO: Cleanup resources


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
