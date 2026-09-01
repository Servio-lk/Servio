"""
Tier 2: Boundary & Corner Cases — Auth Rate Limiting & Brute-Force Protection.
Tests Bucket4j rate limiting filter on public authentication endpoints (/api/auth/**),
verifying HTTP 429 Too Many Requests responses and Retry-After headers.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestAuthRateLimiting(ServioE2ETestCase):

    def test_01_auth_rate_limiting_triggered_on_burst(self):
        """TC-BOUND-RATE-01: Rapid burst of login attempts exceeds rate limit and returns HTTP 429."""
        burst_count = 10
        responses = []

        for i in range(burst_count):
            resp = self.client.post(
                "/api/auth/login",
                data={"email": f"brute_force_{i}@test.com", "password": "WrongPassword!"},
                headers={"X-Test-Rate-Limit": "1"}
            )
            responses.append(resp)

        statuses = [r.status for r in responses]
        self.assertIn(429, statuses, f"Expected HTTP 429 in responses, but got statuses: {statuses}")

        # Validate structure of 429 response
        rate_limited_resp = next(r for r in responses if r.status == 429)
        Assertions.assert_rate_limited(rate_limited_resp)

    def test_02_health_endpoint_not_rate_limited(self):
        """TC-BOUND-RATE-02: Public health check endpoint is exempt from authentication rate limiting."""
        for _ in range(10):
            resp = self.client.get("/api/auth/health")
            self.assertEqual(resp.status, 200)

    def test_03_rate_limiting_returns_retry_after_header(self):
        """TC-BOUND-RATE-03: HTTP 429 response contains Retry-After header for client backoff."""
        # Flood signup endpoint with rate limit test header
        for _ in range(8):
            resp = self.client.post(
                "/api/auth/signup",
                data={"email": "flood@test.com", "password": "password123"},
                headers={"X-Test-Rate-Limit": "1"}
            )
            if resp.status == 429:
                retry_after = resp.get_header("retry-after") or resp.get_header("x-rate-limit-retry-after-seconds")
                self.assertIsNotNone(retry_after, f"Missing Retry-After header in 429 response: {resp.headers}")
                return

        self.fail("Expected at least one HTTP 429 response during flooding")
