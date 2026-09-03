"""
Tier 1: Feature Coverage — Service Catalog & Offers APIs.
Tests category listings, all services, featured items, service detail, keyword search, and active offers.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestServicesFeature(ServioE2ETestCase):

    def test_01_get_service_categories_with_services(self):
        """TC-SVC-01: Validates GET /api/services/categories returns categories and nested services."""
        resp = self.client.get("/api/services/categories")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        categories = data.get("data", [])
        self.assertIsInstance(categories, list)
        self.assertTrue(len(categories) >= 1)

        first_cat = categories[0]
        self.assertIn("id", first_cat)
        self.assertIn("name", first_cat)
        self.assertIn("services", first_cat)

    def test_02_get_all_services_list(self):
        """TC-SVC-02: Validates GET /api/services returns full service catalog."""
        resp = self.client.get("/api/services")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        services = data.get("data", [])
        self.assertIsInstance(services, list)
        self.assertTrue(len(services) >= 1)

        first_svc = services[0]
        self.assertIn("id", first_svc)
        self.assertIn("name", first_svc)
        self.assertIn("basePrice", first_svc)

    def test_03_get_featured_services(self):
        """TC-SVC-03: Validates GET /api/services/featured filters items by is_featured."""
        resp = self.client.get("/api/services/featured")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        featured = data.get("data", [])
        self.assertIsInstance(featured, list)
        self.assertTrue(len(featured) >= 1)
        for svc in featured:
            self.assertTrue(svc.get("isFeatured", True))

    def test_04_get_service_by_id(self):
        """TC-SVC-04: Validates GET /api/services/{id} returns single service details."""
        resp = self.client.get("/api/services/1")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        svc = data.get("data", {})
        self.assertEqual(svc.get("id"), 1)
        self.assertIn("Oil", svc.get("name", ""))

    def test_05_search_services_by_query(self):
        """TC-SVC-05: Validates GET /api/services/search?q={query} keyword filtering."""
        resp = self.client.get("/api/services/search", params={"q": "brake"})
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        results = data.get("data", [])
        self.assertIsInstance(results, list)
        self.assertTrue(len(results) >= 1)
        self.assertTrue(any("brake" in s.get("name", "").lower() for s in results))

    def test_06_get_active_promotional_offers(self):
        """TC-SVC-06: Validates GET /api/services/offers returns marketing promotional codes."""
        resp = self.client.get("/api/services/offers")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        offers = data.get("data", [])
        self.assertIsInstance(offers, list)
        self.assertTrue(len(offers) >= 1)

        first_offer = offers[0]
        self.assertIn("code", first_offer)
        self.assertIn("discountPercentage", first_offer)
