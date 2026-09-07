"""
Tier 3: Cross-Feature Integration — Flow 2: Appointment -> Status -> Repair Job -> Photo -> Chat.
Validates the complete repair lifecycle linking appointment scheduling, mechanic status updates,
Cloudinary inspection photo attachment to Job Card, and real-time repair chat collaboration.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestRepairLifecycleChatFlow(ServioE2ETestCase):

    def test_complete_repair_job_and_inspection_chat_flow(self):
        """TC-FLOW-02: Validates appointment status evolution to repair job, photo upload and live chat."""
        # 1. Customer creates appointment
        cust_client, cust_user, _ = self.create_and_login_user(email_prefix="flow2_cust")
        admin_client = self.get_admin_client()

        appt_resp = cust_client.post("/api/appointments", {
            "serviceType": "Brake System Overhaul",
            "appointmentDate": "2026-12-18T11:00:00",
            "notes": "Spongy brake pedal"
        })
        appt_id = appt_resp.json["data"]["id"]

        # 2. Admin confirms appointment
        patch_conf = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "CONFIRMED"})
        Assertions.assert_api_response_success(patch_conf, expected_status=200)
        self.assertEqual(patch_conf.json["data"]["status"], "CONFIRMED")

        # 3. Mechanic starts work: Transition to IN_PROGRESS
        patch_prog = admin_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "IN_PROGRESS"})
        Assertions.assert_api_response_success(patch_prog, expected_status=200)
        self.assertEqual(patch_prog.json["data"]["status"], "IN_PROGRESS")

        # 4. Mechanic uploads pre-inspection and damage photos to Job Card
        job_card_id = 201
        fake_photo_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00"

        upload_resp = admin_client.post_multipart(
            "/api/admin/job-card-photos/upload",
            fields={
                "jobCardId": str(job_card_id),
                "photoType": "PRE_INSPECTION",
                "description": "Pre-work caliper inspection"
            },
            files={"file": ("caliper.jpg", fake_photo_bytes, "image/jpeg")}
        )
        photo_data = Assertions.assert_api_response_success(upload_resp, expected_status=200)["data"]
        self.assertEqual(photo_data["photoType"], "PRE_INSPECTION")
        self.assertIn("cloudinary", photo_data["photoUrl"])

        # 5. Customer initiates live chat with mechanic
        repair_id = appt_id
        chat_msg_resp = cust_client.post(f"/api/repairs/{repair_id}/messages", {
            "message": "Hi, did you find the cause of the spongy brake pedal?"
        })
        msg_data = Assertions.assert_api_response_success(chat_msg_resp, expected_status=200)["data"]
        self.assertEqual(msg_data["senderId"], cust_user["id"])

        # 6. Mechanic responds in chat
        admin_chat_resp = admin_client.post(f"/api/repairs/{repair_id}/messages", {
            "message": "Yes, air was trapped in the brake lines. We have bled the system and replaced pads."
        })
        admin_msg = Assertions.assert_api_response_success(admin_chat_resp, expected_status=200)["data"]
        self.assertEqual(admin_msg["senderRole"], "ADMIN")

        # 7. Customer verifies complete conversation history
        history_resp = cust_client.get(f"/api/repairs/{repair_id}/messages")
        messages = Assertions.assert_api_response_success(history_resp, expected_status=200)["data"]
        self.assertEqual(len(messages), 2)
        self.assertEqual(messages[0]["message"], "Hi, did you find the cause of the spongy brake pedal?")
        self.assertEqual(messages[1]["message"], "Yes, air was trapped in the brake lines. We have bled the system and replaced pads.")
