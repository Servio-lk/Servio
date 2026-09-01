"""
Tier 4: Real-World Application Scenarios — Scenario 1: Complete Customer Journey.
Simulates realistic customer experience: account onboarding, vehicle registration, catalog browsing,
checking real-time bay availability, booking appointment, public QR tracking, live mechanic messaging,
and verifying account history.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestCustomerBookingJourney(ServioE2ETestCase):

    def test_full_customer_lifecycle_journey(self):
        """TC-SCENARIO-01: Holistic Customer Journey from Registration to Completion."""
        # ── Step 1: Customer Account Creation & Login ──
        cust_client, cust_user, token = self.create_and_login_user(email_prefix="john_doe")
        self.assertTrue(Assertions.is_valid_uuid(cust_user["id"]))
        self.assertEqual(cust_user["role"], "USER")

        # ── Step 2: Customer Registers Their Daily Driver Vehicle ──
        veh_payload = {
            "make": "Honda",
            "model": "Accord Sport 2.0T",
            "year": 2022,
            "licensePlate": "7XYZ890",
            "vin": "1HGCV2F84NA123999"
        }
        veh_resp = cust_client.post("/api/vehicles/my", veh_payload)
        veh_data = Assertions.assert_api_response_success(veh_resp, expected_status=201)["data"]
        vehicle_id = veh_data["id"]

        # ── Step 3: Customer Explores Service Catalog & Filters by Maintenance ──
        catalog_resp = self.client.get("/api/services/categories")
        categories = Assertions.assert_api_response_success(catalog_resp, expected_status=200)["data"]
        maintenance_cat = next(c for c in categories if c["id"] == 1)
        selected_service = maintenance_cat["services"][0]
        self.assertEqual(selected_service["name"], "Full Synthetic Oil & Filter Change")

        # ── Step 4: Customer Checks Available Slots for Next Week ──
        target_date = "2026-12-28"
        slots_resp = self.client.get("/api/appointments/booked-slots", params={"date": target_date})
        booked_slots = Assertions.assert_api_response_success(slots_resp, expected_status=200)["data"]
        desired_time = "09:30"
        self.assertNotIn(desired_time, booked_slots)

        # ── Step 5: Customer Books the Service ──
        slot_datetime = f"{target_date}T{desired_time}:00"
        booking_payload = {
            "serviceType": selected_service["name"],
            "appointmentDate": slot_datetime,
            "vehicleId": vehicle_id,
            "serviceBayId": 1,
            "notes": "Synthetic 0W-20 requested; please reset oil life monitor.",
            "estimatedCost": selected_service["basePrice"]
        }
        booking_resp = cust_client.post("/api/appointments", booking_payload)
        booking_data = Assertions.assert_api_response_success(booking_resp, expected_status=201)["data"]
        appointment_id = booking_data["id"]
        self.assertEqual(booking_data["status"], "PENDING")

        # ── Step 6: Customer Checks Public QR Tracking Page ──
        # In a real setup, QR code in email points to /appointment/:id
        status_page_resp = self.client.get(f"/appointment/{appointment_id}")
        self.assertEqual(status_page_resp.status, 200)

        # ── Step 7: Workshop Confirms & Starts Job ──
        admin_client = self.get_admin_client()
        admin_client.patch(f"/api/appointments/{appointment_id}/status", params={"status": "IN_PROGRESS"})

        # ── Step 8: Customer Sends Live Question to Assigned Mechanic ──
        chat_resp = cust_client.post(f"/api/repairs/{appointment_id}/messages", {
            "message": "Hi, how are the brake pads looking during the inspection?"
        })
        Assertions.assert_api_response_success(chat_resp, expected_status=200)

        # ── Step 9: Mechanic Replies ──
        admin_client.post(f"/api/repairs/{appointment_id}/messages", {
            "message": "Brake pads have 7mm remaining (approx 70% life). Everything looks healthy!"
        })

        # ── Step 10: Service Completed & Final History Verification ──
        admin_client.patch(f"/api/appointments/{appointment_id}/status", params={"status": "COMPLETED"})

        history_resp = cust_client.get("/api/appointments/my")
        my_appts = Assertions.assert_api_response_success(history_resp, expected_status=200)["data"]
        completed_appt = next(a for a in my_appts if a["id"] == appointment_id)
        self.assertEqual(completed_appt["status"], "COMPLETED")
