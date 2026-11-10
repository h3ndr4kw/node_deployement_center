"""
Log service for deployment session logging.

Creates structured log files at:
    data/epg/output/deployement/[YYYY-MM-DD]/[NODE_NAME]_[YYYYMMDD_HHMMSS].log
"""

import os
from datetime import datetime
from pathlib import Path

# Base directory relative to the backend root
BASE_LOG_DIR = Path(__file__).parent.parent / "data" / "epg" / "output" / "deployement"


class LogSession:
    """Manages a single log file for one node execution."""

    def __init__(self, node_name: str):
        self.node_name = node_name
        self.start_time = datetime.now()
        self.log_path = self._create_log_path()
        self._file_handle = None

    def _create_log_path(self) -> Path:
        date_dir = self.start_time.strftime("%Y-%m-%d")
        filename = f"{self.node_name}_{self.start_time.strftime('%Y%m%d_%H%M%S')}.log"
        log_dir = BASE_LOG_DIR / date_dir
        log_dir.mkdir(parents=True, exist_ok=True)
        return log_dir / filename

    def open(self):
        """Open the log file for writing."""
        self._file_handle = open(self.log_path, "w", encoding="utf-8")
        self.write_header()

    def write_header(self):
        """Write session header to log file."""
        header = (
            f"{'=' * 70}\n"
            f"  Node Deployment Log\n"
            f"  Node: {self.node_name}\n"
            f"  Start Time: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"{'=' * 70}\n\n"
        )
        self._write_raw(header)

    def write(self, line: str):
        """Write a timestamped line to the log."""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        self._write_raw(f"[{timestamp}] {line}\n")

    def write_separator(self, label: str = ""):
        """Write a visual separator with optional label."""
        if label:
            self._write_raw(f"\n--- {label} ---\n")
        else:
            self._write_raw(f"\n{'-' * 50}\n")

    def write_footer(self, status: str):
        """Write session footer showing completion status."""
        end_time = datetime.now()
        duration = end_time - self.start_time
        footer = (
            f"\n{'=' * 70}\n"
            f"  End Time: {end_time.strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"  Duration: {duration}\n"
            f"  Status: {status}\n"
            f"{'=' * 70}\n"
        )
        self._write_raw(footer)

    def _write_raw(self, text: str):
        """Write raw text to file (no timestamp prefix)."""
        if self._file_handle and not self._file_handle.closed:
            self._file_handle.write(text)
            self._file_handle.flush()

    def close(self, status: str = "Completed"):
        """Flush and close the log file."""
        if self._file_handle and not self._file_handle.closed:
            self.write_footer(status)
            self._file_handle.flush()
            self._file_handle.close()

    def get_relative_path(self) -> str:
        """Return relative path from backend root for API response."""
        try:
            return str(self.log_path.relative_to(Path(__file__).parent.parent))
        except ValueError:
            return str(self.log_path)

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        status = "Failed" if exc_type else "Completed"
        self.close(status)
        return False
