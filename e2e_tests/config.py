"""
Servio E2E Test Suite Configuration
"""
import os
import socket

# Base URLs
DEFAULT_BACKEND_URL = "http://127.0.0.1:3001"
DEFAULT_FRONTEND_URL = "http://127.0.0.1:5173"

BACKEND_BASE_URL = os.environ.get("SERVIO_BASE_URL", DEFAULT_BACKEND_URL).rstrip("/")
FRONTEND_BASE_URL = os.environ.get("FRONTEND_BASE_URL", DEFAULT_FRONTEND_URL).rstrip("/")

# Execution mode: 'live', 'mock', or 'auto' (auto-detects if live server reachable)
E2E_MOCK_MODE = os.environ.get("SERVIO_E2E_MOCK", "auto").lower()

# Verbose logging
VERBOSE = os.environ.get("E2E_VERBOSE", "0") in ("1", "true", "True")

# Default timeouts
DEFAULT_TIMEOUT = float(os.environ.get("E2E_TIMEOUT", "10.0"))


def is_port_open(host: str, port: int, timeout: float = 0.5) -> bool:
    """Check if a network port is reachable."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False


def get_effective_backend_url() -> str:
    """Returns the effective backend URL, dynamically adjusted if mock server is running."""
    return os.environ.get("SERVIO_BASE_URL", BACKEND_BASE_URL)
