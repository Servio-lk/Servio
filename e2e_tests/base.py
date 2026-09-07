"""
Base Test Case for Servio E2E Test Suite.
Handles environment detection, mock server fallback, and authenticated test fixtures.
"""
import os
import unittest
import uuid
from e2e_tests.config import (
    BACKEND_BASE_URL,
    E2E_MOCK_MODE,
    is_port_open,
)
from e2e_tests.utils.http_client import HttpClient
from e2e_tests.utils.assertions import Assertions
from e2e_tests.utils.mock_server import ensure_mock_server_running


class ServioE2ETestCase(unittest.TestCase):
    """Base class for all E2E test cases."""
    client: HttpClient
    base_url: str

    @classmethod
    def setUpClass(cls):
        # Determine whether to use live server or start oracle mock
        use_mock = False
        if E2E_MOCK_MODE in ("1", "true", "mock"):
            use_mock = True
        elif E2E_MOCK_MODE == "auto":
            # Check if live server is reachable on port 3001
            live_port_open = is_port_open("127.0.0.1", 3001)
            if not live_port_open:
                use_mock = True

        if use_mock:
            cls.base_url = ensure_mock_server_running(port=3001)
        else:
            cls.base_url = BACKEND_BASE_URL

        cls.client = HttpClient(base_url=cls.base_url)

    def get_new_client(self, token: str = None) -> HttpClient:
        """Returns a new isolated HttpClient instance."""
        return HttpClient(base_url=self.base_url, token=token)

    def create_and_login_user(self, email_prefix: str = "customer", role: str = "USER"):
        """Helper to create a unique test user and return (client, user_dict, token)."""
        unique_id = uuid.uuid4().hex[:8]
        email = f"{email_prefix}_{unique_id}@servio-test.com"
        password = "SecurePassword123!"
        full_name = f"Test User {unique_id}"

        resp = self.client.post("/api/auth/signup", {
            "email": email,
            "password": password,
            "fullName": full_name,
            "phone": "+15551234567"
        })
        Assertions.assert_api_response_success(resp, expected_status=201)
        token = resp.json["data"]["token"]
        user_data = resp.json["data"]["user"]

        auth_client = self.get_new_client(token=token)
        return auth_client, user_data, token

    def get_admin_client(self):
        """Helper to login as Admin and return authenticated HttpClient."""
        resp = self.client.post("/api/auth/login", {
            "email": "admin@servio.com",
            "password": "AdminPassword123!"
        })
        Assertions.assert_api_response_success(resp, expected_status=200)
        token = resp.json["data"]["token"]
        return self.get_new_client(token=token)
