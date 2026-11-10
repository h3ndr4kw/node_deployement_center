"""
WebSocket endpoint for real-time deployment log streaming.

Frontend connects to: ws://host:port/ws/deploy/{session_id}
Messages are JSON: {"node_id": "...", "line": "...", "status": "running|done|error", "timestamp": "..."}
"""

import asyncio
import json
import logging
from datetime import datetime

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

logger = logging.getLogger(__name__)

router = APIRouter(tags=["websocket"])


class SessionManager:
    """
    Manages WebSocket connections grouped by deployment session_id.
    SSH service pushes output lines here; connected WebSocket clients receive them.
    """

    def __init__(self):
        # session_id -> list of connected WebSockets
        self._connections: dict[str, list[WebSocket]] = {}
        # session_id -> asyncio.Queue for buffering messages
        self._queues: dict[str, asyncio.Queue] = {}

    def get_or_create_queue(self, session_id: str) -> asyncio.Queue:
        """Get or create a message queue for a session."""
        if session_id not in self._queues:
            self._queues[session_id] = asyncio.Queue()
        return self._queues[session_id]

    async def connect(self, session_id: str, websocket: WebSocket):
        """Register a WebSocket connection for a session."""
        await websocket.accept()
        if session_id not in self._connections:
            self._connections[session_id] = []
        self._connections[session_id].append(websocket)
        logger.info("WebSocket connected for session %s (total: %d)",
                     session_id, len(self._connections[session_id]))

    def disconnect(self, session_id: str, websocket: WebSocket):
        """Remove a WebSocket connection from a session."""
        if session_id in self._connections:
            self._connections[session_id] = [
                ws for ws in self._connections[session_id] if ws != websocket
            ]
            if not self._connections[session_id]:
                del self._connections[session_id]
        logger.info("WebSocket disconnected for session %s", session_id)

    async def broadcast(self, session_id: str, data: dict):
        """Send a message to all WebSocket clients in a session."""
        data["timestamp"] = datetime.now().isoformat()
        message = json.dumps(data, ensure_ascii=False)

        if session_id not in self._connections:
            # No connected clients yet, buffer to queue
            queue = self.get_or_create_queue(session_id)
            await queue.put(message)
            return

        disconnected = []
        for ws in self._connections.get(session_id, []):
            try:
                await ws.send_text(message)
            except Exception:
                disconnected.append(ws)

        # Clean up disconnected sockets
        for ws in disconnected:
            self.disconnect(session_id, ws)

    async def drain_queue(self, session_id: str, websocket: WebSocket):
        """Send any buffered messages to a newly connected client."""
        if session_id in self._queues:
            queue = self._queues[session_id]
            while not queue.empty():
                try:
                    message = queue.get_nowait()
                    await websocket.send_text(message)
                except asyncio.QueueEmpty:
                    break
                except Exception:
                    break

    def cleanup_session(self, session_id: str):
        """Clean up all resources for a session."""
        self._connections.pop(session_id, None)
        self._queues.pop(session_id, None)


# Global session manager instance
session_manager = SessionManager()


@router.websocket("/ws/deploy/{session_id}")
async def websocket_deploy(websocket: WebSocket, session_id: str):
    """
    WebSocket endpoint for real-time deployment output streaming.

    Connect to this endpoint after initiating a deployment via REST API.
    The session_id is returned in the deployment response.
    """
    await session_manager.connect(session_id, websocket)

    # Send any buffered messages
    await session_manager.drain_queue(session_id, websocket)

    try:
        # Keep connection alive; listen for client messages (e.g., ping/cancel)
        while True:
            data = await websocket.receive_text()

            # Handle client messages
            try:
                msg = json.loads(data)
                if msg.get("type") == "ping":
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.now().isoformat(),
                    }))
            except json.JSONDecodeError:
                pass  # Ignore malformed client messages

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected from session %s", session_id)
    except Exception as e:
        logger.warning("WebSocket error for session %s: %s", session_id, e)
    finally:
        session_manager.disconnect(session_id, websocket)
