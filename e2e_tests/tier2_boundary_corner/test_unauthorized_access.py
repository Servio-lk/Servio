"""
Tier 2: Boundary & Corner Cases — Security, Authentication & Role-Based Authorization.
Tests unauthenticated requests (HTTP 401) and forbidden cross-role access (HTTP 403).
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestUnauthorizedAccess(ServioE2ETestCase):

    def test_01_unauthenticated_request_to_protected_endpoint_returns_401(self):
        """TC-BOUND-SEC-01: Requests without Authorization Bearer header return HTTP 401."""
        endpoints = [
            ("GET", "/api/auth/profile"),
            ("GET", "/api/appointments/my"),
            ("GET", "/api/vehicles/my"),
            ("POST", "/api/appointments"),
            ("POST", "/api/vehicles/my"),
            ("POST", "/api/repairs/1/messages"),
        ]

        for method, path in endpoints:
            resp = self.client.request(method, path)
            self.assertEqual(resp.status, 401, f"Expected 401 for unauthenticated {method} {path}, got {resp.status}")

    def test_02_invalid_bearer_token_returns_401(self):
        """TC-BOUND-SEC-02: Requests with forged or invalid Bearer tokens return HTTP 401."""
        invalid_client = self.get_new_client(token="forged_invalid_jwt_token_signature_xyz")
        resp = invalid_client.get("/api/auth/profile")
        self.assertEqual(resp.status, 401)

    def test_03_customer_accessing_admin_endpoints_returns_403(self):
        """TC-BOUND-SEC-03: Regular customer tokens accessing /api/admin/** return HTTP 403 Forbidden."""
        customer_client, _, _ = self.create_and_login_user(email_prefix="cust_forbidden")

        admin_endpoints = [
            ("GET", "/api/admin/dashboard/stats"),
            ("POST", "/api/admin/job-card-photos"),
            ("GET", "/actuator/metrics"),
        ]

        for method, path in admin_endpoints:
            resp = customer_client.request(method, path)
            self.assertEqual(resp.status, 403, f"Expected 403 for customer accessing {method} {path}, got {resp.status}")

    def test_04_cancelling_other_users_appointment_returns_403(self):
        """TC-BOUND-SEC-04: User A attempting to cancel User B's appointment is rejected with 403."""
        client_a, _, _ = self.create_and_login_user(email_prefix="victim_a")
        client_b, _, _ = self.create_and_login_user(email_prefix="attacker_b")

        # User A creates appointment
        create_resp = client_a.post("/api/appointments", {
            "serviceType": "Oil Change",
            "appointmentDate": "2026-11-28T09:00:00"
        })
        appt_id = create_resp.json["data"]["id"]

        # User B attempts to cancel User A's appointment
        cancel_resp = client_b.post(f"/api/appointments/{appt_id}/cancel")
        self.assertEqual(cancel_resp.status, 403)
