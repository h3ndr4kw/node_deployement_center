"""
SSH Service for multi-hop SSH connections to network nodes.

Architecture:
    Backend → SSH to Jump Server (Bastion) → SSH to Target Node

Uses Netmiko for reliable prompt detection and command execution.
"""

import asyncio
import re
import logging
from pathlib import Path
from typing import Callable, Any

import toml
from netmiko import ConnectHandler
from netmiko.exceptions import (
    NetmikoTimeoutException,
    NetmikoAuthenticationException,
)
from paramiko.ssh_exception import SSHException

from services.log_service import LogSession

logger = logging.getLogger(__name__)

# Path to SSH config file
CONFIG_PATH = Path(__file__).parent.parent / "config" / "ssh_config.toml"


class SSHConfig:
    """Loads and manages SSH configuration from TOML file."""

    def __init__(self, config_path: Path = CONFIG_PATH):
        self._config = toml.load(str(config_path))

    @property
    def jump_host(self) -> dict:
        return self._config.get("jump_host", {})

    @property
    def default_node(self) -> dict:
        return self._config.get("default_node", {})

    @property
    def ssh_settings(self) -> dict:
        return self._config.get("ssh", {})

    def get_node_credentials(self, node_name: str) -> dict:
        """Get credentials for a specific node, with per-node overrides."""
        overrides = self._config.get("node_overrides", {})
        if node_name in overrides:
            creds = dict(self.default_node)
            creds.update(overrides[node_name])
            return creds
        return dict(self.default_node)

    @property
    def prompt_regex(self) -> str:
        return self.ssh_settings.get("prompt_regex", r"[\w\-\.]+[#>$%]\s*$")

    @property
    def command_timeout(self) -> int:
        return self.ssh_settings.get("command_timeout", 60)

    @property
    def login_timeout(self) -> int:
        return self.ssh_settings.get("login_timeout", 30)

    @property
    def read_delay(self) -> float:
        return self.ssh_settings.get("read_delay", 0.5)


# Global config instance loaded at startup
_ssh_config: SSHConfig | None = None


def load_ssh_config():
    """Load SSH config at application startup."""
    global _ssh_config
    _ssh_config = SSHConfig()
    logger.info("SSH configuration loaded from %s", CONFIG_PATH)


def get_ssh_config() -> SSHConfig:
    """Get the loaded SSH config instance."""
    if _ssh_config is None:
        load_ssh_config()
    return _ssh_config


