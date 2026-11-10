"""
API routes for node listing.
Reads nodes from data/settings/nodes.txt and returns JSON.
"""

import re
from pathlib import Path

from fastapi import APIRouter, HTTPException

from models.node import NodeArea, NodeType, NodeResponse

router = APIRouter(prefix="/api", tags=["nodes"])

# Path to nodes config (shared with Flutter frontend)
NODES_FILE = Path(__file__).parent.parent.parent / "data" / "settings" / "nodes.txt"


def parse_nodes_file(file_path: Path) -> list[NodeResponse]:
    """
    Parse nodes.txt with format:
        NODE_NAME  IP_ADDRESS  AREA  TYPE
    Mirrors the Dart NodeBuilder logic.
    """
    if not file_path.exists():
        raise FileNotFoundError(f"Nodes config not found: {file_path}")

    nodes = []
    content = file_path.read_text(encoding="utf-8")

    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue

        parts = re.split(r"\s+", line)
        if len(parts) < 4:
            continue

        name = parts[0]
        ip = parts[1]
        area_str = parts[2].lower()
        type_str = parts[3].lower()

        try:
            area = NodeArea(area_str)
        except ValueError:
            continue  # Skip unknown areas

        try:
            node_type = NodeType(type_str)
        except ValueError:
            continue  # Skip unknown types

        nodes.append(NodeResponse(
            id=name,
            name=name,
            ip=ip,
            area=area,
            type=node_type,
            is_online=False,
        ))

    return nodes


# Cache parsed nodes
_cached_nodes: list[NodeResponse] | None = None


@router.get("/nodes", response_model=list[NodeResponse])
async def get_nodes():
    """Get all available nodes from configuration file."""
    global _cached_nodes
    try:
        if _cached_nodes is None:
            _cached_nodes = parse_nodes_file(NODES_FILE)
        return _cached_nodes
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading nodes: {e}")


@router.post("/nodes/reload", response_model=list[NodeResponse])
async def reload_nodes():
    """Force reload nodes from configuration file."""
    global _cached_nodes
    try:
        _cached_nodes = parse_nodes_file(NODES_FILE)
        return _cached_nodes
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading nodes: {e}")


def get_node_by_id(node_id: str) -> NodeResponse | None:
    """Lookup a node by its ID. Used internally by deployment routes."""
    global _cached_nodes
    if _cached_nodes is None:
        _cached_nodes = parse_nodes_file(NODES_FILE)
    for node in _cached_nodes:
        if node.id == node_id:
            return node
    return None
