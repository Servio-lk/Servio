"""
Tier 2: Boundary & Corner Cases — Unified UUID Identifier Validation.
Tests malformed UUID strings, non-existent UUID paths, and RFC 7807 error responses (R1 compliance).
"""
import uuid
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestUuidValidation(ServioE2ETestCase):

    def test_01_malformed_uuid_in_path_returns_400_or_404(self):
        """TC-BOUND-UUID-01: Malformed non-UUID strings in ID paths return clean 400/404 errors."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="uuid_malformed")
        malformed_ids = [
            "not-a-uuid",
            "12345",
            "../../../etc/passwd",
            "undefined",
            "null",
            "00000000-0000-0000-0000-00000000000Z"  # invalid character
        ]

        for bad_id in malformed_ids:
            resp = auth_client.get(f"/api/vehicles/{bad_id}")
            self.assertIn(resp.status, (400, 404), f"Expected 400 or 404 for bad id '{bad_id}', got {resp.status}")
            self.assertNotEqual(resp.status, 500, f"Server threw unhandled 500 on bad UUID '{bad_id}'")

    def test_02_non_existent_uuid_returns_404_not_found(self):
        """TC-BOUND-UUID-02: Valid UUID format for non-existent record returns RFC 7807 404."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="uuid_missing")
        non_existent_uuid = str(uuid.uuid4())

        resp = auth_client.get(f"/api/vehicles/{non_existent_uuid}")
        Assertions.assert_error_response(
            resp,
            expected_status=404,
            expected_error_contains="Not Found"
        )

    def test_03_all_created_entities_contain_valid_uuids(self):
        """TC-BOUND-UUID-03: Asserts user and vehicle creations consistently return UUID v4."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="uuid_verify")
        self.assertTrue(Assertions.is_valid_uuid(user_data["id"]))

        veh_resp = auth_client.post("/api/vehicles/my", {
            "make": "Genesis",
            "model": "GV70",
            "year": 2024
        })
        veh_data = Assertions.assert_api_response_success(veh_resp, expected_status=201)
        self.assertTrue(Assertions.is_valid_uuid(veh_data["data"]["id"]))
        self.assertTrue(Assertions.is_valid_uuid(veh_data["data"]["userId"]))
