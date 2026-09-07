"""
Tier 3: Cross-Feature Integration — Flow 1: Auth -> Vehicle -> Slot Discovery -> Booking.
Validates multi-step journey of user registration, vehicle association, checking slot availability,
booking appointment with vehicle linkage, and verifying appointment retrieval.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestBookingVehicleFlow(ServioE2ETestCase):

    def test_full_auth_vehicle_slot_booking_pipeline(self):
        """TC-FLOW-01: End-to-end user onboarding, vehicle registration, slot query, and booking."""
        # 1. User Registration & Auth
        auth_client, user_data, token = self.create_and_login_user(email_prefix="flow1_customer")
        self.assertTrue(Assertions.is_valid_uuid(user_data["id"]))

        # 2. Register Vehicle
        veh_resp = auth_client.post("/api/vehicles/my", {
            "make": "Subaru",
            "model": "Crosstrek",
            "year": 2023,
            "licensePlate": "SUB-8812",
            "vin": "JF2GTAEC4N8123456"
        })
        veh_data = Assertions.assert_api_response_success(veh_resp, expected_status=201)
        vehicle_id = veh_data["data"]["id"]
        self.assertEqual(veh_data["data"]["userId"], user_data["id"])

        # 3. Check Slot Availability for Target Date
        target_date = "2026-12-15"
        slots_resp = self.client.get("/api/appointments/booked-slots", params={"date": target_date})
        booked_slots = Assertions.assert_api_response_success(slots_resp, expected_status=200)["data"]

        target_time = "10:00"
        self.assertNotIn(target_time, booked_slots)

        # 4. Book Appointment with Linked Vehicle ID
        slot_datetime = f"{target_date}T{target_time}:00"
        booking_resp = auth_client.post("/api/appointments", {
            "serviceType": "Full Synthetic Oil & Filter Change",
            "appointmentDate": slot_datetime,
            "vehicleId": vehicle_id,
            "serviceBayId": 1,
            "notes": "First 10k mile maintenance check"
        })
        booking_data = Assertions.assert_api_response_success(booking_resp, expected_status=201)
        appt = booking_data["data"]
        appt_id = appt["id"]
        self.assertEqual(appt["userId"], user_data["id"])
        self.assertEqual(appt["vehicleId"], vehicle_id)
        self.assertEqual(appt["status"], "PENDING")

        # 5. Verify Slot is now marked as booked
        slots_after_resp = self.client.get("/api/appointments/booked-slots", params={"date": target_date})
        updated_slots = slots_after_resp.json["data"]
        self.assertIn(target_time, updated_slots)

        # 6. Verify User's Appointment List Contains Linked Vehicle Reference
        my_appts_resp = auth_client.get("/api/appointments/my")
        my_appts = Assertions.assert_api_response_success(my_appts_resp, expected_status=200)["data"]
        user_appt_ids = [a["id"] for a in my_appts]
        self.assertIn(appt_id, user_appt_ids)
        target_appt = next(a for a in my_appts if a["id"] == appt_id)
        self.assertEqual(target_appt["vehicleId"], vehicle_id)
