"""
Tier 1: Feature Coverage — Repair Chat & Messaging APIs.
Tests conversation retrieval, message sending, chat history, multi-turn exchanges, and authentication checks.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestRepairChatFeature(ServioE2ETestCase):

    def test_01_get_repair_conversation_details(self):
        """TC-CHAT-01: Validates GET /api/repairs/{repairId}/conversation returns conversation channel."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="chat_user")
        repair_id = 42

        resp = auth_client.get(f"/api/repairs/{repair_id}/conversation")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        conv = data.get("data", {})
        self.assertEqual(conv.get("repairJobId"), repair_id)
        self.assertIn("Support Channel", conv.get("title", ""))

    def test_02_send_repair_message_success(self):
        """TC-CHAT-02: Validates POST /api/repairs/{repairId}/messages sends message with sender identity."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="chat_sender")
        repair_id = 43
        msg_text = "Hello, can you check the brake pads while replacing the oil?"

        resp = auth_client.post(f"/api/repairs/{repair_id}/messages", {"message": msg_text})
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        msg = data.get("data", {})
        self.assertIsNotNone(msg.get("id"))
        self.assertEqual(msg.get("senderId"), user_data["id"])
        self.assertEqual(msg.get("message"), msg_text)
        self.assertEqual(msg.get("repairJobId"), repair_id)

    def test_03_get_repair_messages_history(self):
        """TC-CHAT-03: Validates GET /api/repairs/{repairId}/messages returns message chronological history."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="chat_history")
        repair_id = 44

        # Send two messages
        auth_client.post(f"/api/repairs/{repair_id}/messages", {"message": "Message 1 from customer"})
        auth_client.post(f"/api/repairs/{repair_id}/messages", {"message": "Message 2 from customer"})

        resp = auth_client.get(f"/api/repairs/{repair_id}/messages")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        msgs = data.get("data", [])
        self.assertIsInstance(msgs, list)
        self.assertTrue(len(msgs) >= 2)
        texts = [m.get("message") for m in msgs]
        self.assertIn("Message 1 from customer", texts)
        self.assertIn("Message 2 from customer", texts)

    def test_04_multiturn_repair_chat_exchange(self):
        """TC-CHAT-04: Validates multi-party dialogue between customer and mechanic/admin."""
        customer_client, customer_data, _ = self.create_and_login_user(email_prefix="customer_chat")
        admin_client = self.get_admin_client()
        repair_id = 45

        # Customer sends question
        customer_client.post(f"/api/repairs/{repair_id}/messages", {"message": "Is the car ready for pickup?"})

        # Admin responds
        admin_client.post(f"/api/repairs/{repair_id}/messages", {"message": "Yes, final inspection is completed."})

        resp = customer_client.get(f"/api/repairs/{repair_id}/messages")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        msgs = data.get("data", [])
        self.assertEqual(len(msgs), 2)
        self.assertEqual(msgs[0]["senderRole"], "USER")
        self.assertEqual(msgs[1]["senderRole"], "ADMIN")

    def test_05_repair_chat_unauthenticated_rejected(self):
        """TC-CHAT-05: Validates unauthenticated requests to send messages are rejected with HTTP 401."""
        resp = self.client.post("/api/repairs/99/messages", {"message": "Unauthorized attempt"})
        self.assertEqual(resp.status, 401)
