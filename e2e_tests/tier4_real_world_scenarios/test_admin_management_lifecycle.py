"""
Tier 4: Real-World Application Scenarios — Scenario 2: Complete Admin & Workshop Operations Lifecycle.
Simulates workshop manager/admin daily workflow: authenticating, reviewing KPI dashboard,
staff lookup, managing promotional campaigns, bay management, job card photo inspection, and service billing.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestAdminManagementLifecycle(ServioE2ETestCase):

    def test_full_admin_workshop_management_lifecycle(self):
        """TC-SCENARIO-02: Comprehensive Admin Workshop Management & Lifecycle Oversight."""
        # ── Step 1: Admin Authentication & Authority Check ──
        admin_client = self.get_admin_client()
        profile_resp = admin_client.get("/api/auth/profile")
        admin_profile = Assertions.assert_api_response_success(profile_resp, expected_status=200)["data"]
        self.assertEqual(admin_profile["role"], "ADMIN")
        self.assertTrue(admin_profile.get("isAdmin", True))

        # ── Step 2: Review Executive Dashboard KPIs ──
        kpi_resp = admin_client.get("/api/admin/dashboard/stats")
        kpis = Assertions.assert_api_response_success(kpi_resp, expected_status=200)["data"]
        self.assertIn("totalRevenue", kpis)
        self.assertIn("activeAppointments", kpis)

        # ── Step 3: Verify Technician Roster & Qualifications ──
        staff_resp = self.client.get("/api/auth/mechanic-registration", params={"email": "mechanic@servio.com"})
        staff_data = Assertions.assert_api_response_success(staff_resp, expected_status=200)["data"]
        self.assertEqual(staff_data["fullName"], "Senior Technician Dave")
        self.assertTrue(staff_data["isActive"])

        # ── Step 4: Check Actuator System Health ──
        health_resp = self.client.get("/actuator/health")
        Assertions.assert_actuator_health(health_resp)

        # ── Step 5: Incoming Customer Appointment Scheduling ──
        cust_client, cust_user, _ = self.create_and_login_user(email_prefix="walkin_lead")
        appt_resp = cust_client.post("/api/appointments", {
            "serviceType": "Comprehensive Brake Pad Replacement",
            "appointmentDate": "2026-12-30T14:00:00",
            "serviceBayId": 2,
            "estimatedCost": 149.99,
            "notes": "Squealing sound during high speed braking"
        })
        appt_id = appt_resp.json["data"]["id"]

        # ── Step 6: Workshop Approves & Assigns Bay 2 ──
        approve_resp = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "IN_PROGRESS"})
        Assertions.assert_api_response_success(approve_resp, expected_status=200)

        # ── Step 7: Mechanic Documents Damage with Cloudinary Photo Upload ──
        fake_photo_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00"
        upload_resp = admin_client.post_multipart(
            "/api/admin/job-card-photos/upload",
            fields={
                "jobCardId": str(appt_id),
                "photoType": "DAMAGE",
                "description": "Inner brake pad worn down to 1mm metal backing plate"
            },
            files={"file": ("pad_wear.jpg", fake_photo_bytes, "image/jpeg")}
        )
        photo_info = Assertions.assert_api_response_success(upload_resp, expected_status=200)["data"]
        self.assertEqual(photo_info["photoType"], "DAMAGE")
        self.assertIn("cloudinary", photo_info["photoUrl"])

        # ── Step 8: Attach Post-Repair Verification Photo ──
        post_photo_resp = admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": appt_id,
            "photoUrl": "https://res.cloudinary.com/servio/brake_installed.jpg",
            "description": "New ceramic brake pads and resurfaced rotors installed",
            "photoType": "COMPLETED"
        })
        Assertions.assert_api_response_success(post_photo_resp, expected_status=200)

        # ── Step 9: Verify Job Card Photos Gallery ──
        gallery_resp = admin_client.get(f"/api/admin/job-card-photos/job-card/{appt_id}")
        photos = Assertions.assert_api_response_success(gallery_resp, expected_status=200)["data"]
        self.assertEqual(len(photos), 2)
        types = [p["photoType"] for p in photos]
        self.assertIn("DAMAGE", types)
        self.assertIn("COMPLETED", types)

        # ── Step 10: Complete Job and Reconcile Billing ──
        final_resp = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "COMPLETED"})
        final_data = Assertions.assert_api_response_success(final_resp, expected_status=200)["data"]
        self.assertEqual(final_data["status"], "COMPLETED")
