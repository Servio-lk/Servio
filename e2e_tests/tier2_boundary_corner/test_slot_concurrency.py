"""
Tier 2: Boundary & Corner Cases — Slot Concurrency & Double Booking Prevention.
Tests sequential and multi-threaded concurrent booking requests for the same time slot,
verifying pessimistic row locking, database constraints, and HTTP 409 Conflict responses.
"""
import concurrent.futures
import time
import uuid
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestSlotConcurrency(ServioE2ETestCase):

    def test_01_sequential_duplicate_slot_booking_rejected_with_409(self):
        """TC-BOUND-CONC-01: Sequential booking of the same slot returns HTTP 409 Conflict."""
        client_a, user_a, _ = self.create_and_login_user(email_prefix="slot_user_a")
        client_b, user_b, _ = self.create_and_login_user(email_prefix="slot_user_b")

        slot_time = f"2026-12-01T10:00:00"
        payload = {
            "serviceType": "Full Synthetic Oil & Filter Change",
            "appointmentDate": slot_time,
            "serviceBayId": 1
        }

        # First booking succeeds
        resp1 = client_a.post("/api/appointments", payload)
        Assertions.assert_api_response_success(resp1, expected_status=201)

        # Second booking for identical slot must be rejected with 409 Conflict
        resp2 = client_b.post("/api/appointments", payload)
        Assertions.assert_error_response(
            resp2,
            expected_status=409,
            expected_error_contains="Conflict",
            expected_message_contains="already booked"
        )

    def test_02_concurrent_slot_booking_race_condition(self):
        """TC-BOUND-CONC-02: 10 concurrent threads race for the same slot; exactly 1 succeeds, 9 get 409."""
        num_threads = 10
        users_and_clients = [self.create_and_login_user(email_prefix=f"race_{i}") for i in range(num_threads)]

        slot_time = f"2026-12-05T14:30:00"
        payload = {
            "serviceType": "Transmission Service",
            "appointmentDate": slot_time,
            "serviceBayId": 2
        }

        results = []

        def attempt_booking(client_tuple):
            c, u, _ = client_tuple
            return c.post("/api/appointments", payload)

        with concurrent.futures.ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = [executor.submit(attempt_booking, u_tuple) for u_tuple in users_and_clients]
            for f in concurrent.futures.as_completed(futures):
                results.append(f.result())

        status_codes = [r.status for r in results]
        successes = status_codes.count(201)
        conflicts = status_codes.count(409)

        self.assertEqual(successes, 1, f"Expected exactly 1 booking to succeed, but got {successes}. Statuses: {status_codes}")
        self.assertEqual(conflicts, num_threads - 1, f"Expected {num_threads - 1} to be rejected with 409 Conflict, got {conflicts}")

    def test_03_cancelled_slot_can_be_rebooked(self):
        """TC-BOUND-CONC-03: Once an appointment is cancelled, the released slot becomes bookable again."""
        client_a, _, _ = self.create_and_login_user(email_prefix="rebook_user_a")
        client_b, _, _ = self.create_and_login_user(email_prefix="rebook_user_b")

        slot_time = f"2026-12-10T16:00:00"
        payload = {
            "serviceType": "Tire Rotation",
            "appointmentDate": slot_time
        }

        # User A books slot
        resp1 = client_a.post("/api/appointments", payload)
        appt_id = resp1.json["data"]["id"]

        # User B attempt fails with 409
        resp2 = client_b.post("/api/appointments", payload)
        self.assertEqual(resp2.status, 409)

        # User A cancels
        client_a.post(f"/api/appointments/{appt_id}/cancel")

        # User B attempt now succeeds with 201
        resp3 = client_b.post("/api/appointments", payload)
        Assertions.assert_api_response_success(resp3, expected_status=201)
