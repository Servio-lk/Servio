"""
Tier 1: Feature Coverage — Spring Boot Actuator Health & Observability APIs.
Tests /actuator/health, database health indicators, disk space, /actuator/info, and metrics role security.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestActuatorHealthFeature(ServioE2ETestCase):

    def test_01_actuator_health_status_up(self):
        """TC-ACT-01: Validates GET /actuator/health returns 200 OK and overall status UP."""
        resp = self.client.get("/actuator/health")
        Assertions.assert_actuator_health(resp)

    def test_02_actuator_database_component_up(self):
        """TC-ACT-02: Validates DataSourceHealthIndicator reports database status UP."""
        resp = self.client.get("/actuator/health")
        self.assertEqual(resp.status, 200)

        json_data = resp.json
        self.assertIn("components", json_data)
        db_comp = json_data["components"].get("db", {})
        self.assertEqual(db_comp.get("status"), "UP")

    def test_03_actuator_info_endpoint(self):
        """TC-ACT-03: Validates GET /actuator/info returns application metadata."""
        resp = self.client.get("/actuator/info")
        self.assertEqual(resp.status, 200)
        self.assertIsNotNone(resp.json)

    def test_04_actuator_disk_space_component(self):
        """TC-ACT-04: Validates DiskSpaceHealthIndicator reports disk status UP."""
        resp = self.client.get("/actuator/health")
        self.assertEqual(resp.status, 200)

        components = resp.json.get("components", {})
        disk = components.get("diskSpace", {})
        self.assertEqual(disk.get("status"), "UP")

    def test_05_actuator_metrics_admin_guard_security(self):
        """TC-ACT-05: Validates /actuator/metrics is secured and accessible only to administrators."""
        # Unauthenticated request must be rejected (401 or 403)
        unauth_resp = self.client.get("/actuator/metrics")
        self.assertIn(unauth_resp.status, (401, 403))

        # Regular customer token must be rejected (403)
        cust_client, _, _ = self.create_and_login_user(email_prefix="cust_metrics")
        cust_resp = cust_client.get("/actuator/metrics")
        self.assertEqual(cust_resp.status, 403)

        # Admin token must succeed (200)
        admin_client = self.get_admin_client()
        admin_resp = admin_client.get("/actuator/metrics")
        self.assertEqual(admin_resp.status, 200)