class SSHSession:
    """
    Manages a multi-hop SSH session:
      Step 1: Connect to Jump Server (Bastion)
      Step 2: From Jump Server, SSH to Target Node
    """

    def __init__(self, node_name: str, node_ip: str,
                 callback: Callable[[str, str, str], Any] | None = None):
        """
        Args:
            node_name: Name of the target node (e.g., "GGTBE2")
            node_ip: IP address of the target node
            callback: Async callback(node_id, line, status) for real-time streaming
        """
        self.node_name = node_name
        self.node_ip = node_ip
        self.callback = callback
        self.config = get_ssh_config()
        self.jump_connection = None
        self.log_session: LogSession | None = None
        self._connected = False

    async def _emit(self, line: str, status: str = "running"):
        """Send output line to callback (WebSocket) and log."""
        if self.log_session:
            self.log_session.write(line)
        if self.callback:
            try:
                await self.callback(self.node_name, line, status)
            except Exception as e:
                logger.warning("Callback error for %s: %s", self.node_name, e)

    async def connect(self) -> bool:
        """
        Establish multi-hop SSH connection.
        Returns True if successful, False otherwise.
        """
        try:
            # -- Step 1: Connect to Jump Server --
            await self._emit(f"Connecting to Jump Server {self.config.jump_host.get('ip')}...")

            jump_params = {
                "device_type": "linux",
                "host": self.config.jump_host["ip"],
                "port": self.config.jump_host.get("port", 22),
                "username": self.config.jump_host["username"],
                "password": self.config.jump_host.get("password", ""),
                "timeout": self.config.login_timeout,
                "session_log": None,
            }

            # Use SSH key if configured
            key_path = self.config.jump_host.get("ssh_key_path")
            if key_path:
                jump_params["use_keys"] = True
                jump_params["key_file"] = key_path

            # Run blocking Netmiko connect in thread pool
            self.jump_connection = await asyncio.to_thread(
                ConnectHandler, **jump_params
            )

            await self._emit("Connected to Jump Server successfully.")

            # -- Step 2: SSH from Jump Server to Target Node --
            node_creds = self.config.get_node_credentials(self.node_name)
            await self._emit(f"Connecting to target node {self.node_name} ({self.node_ip})...")

            ssh_command = f"ssh {node_creds['username']}@{self.node_ip}"
            await self._emit(f"Executing: {ssh_command}")

            # Send SSH command to jump server shell
            output = await asyncio.to_thread(
                self.jump_connection.send_command,
                ssh_command,
                expect_string=r"[Pp]assword:|[Yy]es/[Nn]o|" + self.config.prompt_regex,
                read_timeout=self.config.login_timeout,
            )

            await self._emit(output.strip())

            # Handle SSH host key confirmation
            if re.search(r"[Yy]es/[Nn]o", output):
                output = await asyncio.to_thread(
                    self.jump_connection.send_command,
                    "yes",
                    expect_string=r"[Pp]assword:|" + self.config.prompt_regex,
                    read_timeout=self.config.login_timeout,
                )
                await self._emit(output.strip())

            # Handle password prompt
            if re.search(r"[Pp]assword:", output):
                # We must use cmd_verify=False because passwords are not echoed back by the terminal.
                # If cmd_verify=True, Netmiko will timeout waiting to see the password string in the output.
                output = await asyncio.to_thread(
                    self.jump_connection.send_command,
                    node_creds.get("password", ""),
                    expect_string=self.config.prompt_regex,
                    read_timeout=self.config.login_timeout,
                    cmd_verify=False,
                )
                await self._emit(output.strip())

            self._connected = True
            await self._emit(f"Successfully connected to {self.node_name}.")
            return True

        except NetmikoTimeoutException as e:
            error_msg = f"SSH timeout connecting to {self.node_name}: {e}"
            logger.error(error_msg)
            await self._emit(error_msg, status="error")
            return False

        except NetmikoAuthenticationException as e:
            error_msg = f"SSH authentication failed for {self.node_name}: {e}"
            logger.error(error_msg)
            await self._emit(error_msg, status="error")
            return False

        except SSHException as e:
            error_msg = f"SSH error for {self.node_name}: {e}"
            logger.error(error_msg)
            await self._emit(error_msg, status="error")
            return False

        except Exception as e:
            error_msg = f"Unexpected error connecting to {self.node_name}: {e}"
            logger.error(error_msg, exc_info=True)
            await self._emit(error_msg, status="error")
            return False

    async def execute_commands(self, commands: list[str]) -> bool:
        """
        Execute a list of commands on the target node, one by one.
        Waits for prompt to be ready before sending next command.

        Returns True if all commands executed successfully.
        """
        if not self._connected or not self.jump_connection:
            await self._emit("Not connected. Cannot execute commands.", status="error")
            return False

        try:
            for i, command in enumerate(commands, 1):
                cmd_stripped = command.strip()
                if not cmd_stripped:
                    continue

                await self._emit(f"[{i}/{len(commands)}] Executing: {cmd_stripped}")

                # Send command and wait for prompt
                output = await asyncio.to_thread(
                    self.jump_connection.send_command,
                    cmd_stripped,
                    expect_string=self.config.prompt_regex,
                    read_timeout=self.config.command_timeout,
                    strip_command=False,
                    strip_prompt=False,
                )

                # Stream each line of output
                for line in output.splitlines():
                    await self._emit(line)

                # Small delay between commands for stability
                await asyncio.sleep(self.config.read_delay)

            await self._emit("All commands executed successfully.", status="done")
            return True

        except NetmikoTimeoutException as e:
            error_msg = f"Command timeout on {self.node_name}: {e}"
            logger.error(error_msg)
            await self._emit(error_msg, status="error")
            return False

        except Exception as e:
            error_msg = f"Error executing commands on {self.node_name}: {e}"
            logger.error(error_msg, exc_info=True)
            await self._emit(error_msg, status="error")
            return False

    async def disconnect(self):
        """Clean disconnection: logout from node, then from jump server."""
        try:
            if self._connected and self.jump_connection:
                await self._emit("Disconnecting from target node...")

                # Send exit to leave the target node SSH
                try:
                    await asyncio.to_thread(
                        self.jump_connection.send_command,
                        "exit",
                        expect_string=self.config.prompt_regex + r"|logout|closed",
                        read_timeout=10,
                    )
                except Exception:
                    pass  # Best effort

                await self._emit("Disconnected from target node.")

            if self.jump_connection:
                await self._emit("Disconnecting from Jump Server...")
                await asyncio.to_thread(self.jump_connection.disconnect)
                await self._emit("Disconnected from Jump Server.")

            self._connected = False

        except Exception as e:
            logger.warning("Error during disconnect for %s: %s", self.node_name, e)
            self._connected = False


async def execute_on_node(
    node_name: str,
    node_ip: str,
    commands: list[str],
    callback: Callable[[str, str, str], Any] | None = None,
) -> dict:
    """
    High-level function to execute commands on a single node.
    Handles full lifecycle: connect → execute → disconnect → log.

    Returns dict with status and log_path.
    """
    log_session = LogSession(node_name)
    session = SSHSession(node_name, node_ip, callback=callback)
    session.log_session = log_session

    try:
        log_session.open()
        log_session.write_separator("SSH Connection")

        connected = await session.connect()
        if not connected:
            log_session.close("Failed - Connection Error")
            return {
                "node_id": node_name,
                "node_name": node_name,
                "status": "failed",
                "log_path": log_session.get_relative_path(),
                "error_message": f"Failed to connect to {node_name}",
            }

        log_session.write_separator("Command Execution")
        success = await session.execute_commands(commands)

        log_session.write_separator("Disconnection")
        await session.disconnect()

        status = "success" if success else "failed"
        log_session.close("Success" if success else "Failed - Command Error")

        return {
            "node_id": node_name,
            "node_name": node_name,
            "status": status,
            "log_path": log_session.get_relative_path(),
            "error_message": None if success else f"Command execution failed on {node_name}",
        }

    except Exception as e:
        logger.error("Fatal error executing on %s: %s", node_name, e, exc_info=True)
        log_session.close(f"Failed - {e}")
        return {
            "node_id": node_name,
            "node_name": node_name,
            "status": "failed",
            "log_path": log_session.get_relative_path(),
            "error_message": str(e),
        }
