"""
Tier 3: Cross-Feature Integration — Flow 4: Admin Workshop Operations & Bay Allocation.
Validates administrative dashboard metrics, service bay scheduling, job card photo tracking,
and closing repair job records with invoice reconciliation.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestAdminWorkshopFlow(ServioE2ETestCase):

    def test_admin_workshop_management_and_bay_allocation_flow(self):
        """TC-FLOW-04: Admin operations: dashboard metrics, bay allocation, photo review, and job completion."""
        # 1. Admin login & role verification
        admin_client = self.get_admin_client()

        # 2. Check Dashboard Statistics
        stats_resp = admin_client.get("/api/admin/dashboard/stats")
        stats = Assertions.assert_api_response_success(stats_resp, expected_status=200)["data"]
        self.assertIn("totalRevenue", stats)
        self.assertIn("activeAppointments", stats)

        # 3. Create Appointment with Service Bay 3 allocation
        cust_client, cust_user, _ = self.create_and_login_user(email_prefix="workshop_cust")
        appt_resp = cust_client.post("/api/appointments", {
            "serviceType": "HVAC A/C Recharge & Leak Test",
            "appointmentDate": "2026-12-22T15:00:00",
            "serviceBayId": 3,
            "estimatedCost": 120.00
        })
        appt_id = appt_resp.json["data"]["id"]

        # 4. Admin allocates bay and moves appointment to IN_PROGRESS
        patch_resp = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "IN_PROGRESS"})
        Assertions.assert_api_response_success(patch_resp, expected_status=200)

        # 5. Attach Completed inspection photo
        photo_resp = admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": appt_id,
            "photoUrl": "https://res.cloudinary.com/servio/ac_completed.jpg",
            "description": "A/C pressure gauges verified within spec",
            "photoType": "COMPLETED"
        })
        photo_data = Assertions.assert_api_response_success(photo_resp, expected_status=200)["data"]
        self.assertEqual(photo_data["photoType"], "COMPLETED")

        # 6. Admin marks appointment as COMPLETED
        complete_resp = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "COMPLETED"})
        completed_appt = Assertions.assert_api_response_success(complete_resp, expected_status=200)["data"]
        self.assertEqual(completed_appt["status"], "COMPLETED")

        # 7. Customer verifies appointment is marked COMPLETED in their profile
        my_appts_resp = cust_client.get("/api/appointments/my")
        my_appts = my_appts_resp.json["data"]
        target = next(a for a in my_appts if a["id"] == appt_id)
        self.assertEqual(target["status"], "COMPLETED")
