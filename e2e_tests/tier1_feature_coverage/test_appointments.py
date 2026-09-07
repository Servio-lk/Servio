"""
Tier 1: Feature Coverage — Appointments & Scheduling APIs.
Tests appointment creation, user-filtered list, slot queries, status transitions, and self-cancellation.
"""
import uuid
import time
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestAppointmentsFeature(ServioE2ETestCase):

    def test_01_create_appointment_success(self):
        """TC-APPT-01: Validates customer appointment creation with valid parameters."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="appt_create")
        slot_date = f"2026-10-15T{10 + len(user_data['id']) % 8:02d}:00:00"

        payload = {
            "serviceType": "Full Synthetic Oil & Filter Change",
            "appointmentDate": slot_date,
            "notes": "Please check tire pressure as well",
            "estimatedCost": 89.99,
            "serviceBayId": 1
        }

        resp = auth_client.post("/api/appointments", payload)
        data = Assertions.assert_api_response_success(resp, expected_status=201)

        appt = data.get("data", {})
        self.assertIsNotNone(appt.get("id"))
        self.assertEqual(appt.get("userId"), user_data["id"])
        self.assertEqual(appt.get("serviceType"), payload["serviceType"])
        self.assertEqual(appt.get("status"), "PENDING")

    def test_02_get_my_appointments_filtered_by_jwt(self):
        """TC-APPT-02: Validates GET /api/appointments/my returns only authenticated user appointments."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="my_appts")
        slot_date = f"2026-10-16T{9 + len(user_data['id']) % 8:02d}:00:00"

        # Create appointment
        auth_client.post("/api/appointments", {
            "serviceType": "Brake Inspection",
            "appointmentDate": slot_date,
            "estimatedCost": 49.99
        })

        # Fetch my appointments
        resp = auth_client.get("/api/appointments/my")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        appts = data.get("data", [])
        self.assertIsInstance(appts, list)
        self.assertTrue(len(appts) >= 1)
        for appt in appts:
            self.assertEqual(appt.get("userId"), user_data["id"])

    def test_03_get_booked_slots_by_date_public(self):
        """TC-APPT-03: Validates GET /api/appointments/booked-slots returns occupied slots without auth."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="booked_slot_check")
        target_date = "2026-11-20"
        target_time = "14:00"
        slot_datetime = f"{target_date}T{target_time}:00"

        # Book slot
        auth_client.post("/api/appointments", {
            "serviceType": "Periodic Maintenance",
            "appointmentDate": slot_datetime
        })

        # Query booked slots using unauthenticated public client
        resp = self.client.get("/api/appointments/booked-slots", params={"date": target_date})
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        slots = data.get("data", [])
        self.assertIsInstance(slots, list)
        self.assertIn(target_time, slots)

    def test_04_get_appointment_by_id(self):
        """TC-APPT-04: Validates retrieving a single appointment by ID."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="appt_by_id")
        slot_date = f"2026-10-17T{11 + len(user_data['id']) % 6:02d}:00:00"

        create_resp = auth_client.post("/api/appointments", {
            "serviceType": "Tire Alignment",
            "appointmentDate": slot_date
        })
        appt_id = create_resp.json["data"]["id"]

        resp = auth_client.get(f"/api/appointments/{appt_id}")
        data = Assertions.assert_api_response_success(resp, expected_status=200)
        self.assertEqual(data.get("data", {}).get("id"), appt_id)

    def test_05_update_appointment_status_transition(self):
        """TC-APPT-05: Validates updating appointment status through lifecycle."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="appt_status")
        slot_date = f"2026-10-18T{10 + len(user_data['id']) % 6:02d}:00:00"

        create_resp = auth_client.post("/api/appointments", {
            "serviceType": "Battery Diagnostic",
            "appointmentDate": slot_date
        })
        appt_id = create_resp.json["data"]["id"]

        # Transition status to CONFIRMED
        patch_resp = auth_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "CONFIRMED"})
        data = Assertions.assert_api_response_success(patch_resp, expected_status=200)
        self.assertEqual(data.get("data", {}).get("status"), "CONFIRMED")

    def test_06_cancel_own_appointment_releases_slot(self):
        """TC-APPT-06: Validates cancelling appointment and freeing booked time slot."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="appt_cancel")
        target_date = "2026-11-25"
        target_time = "15:30"
        slot_datetime = f"{target_date}T{target_time}:00"

        create_resp = auth_client.post("/api/appointments", {
            "serviceType": "Oil Service",
            "appointmentDate": slot_datetime
        })
        appt_id = create_resp.json["data"]["id"]

        # Cancel appointment
        cancel_resp = auth_client.post(f"/api/appointments/{appt_id}/cancel")
        Assertions.assert_api_response_success(cancel_resp, expected_status=200)
        self.assertEqual(cancel_resp.json.get("data", {}).get("status"), "CANCELLED")

        # Verify slot is no longer reported as booked
        slots_resp = self.client.get("/api/appointments/booked-slots", params={"date": target_date})
        self.assertNotIn(target_time, slots_resp.json.get("data", []))
