"""
Tier 2: Boundary & Corner Cases — Payload Validation, Constraints & Adversarial Payloads.
Tests missing fields, boundary values, oversized uploads, and special character/SQLi/XSS escaping.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestPayloadBoundaries(ServioE2ETestCase):

    def test_01_missing_required_fields_returns_400(self):
        """TC-BOUND-PAYLOAD-01: Incomplete or missing JSON fields return RFC 7807 HTTP 400."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="payload_req")

        # Missing password in signup
        resp1 = self.client.post("/api/auth/signup", {"email": "invalid_no_pass@test.com"})
        Assertions.assert_error_response(resp1, expected_status=400)

        # Missing make/model in vehicle creation
        resp2 = auth_client.post("/api/vehicles/my", {"year": 2022})
        Assertions.assert_error_response(resp2, expected_status=400)

        # Missing appointmentDate in booking
        resp3 = auth_client.post("/api/appointments", {"serviceType": "Brakes"})
        Assertions.assert_error_response(resp3, expected_status=400)

    def test_02_invalid_vehicle_year_boundary(self):
        """TC-BOUND-PAYLOAD-02: Extreme vehicle year boundary values (<1900, >2100) return 400."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="year_boundary")

        resp1 = auth_client.post("/api/vehicles/my", {"make": "Ford", "model": "Model T", "year": 1850})
        Assertions.assert_error_response(resp1, expected_status=400)

        resp2 = auth_client.post("/api/vehicles/my", {"make": "Tesla", "model": "Cybertruck", "year": 3000})
        Assertions.assert_error_response(resp2, expected_status=400)

    def test_03_oversized_file_upload_limit(self):
        """TC-BOUND-PAYLOAD-03: Inspection photo upload exceeding 10MB size limit returns 400."""
        admin_client = self.get_admin_client()
        # Create 11MB fake byte buffer
        oversized_bytes = b"0" * (11 * 1024 * 1024)

        fields = {"jobCardId": "101", "photoType": "DAMAGE"}
        files = {"file": ("giant_photo.jpg", oversized_bytes, "image/jpeg")}

        resp = admin_client.post_multipart("/api/admin/job-card-photos/upload", fields=fields, files=files)
        Assertions.assert_error_response(resp, expected_status=400, expected_message_contains="10MB")

    def test_04_special_characters_sql_injection_xss_escaping(self):
        """TC-BOUND-PAYLOAD-04: Adversarial strings (SQLi, XSS, Unicode emojis) in inputs."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="adversarial")

        adversarial_strings = [
            "'; DROP TABLE appointments; --",
            "<script>alert('XSS')</script>",
            "🚗 Multi-lingual Special Notes & ⚡️ High Voltage Inspection 🛠️",
            "SELECT * FROM users WHERE '1'='1'",
            "../../../../etc/shadow"
        ]

        for s in adversarial_strings:
            # 1. Test search with SQLi/XSS string
            search_resp = self.client.get("/api/services/search", params={"q": s})
            self.assertEqual(search_resp.status, 200, f"Search failed on adversarial string: {s}")

            # 2. Test chat message with adversarial content
            chat_resp = auth_client.post("/api/repairs/1/messages", {"message": s})
            self.assertEqual(chat_resp.status, 200, f"Chat failed on adversarial string: {s}")
            self.assertEqual(chat_resp.json["data"]["message"], s)
