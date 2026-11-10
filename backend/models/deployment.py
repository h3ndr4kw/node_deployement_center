"""
Pydantic models for deployment request/response schemas.
"""

from pydantic import BaseModel


class SingleCommandRequest(BaseModel):
    """Execute a single command on selected nodes."""
    node_ids: list[str]
    command: str
    activity_name: str = ""
    execution_method: str = "broadcast"


class MultiCommandRequest(BaseModel):
    """Execute multiple commands on selected nodes."""
    node_ids: list[str]
    commands: list[str]
    activity_name: str = ""
    execution_method: str = "broadcast"


class NodeExecutionResult(BaseModel):
    """Result of command execution on a single node."""
    node_id: str
    node_name: str
    status: str  # "success" | "failed"
    log_path: str | None = None
    error_message: str | None = None


class DeploymentResponse(BaseModel):
    """Response returned when a deployment is initiated."""
    session_id: str
    status: str  # "started" | "completed" | "failed"
    message: str
    results: list[NodeExecutionResult] = []
