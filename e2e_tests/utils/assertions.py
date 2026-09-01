"""
Assertion Helpers for Servio E2E Test Suite.
Validates RFC 7807 ErrorResponse, standard ApiResponse<T>, UUIDs, and HTTP invariants.
"""
import uuid
import re
from typing import Any, Dict, Optional, List
from e2e_tests.utils.http_client import HttpResponse


class Assertions:
    @staticmethod
    def is_valid_uuid(val: Any) -> bool:
        """Verifies if a value is a valid UUID string (v4 or standard format)."""
        if not val or not isinstance(val, str):
            return False
        try:
            uuid_obj = uuid.UUID(val)
            return str(uuid_obj).lower() == val.lower()
        except (ValueError, AttributeError):
            return False

    @staticmethod
    def assert_api_response_success(response: HttpResponse, expected_status: int = 200) -> Dict[str, Any]:
        """Asserts that the response follows Spring Boot ApiResponse<T> success structure."""
        assert response.status == expected_status, (
            f"Expected HTTP {expected_status}, but received HTTP {response.status}. Body: {response.text}"
        )
        json_data = response.json
        assert isinstance(json_data, dict), f"Response body is not a JSON object: {response.text}"
        assert json_data.get("success") is True, f"ApiResponse.success is not True: {json_data}"
        return json_data

    @staticmethod
    def assert_error_response(
        response: HttpResponse,
        expected_status: int,
        expected_error_contains: Optional[str] = None,
        expected_message_contains: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Asserts that the response follows the standardized RFC 7807 ErrorResponse model:
        { "timestamp": "...", "status": 4xx/5xx, "error": "...", "message": "...", "path": "...", "traceId": "..." }
        Or fallback ApiResponse with success=false.
        """
        assert response.status == expected_status, (
            f"Expected HTTP {expected_status}, but received HTTP {response.status}. Body: {response.text}"
        )
        json_data = response.json
        assert isinstance(json_data, dict), f"Response body is not a JSON object: {response.text}"

        # Check for RFC 7807 fields or ApiResponse failure structure
        if "status" in json_data and "error" in json_data:
            assert json_data["status"] == expected_status, (
                f"ErrorResponse.status {json_data['status']} does not match HTTP code {expected_status}"
            )
            if "traceId" in json_data and json_data["traceId"]:
                assert Assertions.is_valid_uuid(json_data["traceId"]), (
                    f"traceId is not a valid UUID: {json_data.get('traceId')}"
                )
            if expected_error_contains:
                assert expected_error_contains.lower() in str(json_data.get("error", "")).lower(), (
                    f"Expected error to contain '{expected_error_contains}', got '{json_data.get('error')}'"
                )
        elif "success" in json_data:
            assert json_data["success"] is False, f"Expected success: false, got {json_data}"

        if expected_message_contains:
            msg = str(json_data.get("message", ""))
            assert expected_message_contains.lower() in msg.lower(), (
                f"Expected message to contain '{expected_message_contains}', got '{msg}'"
            )

        return json_data

    @staticmethod
    def assert_rate_limited(response: HttpResponse):
        """Asserts that the response is HTTP 429 Too Many Requests and contains Retry-After info."""
        assert response.status == 429, (
            f"Expected HTTP 429 Too Many Requests, got HTTP {response.status}. Body: {response.text}"
        )
        # Check for retry-after or rate limit headers or error message
        retry_after = response.get_header("retry-after") or response.get_header("x-rate-limit-retry-after-seconds")
        json_data = response.json or {}
        has_rate_limit_msg = "rate limit" in str(json_data).lower() or "too many requests" in str(json_data).lower()
        assert retry_after is not None or has_rate_limit_msg, (
            f"Expected rate limiting header or message, got headers: {response.headers}, body: {response.text}"
        )

    @staticmethod
    def assert_actuator_health(response: HttpResponse):
        """Asserts that Spring Boot Actuator /actuator/health is UP with database component."""
        assert response.status == 200, (
            f"Expected HTTP 200 for Actuator health, got {response.status}. Body: {response.text}"
        )
        json_data = response.json
        assert isinstance(json_data, dict), f"Invalid JSON in actuator response: {response.text}"
        assert json_data.get("status") == "UP", f"Expected status UP, got {json_data.get('status')}"
        if "components" in json_data:
            db_status = json_data["components"].get("db", {}).get("status")
            assert db_status == "UP", f"Expected DB component status UP, got {db_status}"
