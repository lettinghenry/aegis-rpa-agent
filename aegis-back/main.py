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

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from src.models import (
    TaskInstructionRequest,
    TaskInstructionResponse,
    HistoryResponse,
    ErrorResponse,
    ExecutionSession,
    SessionSummary,
    StatusUpdate
)
from src.preprocessing import PreProcessor
from src.plan_cache import PlanCache
from src.adk_agent import ADKAgentManager
from src.session_manager import SessionManager
from src.history_store import HistoryStore
from src.websocket_manager import WebSocketManager
from src.exceptions import (
    AEGISException,
    ValidationError,
    ClientError,
    SystemError,
    SessionNotFoundError,
    InvalidSessionStateError
)
from src.logging_utils import setup_logging, get_session_logger, set_session_context, clear_session_context
from src.resource_manager import ResourceManager
from src.config import get_config

# Load configuration
config = get_config()

# Configure logging with session context support
setup_logging(
    log_level=config.LOG_LEVEL,
    use_json=config.USE_JSON_LOGS,
    log_file=config.LOG_FILE
)
logger = get_session_logger(__name__)

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
        ValidationError: If instruction validation fails
        SystemError: If session creation fails
    
    Validates: Requirement 7.1, 9.2, 9.3
    """
    try:
        logger.info(f"Received task instruction: {request.instruction}")
        
        # Pre-process and validate instruction
        validation_result, sanitized_instruction = preprocessor.validate_and_sanitize(request.instruction)
        
        if not validation_result.is_valid:
            logger.warning(f"Instruction validation failed: {validation_result.error_message}")
            from src.exceptions import InstructionValidationError
            raise InstructionValidationError(
                message="Task instruction validation failed",
                details=validation_result.error_message
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
        
    except ValidationError:
        raise
    except Exception as e:
        logger.error(f"Error starting task: {e}", exc_info=True)
        from src.exceptions import SystemError as AEGISSystemError
        raise AEGISSystemError(
            message="Failed to start task",
            details=str(e)
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
            raise SessionNotFoundError(
                session_id=session_id,
                details="Session not found in active sessions or history"
            )
        
        return session
        
    except (SessionNotFoundError, InvalidSessionStateError):
        # Let custom exceptions propagate to exception handlers
        raise
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
    
    This endpoint cancels an active execution, cleans up resources,
    and restores the frontend window to normal state.
    
    Args:
        session_id: Unique session identifier
    
    Returns:
        Success message
    
    Raises:
        HTTPException 404: If session not found
        HTTPException 400: If session already completed/cancelled
        HTTPException 500: If cancellation fails
    
    Validates: Requirements 7.4, 8.5, 13.4
    """
    try:
        logger.info(f"Cancelling execution for session: {session_id}")
        
        # Get session to check status
        session = session_manager.get_session(session_id)
        
        if not session:
            # Check history store for completed sessions
            session = history_store.get_session_details(session_id)
            if session:
                raise InvalidSessionStateError(
                    session_id=session_id,
                    current_state=session.status,
                    operation="cancel",
                    details="Session already completed and cannot be cancelled"
                )
            raise SessionNotFoundError(session_id=session_id)
        
        # Check if session can be cancelled
        if session.status in ["completed", "failed", "cancelled"]:
            raise InvalidSessionStateError(
                session_id=session_id,
                current_state=session.status,
                operation="cancel",
                details=f"Cannot cancel session with status: {session.status}"
            )
        
        # Cancel the session (this will be picked up by the queue processor)
        success = session_manager.cancel_session(session_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to cancel session"
            )
        
        # Send cancellation status update with window restore
        cancel_update = StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="cancelled",
            message="Execution cancelled by user",
            window_state="normal",
            timestamp=datetime.now()
        )
        await websocket_manager.broadcast_update(session_id, cancel_update)
        
        # Update session in manager
        session.status = "cancelled"
        session.completed_at = datetime.now()
        session.updated_at = datetime.now()
        session_manager.update_session(session_id, None)
        
        # Save to history
        history_store.save_session(session)
        
        logger.info(f"Session {session_id} cancelled successfully")
        
        return {
            "message": f"Session {session_id} cancelled successfully",
            "session_id": session_id,
            "status": "cancelled"
        }
        
    except (SessionNotFoundError, InvalidSessionStateError):
        # Let custom exceptions propagate to exception handlers
        raise
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error cancelling execution: {e}", exc_info=True)
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
    
    Integrates: Pre-Processing → Plan Cache → ADK Agent → RPA Engine → Action Observer
    Connects: Session Manager ↔ WebSocket Manager ↔ History Store
    
    Validates: Requirements 2.1, 2.3, 1.3, 6.5, 8.4, 8.5, 13.1, 13.3, 13.4, 13.5
    """
    logger.info("Starting execution queue processor")
    
    while True:
        session_id = None
        resource_manager = None
        
        try:
            # Wait for next session in queue
            session_id = await request_queue.get()
            logger.info(f"Processing session from queue: {session_id}", session_id=session_id)
            
            # Set session context for logging
            token = set_session_context(session_id)
            
            # Create resource manager for this session
            resource_manager = ResourceManager(session_id)
            
            # Get session from session manager
            session = session_manager.get_session(session_id)
            if not session:
                logger.error(f"Session {session_id} not found in queue processor", session_id=session_id)
                request_queue.task_done()
                clear_session_context(token)
                continue
            
            # Update session status to in_progress
            session.status = "in_progress"
            session.updated_at = datetime.now()
            session_manager.update_session(session_id, None)
            
            # Send initial status update via WebSocket
            initial_update = StatusUpdate(
                session_id=session_id,
                subtask=None,
                overall_status="in_progress",
                message="Starting task execution",
                timestamp=datetime.now()
            )
            await websocket_manager.broadcast_update(session_id, initial_update)
            
            try:
                # Step 1: Pre-processing already done in start_task endpoint
                # Step 2: Check plan cache for similar instructions
                cached_plan = plan_cache.get_cached_plan(session.instruction)
                
                if cached_plan:
                    logger.info(f"Cache hit for session {session_id} - using cached plan")
                    # Note: For now, we still use ADK agent even with cache hit
                    # In future, could execute cached plan directly
                    # This validates Requirement 2.3 (cache lookup performed)
                else:
                    logger.info(f"Cache miss for session {session_id} - generating new plan")
                
                # Step 3: Execute instruction using ADK Agent
                # The ADK agent will orchestrate RPA Engine and Action Observer
                window_state_sent = False
                
                async for status_update in adk_agent.execute_instruction(
                    session.instruction,
                    session_id
                ):
                    # Update session with status from ADK agent
                    session_manager.update_session(session_id, status_update)
                    
                    # Handle window state management
                    # Send WINDOW_STATE_MINIMAL before first desktop action
                    if not window_state_sent and status_update.window_state == "minimal":
                        logger.info(f"Sending WINDOW_STATE_MINIMAL for session {session_id}")
                        window_state_sent = True
                    
                    # Broadcast update via WebSocket to frontend
                    await websocket_manager.broadcast_update(session_id, status_update)
                    
                    # Check if execution completed or failed
                    if status_update.overall_status in ["completed", "failed"]:
                        # Get final session state
                        final_session = session_manager.get_session(session_id)
                        if final_session:
                            # Update completion timestamp
                            final_session.completed_at = datetime.now()
                            final_session.updated_at = datetime.now()
                            
                            # Save to history store for persistence
                            history_store.save_session(final_session)
                            logger.info(f"Session {session_id} saved to history with status: {status_update.overall_status}")
                        
                        # Ensure window is restored to normal
                        if status_update.window_state != "normal":
                            restore_update = StatusUpdate(
                                session_id=session_id,
                                subtask=None,
                                overall_status=status_update.overall_status,
                                message="Restoring window to normal state",
                                window_state="normal",
                                timestamp=datetime.now()
                            )
                            await websocket_manager.broadcast_update(session_id, restore_update)
                            logger.info(f"Sent WINDOW_STATE_NORMAL for session {session_id}")
                        
                        break
                
                # Store execution plan in cache for future reuse
                if not cached_plan:
                    # Get the executed plan from session
                    final_session = session_manager.get_session(session_id)
                    if final_session and final_session.subtasks:
                        from src.models import ExecutionPlan
                        plan = ExecutionPlan(
                            instruction=session.instruction,
                            subtasks=[
                                {
                                    "tool_name": st.tool_name,
                                    "tool_args": st.tool_args,
                                    "description": st.description
                                }
                                for st in final_session.subtasks
                            ],
                            created_at=datetime.now()
                        )
                        plan_cache.store_plan(session.instruction, plan)
                        logger.info(f"Stored execution plan in cache for session {session_id}")
                
            except asyncio.CancelledError:
                # Handle cancellation with resource cleanup
                logger.info(f"Session {session_id} execution cancelled", session_id=session_id)
                
                # Cleanup resources
                if resource_manager:
                    await resource_manager.cleanup_all(suppress_errors=True)
                
                session = session_manager.get_session(session_id)
                if session:
                    session.status = "cancelled"
                    session.completed_at = datetime.now()
                    session.updated_at = datetime.now()
                    session_manager.update_session(session_id, None)
                    
                    # Save cancelled session to history
                    history_store.save_session(session)
                    
                    # Send cancellation update with window restore
                    cancel_update = StatusUpdate(
                        session_id=session_id,
                        subtask=None,
                        overall_status="cancelled",
                        message="Execution cancelled by user",
                        window_state="normal",
                        timestamp=datetime.now()
                    )
                    await websocket_manager.broadcast_update(session_id, cancel_update)
                    logger.info(f"Sent WINDOW_STATE_NORMAL after cancellation", session_id=session_id)
                
                raise
                
            except Exception as e:
                logger.error(
                    f"Error executing session: {str(e)}",
                    session_id=session_id,
                    exc_info=True
                )
                
                # Cleanup resources on error
                if resource_manager:
                    await resource_manager.cleanup_all(suppress_errors=True)
                
                # Mark session as failed
                session = session_manager.get_session(session_id)
                if session:
                    session.status = "failed"
                    session.completed_at = datetime.now()
                    session.updated_at = datetime.now()
                    session_manager.update_session(session_id, None)
                    
                    # Save failed session to history
                    history_store.save_session(session)
                    
                    # Determine error message based on exception type
                    from src.exceptions import AEGISException
                    if isinstance(e, AEGISException):
                        error_message = e.message
                        error_details = e.details
                    else:
                        error_message = "Execution failed due to unexpected error"
                        error_details = str(e)
                    
                    # Send failure update with window restore
                    failure_update = StatusUpdate(
                        session_id=session_id,
                        subtask=None,
                        overall_status="failed",
                        message=f"{error_message}: {error_details}",
                        window_state="normal",
                        timestamp=datetime.now()
                    )
                    await websocket_manager.broadcast_update(session_id, failure_update)
                    logger.info(f"Sent WINDOW_STATE_NORMAL after failure", session_id=session_id)
            
            # Mark task as done in queue
            request_queue.task_done()
            logger.info(f"Completed processing session", session_id=session_id)
            
            # Clear session context
            if session_id:
                clear_session_context(token)
            
        except asyncio.CancelledError:
            logger.info("Execution queue processor cancelled")
            # Cleanup any remaining resources
            if resource_manager:
                await resource_manager.cleanup_all(suppress_errors=True)
            break
        except Exception as e:
            logger.error(f"Error in execution queue processor: {e}", session_id=session_id, exc_info=True)
            # Cleanup resources on error
            if resource_manager:
                await resource_manager.cleanup_all(suppress_errors=True)
            # Clear session context
            if session_id:
                clear_session_context(token)
            await asyncio.sleep(1)  # Prevent tight loop on errors


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup"""
    global preprocessor, plan_cache, adk_agent, session_manager, history_store, websocket_manager, execution_task
    
    logger.info("🚀 AEGIS RPA Backend starting up...")
    
    try:
        # Log configuration summary
        config_summary = config.get_summary()
        logger.info(f"Configuration loaded: {config_summary}")
        
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


