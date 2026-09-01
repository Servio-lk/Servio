"""
Tier 3: Cross-Feature Integration — Flow 3: Catalog -> Offer -> Booking -> Payment.
Validates service catalog exploration, promotional discount selection, booking execution,
and PayHere server-to-server payment confirmation callback (R3/F-09 compliance).
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestCatalogBookingPaymentFlow(ServioE2ETestCase):

    def test_catalog_discovery_offer_and_payment_flow(self):
        """TC-FLOW-03: Service catalog exploration, applying promotion code, booking, and payment."""
        # 1. Customer browses catalog
        catalog_resp = self.client.get("/api/services/categories")
        categories = Assertions.assert_api_response_success(catalog_resp, expected_status=200)["data"]
        self.assertTrue(len(categories) >= 1)

        # 2. Customer checks active promotional offers
        offers_resp = self.client.get("/api/services/offers")
        offers = Assertions.assert_api_response_success(offers_resp, expected_status=200)["data"]
        self.assertTrue(len(offers) >= 1)
        selected_offer = offers[0]
        self.assertEqual(selected_offer["code"], "SPRING20")

        # 3. Customer logs in and books discounted service
        cust_client, cust_user, _ = self.create_and_login_user(email_prefix="flow3_payer")
        base_price = 89.99
        discount = selected_offer["discountPercentage"]
        final_price = round(base_price * (1 - discount / 100.0), 2)

        booking_resp = cust_client.post("/api/appointments", {
            "serviceType": "Full Synthetic Oil & Filter Change",
            "appointmentDate": "2026-12-20T13:00:00",
            "notes": f"Applied promo code: {selected_offer['code']}",
            "estimatedCost": final_price
        })
        appt_data = Assertions.assert_api_response_success(booking_resp, expected_status=201)["data"]
        appt_id = appt_data["id"]
        self.assertEqual(appt_data["estimatedCost"], final_price)

        # 4. Simulate PayHere Server-to-Server Payment Callback Notification
        payhere_payload = {
            "merchant_id": "123456",
            "order_id": f"SER-APPT-{appt_id}",
            "payment_id": "320025142512",
            "payhere_amount": str(final_price),
            "payhere_currency": "LKR",
            "status_code": "2",  # PayHere success code
            "md5sig": "MD5_MOCK_SIGNATURE_OK"
        }
        notify_resp = self.client.post("/api/payments/payhere/notify", payhere_payload)
        self.assertEqual(notify_resp.status, 200)

        # 5. Verify Appointment Status can be transitioned to CONFIRMED
        patch_resp = cust_client.patch(f"/api/appointments/{appt_id}/status", params={"status": "CONFIRMED"})
        updated_appt = Assertions.assert_api_response_success(patch_resp, expected_status=200)["data"]
        self.assertEqual(updated_appt["status"], "CONFIRMED")
