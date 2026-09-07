"""
Tier 1: Feature Coverage — Authentication & User Identity APIs.
Tests signup, login, Supabase token exchange, profile retrieval, mechanic lookup, and account deletion.
"""
import uuid
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestAuthenticationFeature(ServioE2ETestCase):

    def test_01_signup_new_user_success(self):
        """TC-AUTH-01: Validates customer registration with unified UUID identity."""
        unique_suffix = uuid.uuid4().hex[:6]
        email = f"signup_test_{unique_suffix}@servio-test.com"
        payload = {
            "email": email,
            "password": "SecurePassword123!",
            "fullName": f"New Customer {unique_suffix}",
            "phone": "+15551234567"
        }

        resp = self.client.post("/api/auth/signup", payload)
        data = Assertions.assert_api_response_success(resp, expected_status=201)

        user_info = data.get("data", {}).get("user", {})
        user_id = user_info.get("id")
        self.assertTrue(Assertions.is_valid_uuid(user_id), f"Expected User ID to be UUID, got {user_id}")
        self.assertEqual(user_info.get("email"), email)
        self.assertEqual(user_info.get("role"), "USER")
        self.assertIsNotNone(data.get("data", {}).get("token"))

    def test_02_login_existing_user_success(self):
        """TC-AUTH-02: Validates email and password authentication returning JWT."""
        unique_suffix = uuid.uuid4().hex[:6]
        email = f"login_test_{unique_suffix}@servio-test.com"
        password = "ValidUserPassword123!"

        # Register first
        self.client.post("/api/auth/signup", {
            "email": email,
            "password": password,
            "fullName": "Login Tester"
        })

        # Login
        resp = self.client.post("/api/auth/login", {
            "email": email,
            "password": password
        })
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        token = data.get("data", {}).get("token")
        self.assertIsNotNone(token)
        self.assertTrue(len(token) > 10)
        self.assertEqual(data.get("data", {}).get("user", {}).get("email"), email)

    def test_03_supabase_jwt_exchange_success(self):
        """TC-AUTH-03: Validates Supabase JWT exchange for Spring Boot backend JWT (R1 compliance)."""
        unique_suffix = uuid.uuid4().hex[:6]
        email = f"supabase_user_{unique_suffix}@servio-test.com"
        payload = {
            "accessToken": f"sb_mock_token_{unique_suffix}",
            "email": email,
            "fullName": "Supabase Mobile Customer",
            "phone": "+15559876543",
            "role": "USER"
        }

        resp = self.client.post("/api/auth/supabase-login", payload)
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        user_info = data.get("data", {}).get("user", {})
        self.assertTrue(Assertions.is_valid_uuid(user_info.get("id")))
        self.assertEqual(user_info.get("email"), email)

    def test_04_get_user_profile_authenticated(self):
        """TC-AUTH-04: Validates fetching profile via Authorization: Bearer header."""
        auth_client, user_data, token = self.create_and_login_user(email_prefix="profile_check")

        resp = auth_client.get("/api/auth/profile")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        profile = data.get("data", {})
        self.assertEqual(profile.get("id"), user_data.get("id"))
        self.assertEqual(profile.get("email"), user_data.get("email"))
        self.assertEqual(profile.get("role"), "USER")

    def test_05_mechanic_registration_lookup(self):
        """TC-AUTH-05: Validates pre-registered mechanic metadata lookup."""
        resp = self.client.get("/api/auth/mechanic-registration", params={"email": "mechanic@servio.com"})
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        mechanic = data.get("data", {})
        self.assertEqual(mechanic.get("email"), "mechanic@servio.com")
        self.assertEqual(mechanic.get("specialization"), "Engine & Transmission")
        self.assertTrue(mechanic.get("isActive"))

    def test_06_delete_user_account_anonymize(self):
        """TC-AUTH-06: Validates user account deletion and cascade integrity."""
        auth_client, user_data, token = self.create_and_login_user(email_prefix="delete_me")

        # Delete profile
        resp = auth_client.delete("/api/auth/profile")
        Assertions.assert_api_response_success(resp, expected_status=200)

        # Confirm profile can no longer be retrieved
        get_resp = auth_client.get("/api/auth/profile")
        self.assertEqual(get_resp.status, 401)
