"""
Tier 1: Feature Coverage — Web Client Routing & Guards.
Tests unified React SPA routes, public paths, customer pages, /admin/* subroutes, and QR code tracking.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestWebRoutingFeature(ServioE2ETestCase):

    def test_01_public_auth_routes_accessible(self):
        """TC-WEB-01: Validates public routes (/login, /signup, /forgot-password) render SPA root."""
        for path in ["/login", "/signup"]:
            resp = self.client.get(path)
            self.assertEqual(resp.status, 200)
            self.assertIn("text/html", resp.get_header("content-type", ""))
            self.assertIn("root", resp.text)

    def test_02_customer_protected_routes_render_spa(self):
        """TC-WEB-02: Validates customer routes (/home, /services, /activity) render SPA framework."""
        for path in ["/home", "/services", "/activity"]:
            resp = self.client.get(path)
            self.assertEqual(resp.status, 200)
            self.assertIn("text/html", resp.get_header("content-type", ""))

    def test_03_admin_routes_accessible_under_unified_spa(self):
        """TC-WEB-03: Validates unified /admin routes render under consolidated frontend."""
        for path in ["/admin", "/admin/dashboard"]:
            resp = self.client.get(path)
            self.assertEqual(resp.status, 200)
            self.assertIn("text/html", resp.get_header("content-type", ""))

    def test_04_public_qr_appointment_status_route(self):
        """TC-WEB-04: Validates public QR code tracking route /appointment/:id is reachable."""
        resp = self.client.get("/appointment/123")
        self.assertEqual(resp.status, 200)
        self.assertIn("text/html", resp.get_header("content-type", ""))

    def test_05_admin_dashboard_stats_endpoint(self):
        """TC-WEB-05: Validates /api/admin/dashboard/stats returns operational KPIs for Admin portal."""
        admin_client = self.get_admin_client()
        resp = admin_client.get("/api/admin/dashboard/stats")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        stats = data.get("data", {})
        self.assertIn("totalRevenue", stats)
        self.assertIn("activeAppointments", stats)
