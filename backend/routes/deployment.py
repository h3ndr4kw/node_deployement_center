"""
API routes for deployment command execution.

Endpoints:
    POST /api/deploy/command   - Single command
    POST /api/deploy/commands  - Multiple commands
    POST /api/deploy/file      - Commands from uploaded file
"""

import asyncio
import uuid
import logging
from typing import Any

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, BackgroundTasks

from models.deployment import (
    SingleCommandRequest,
    MultiCommandRequest,
    DeploymentResponse,
    NodeExecutionResult,
)
from routes.nodes import get_node_by_id
from routes.ws import session_manager
from services.ssh_service import execute_on_node

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/deploy", tags=["deployment"])

# Store deployment results by session_id
deployment_results: dict[str, dict[str, Any]] = {}


async def _ws_callback(session_id: str):
    """Create a callback function bound to a WebSocket session."""
    async def callback(node_id: str, line: str, status: str):
        await session_manager.broadcast(session_id, {
            "node_id": node_id,
            "line": line,
            "status": status,
        })
    return callback


async def _run_deployment(
    session_id: str,
    node_ids: list[str],
    commands: list[str],
    execution_method: str = "broadcast",
):
    """Background task that executes commands on all target nodes."""
    callback = await _ws_callback(session_id)
    results = []

    # Resolve node IDs to node info
    tasks = []
    for node_id in node_ids:
        node = get_node_by_id(node_id)
        if node is None:
            results.append(NodeExecutionResult(
                node_id=node_id,
                node_name=node_id,
                status="failed",
                error_message=f"Node '{node_id}' not found",
            ))
            continue

        # Create async task for each node
        tasks.append(execute_on_node(
            node_name=node.name,
            node_ip=node.ip,
            commands=commands,
            callback=callback,
        ))

    # Execute all nodes (either standard/sequential or broadcast/parallel)
    if tasks:
        if execution_method == "standard":
            for task in tasks:
                try:
                    result = await task
                    results.append(NodeExecutionResult(**result))
                except Exception as e:
                    results.append(NodeExecutionResult(
                        node_id="unknown",
                        node_name="unknown",
                        status="failed",
                        error_message=str(e),
                    ))
        else:
            task_results = await asyncio.gather(*tasks, return_exceptions=True)
            for result in task_results:
                if isinstance(result, Exception):
                    results.append(NodeExecutionResult(
                        node_id="unknown",
                        node_name="unknown",
                        status="failed",
                        error_message=str(result),
                    ))
                else:
                    results.append(NodeExecutionResult(**result))

    # Determine overall status
    all_success = all(r.status == "success" for r in results)
    overall_status = "completed" if all_success else "failed"

    # Store results
    deployment_results[session_id] = {
        "session_id": session_id,
        "status": overall_status,
        "message": f"Deployment {overall_status}. {len(results)} node(s) processed.",
        "results": [r.model_dump() for r in results],
    }

    # Notify WebSocket clients that deployment is complete
    await session_manager.broadcast(session_id, {
        "node_id": "__system__",
        "line": f"Deployment {overall_status}",
        "status": "completed" if all_success else "failed",
    })

    logger.info("Deployment %s %s: %d nodes processed", session_id, overall_status, len(results))


@router.post("/command", response_model=DeploymentResponse)
async def deploy_single_command(
    request: SingleCommandRequest,
    background_tasks: BackgroundTasks,
):
    """Execute a single command on selected nodes."""
    if not request.node_ids:
        raise HTTPException(status_code=400, detail="No nodes selected")
    if not request.command.strip():
        raise HTTPException(status_code=400, detail="Command is empty")

    session_id = str(uuid.uuid4())
    commands = [request.command]

    # Initialize session result
    deployment_results[session_id] = {
        "session_id": session_id,
        "status": "started",
        "message": f"Deployment started on {len(request.node_ids)} node(s)",
        "results": [],
    }

    # Run in background
    background_tasks.add_task(
        _run_deployment,
        session_id,
        request.node_ids,
        commands,
        request.execution_method
    )

    return DeploymentResponse(
        session_id=session_id,
        status="started",
        message=f"Deployment initiated on {len(request.node_ids)} node(s). "
                f"Connect to WebSocket /ws/deploy/{session_id} for real-time updates.",
    )


@router.post("/commands", response_model=DeploymentResponse)
async def deploy_multiple_commands(
    request: MultiCommandRequest,
    background_tasks: BackgroundTasks,
):
    """Execute multiple commands on selected nodes."""
    if not request.node_ids:
        raise HTTPException(status_code=400, detail="No nodes selected")
    if not request.commands or all(not c.strip() for c in request.commands):
        raise HTTPException(status_code=400, detail="Commands list is empty")

    session_id = str(uuid.uuid4())
    commands = [c for c in request.commands if c.strip()]

    deployment_results[session_id] = {
        "session_id": session_id,
        "status": "started",
        "message": f"Deployment started on {len(request.node_ids)} node(s), {len(commands)} command(s)",
        "results": [],
    }

    background_tasks.add_task(
        _run_deployment,
        session_id,
        request.node_ids,
        commands,
        request.execution_method
    )

    return DeploymentResponse(
        session_id=session_id,
        status="started",
        message=f"Deployment initiated on {len(request.node_ids)} node(s) with {len(commands)} command(s). "
                f"Connect to WebSocket /ws/deploy/{session_id} for real-time updates.",
    )


@router.post("/file", response_model=DeploymentResponse)
async def deploy_from_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(..., description="Text file containing commands (one per line)"),
    node_ids: str = Form(..., description="Comma-separated node IDs"),
    execution_method: str = Form("broadcast", description="Execution method (broadcast or standard)"),
):
    """Execute commands from an uploaded file on selected nodes."""
    # Parse node IDs from comma-separated string
    parsed_node_ids = [nid.strip() for nid in node_ids.split(",") if nid.strip()]
    if not parsed_node_ids:
        raise HTTPException(status_code=400, detail="No nodes selected")

    # Read and parse file
    try:
        content = await file.read()
        text = content.decode("utf-8")
        commands = [line for line in text.splitlines() if line.strip()]
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error reading file: {e}")

    if not commands:
        raise HTTPException(status_code=400, detail="Uploaded file contains no commands")

    session_id = str(uuid.uuid4())

    deployment_results[session_id] = {
        "session_id": session_id,
        "status": "started",
        "message": f"Deployment started from file '{file.filename}' on {len(parsed_node_ids)} node(s)",
        "results": [],
    }

    background_tasks.add_task(
        _run_deployment,
        session_id,
        parsed_node_ids,
        commands,
        execution_method
    )

    return DeploymentResponse(
        session_id=session_id,
        status="started",
        message=f"Deployment initiated from file '{file.filename}' on {len(parsed_node_ids)} node(s), "
                f"{len(commands)} command(s). Connect to WebSocket /ws/deploy/{session_id} for real-time updates.",
    )


@router.get("/status/{session_id}", response_model=DeploymentResponse)
async def get_deployment_status(session_id: str):
    """Get the current status / result of a deployment session."""
    result = deployment_results.get(session_id)
    if result is None:
        raise HTTPException(status_code=404, detail=f"Session '{session_id}' not found")

    return DeploymentResponse(**result)
