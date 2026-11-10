"""
PISC Node Deployment Backend API Server

FastAPI application entry point.
Provides REST API + WebSocket for remote node command deployment.
"""

import logging
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.nodes import router as nodes_router
from routes.deployment import router as deployment_router
from routes.ws import router as ws_router
from routes.schedule import router as schedule_router, start_background_scheduler
from services.ssh_service import load_ssh_config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle."""
    # Startup
    logger.info("=" * 60)
    logger.info("  PISC Node Deployment Backend Starting...")
    logger.info("=" * 60)

    # Load SSH configuration
    try:
        load_ssh_config()
        logger.info("SSH configuration loaded successfully.")
    except Exception as e:
        logger.error("Failed to load SSH configuration: %s", e)
        logger.warning("SSH operations will fail until config is fixed.")

    # Start background scheduler
    scheduler_task = asyncio.create_task(start_background_scheduler())
    logger.info("Background scheduler task created.")

    yield

    # Shutdown
    logger.info("PISC Node Deployment Backend shutting down.")
    scheduler_task.cancel()
    try:
        await scheduler_task
    except asyncio.CancelledError:
        pass


# Create FastAPI application
app = FastAPI(
    title="PISC Node Deployment API",
    description=(
        "Backend API for deploying commands to network nodes via multi-hop SSH. "
        "Supports real-time output streaming via WebSocket."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware - allow Flutter web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Development: allow all origins. Restrict in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount routers
app.include_router(nodes_router)
app.include_router(deployment_router)
app.include_router(ws_router)
app.include_router(schedule_router)


@app.get("/", tags=["health"])
async def root():
    """Health check endpoint."""
    return {
        "service": "PISC Node Deployment API",
        "version": "1.0.0",
        "status": "running",
    }


@app.get("/health", tags=["health"])
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "endpoints": {
            "nodes": "/api/nodes",
            "deploy_command": "/api/deploy/command",
            "deploy_commands": "/api/deploy/commands",
            "deploy_file": "/api/deploy/file",
            "deploy_status": "/api/deploy/status/{session_id}",
            "websocket": "/ws/deploy/{session_id}",
            "schedule": "/api/schedule",
        },
    }