@app.exception_handler(ValidationError)
async def validation_error_handler(request: Request, exc: ValidationError):
    """
    Handle validation errors (HTTP 422).
    
    Validates: Requirement 9.2
    """
    logger.warning(
        f"Validation error: {exc.message}",
        session_id=exc.session_id,
        extra_data=exc.context
    )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=exc.to_dict()
    )


@app.exception_handler(SessionNotFoundError)
async def session_not_found_handler(request: Request, exc: SessionNotFoundError):
    """
    Handle session not found errors (HTTP 404).
    """
    logger.warning(
        f"Session not found: {exc.message}",
        session_id=exc.session_id,
        extra_data=exc.context
    )
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content=exc.to_dict()
    )


@app.exception_handler(ClientError)
async def client_error_handler(request: Request, exc: ClientError):
    """
    Handle client errors (HTTP 400).
    """
    logger.warning(
        f"Client error: {exc.message}",
        session_id=exc.session_id,
        extra_data=exc.context
    )
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content=exc.to_dict()
    )


@app.exception_handler(SystemError)
async def system_error_handler(request: Request, exc: SystemError):
    """
    Handle system errors (HTTP 500).
    
    Validates: Requirement 8.1
    """
    logger.error(
        f"System error: {exc.message}",
        session_id=exc.session_id,
        extra_data=exc.context
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=exc.to_dict()
    )


@app.exception_handler(AEGISException)
async def aegis_exception_handler(request: Request, exc: AEGISException):
    """
    Handle all AEGIS-specific exceptions.
    """
    logger.error(
        f"AEGIS exception: {exc.message}",
        session_id=exc.session_id,
        extra_data=exc.context
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=exc.to_dict()
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Global exception handler for unhandled errors.
    
    Validates: Requirement 8.1
    """
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "InternalServerError",
            "message": "An unexpected error occurred",
            "details": str(exc)
        }
    )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=True,
        log_level=config.LOG_LEVEL.lower()
    )
