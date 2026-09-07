"""
Tier 1: Feature Coverage — Customer Vehicles APIs.
Tests vehicle creation, retrieval, updates, statistics, and deletion with UUID ownership.
"""
import uuid
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestVehiclesFeature(ServioE2ETestCase):

    def test_01_create_vehicle_authenticated(self):
        """TC-VEH-01: Validates registering a new vehicle for authenticated user."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="veh_create")
        payload = {
            "make": "Toyota",
            "model": "RAV4 Hybrid",
            "year": 2023,
            "licensePlate": f"CA-{uuid.uuid4().hex[:4].upper()}",
            "vin": f"2T3F1RFV{uuid.uuid4().hex[:8].upper()}"
        }

        resp = auth_client.post("/api/vehicles/my", payload)
        data = Assertions.assert_api_response_success(resp, expected_status=201)

        vehicle = data.get("data", {})
        self.assertIsNotNone(vehicle.get("id"))
        self.assertEqual(vehicle.get("userId"), user_data["id"])
        self.assertEqual(vehicle.get("make"), payload["make"])
        self.assertEqual(vehicle.get("model"), payload["model"])
        self.assertEqual(vehicle.get("year"), payload["year"])

    def test_02_get_my_vehicles_list(self):
        """TC-VEH-02: Validates GET /api/vehicles/my returns all user vehicles."""
        auth_client, user_data, _ = self.create_and_login_user(email_prefix="my_vehicles")

        # Register two vehicles
        auth_client.post("/api/vehicles/my", {"make": "Honda", "model": "Civic", "year": 2021})
        auth_client.post("/api/vehicles/my", {"make": "Mazda", "model": "CX-5", "year": 2022})

        resp = auth_client.get("/api/vehicles/my")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        vehicles = data.get("data", [])
        self.assertIsInstance(vehicles, list)
        self.assertEqual(len(vehicles), 2)
        makes = [v.get("make") for v in vehicles]
        self.assertIn("Honda", makes)
        self.assertIn("Mazda", makes)

    def test_03_get_vehicle_by_id(self):
        """TC-VEH-03: Validates retrieving a single vehicle by its ID."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="veh_by_id")

        create_resp = auth_client.post("/api/vehicles/my", {
            "make": "Subaru",
            "model": "Outback",
            "year": 2020
        })
        veh_id = create_resp.json["data"]["id"]

        resp = auth_client.get(f"/api/vehicles/{veh_id}")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        vehicle = data.get("data", {})
        self.assertEqual(vehicle.get("id"), veh_id)
        self.assertEqual(vehicle.get("model"), "Outback")

    def test_04_update_vehicle_details(self):
        """TC-VEH-04: Validates updating vehicle information."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="veh_update")

        create_resp = auth_client.post("/api/vehicles/my", {
            "make": "Ford",
            "model": "Mustang",
            "year": 2019,
            "licensePlate": "OLD-999"
        })
        veh_id = create_resp.json["data"]["id"]

        # Update license plate
        update_resp = auth_client.put(f"/api/vehicles/{veh_id}", {
            "make": "Ford",
            "model": "Mustang GT",
            "year": 2019,
            "licensePlate": "NEW-777"
        })
        data = Assertions.assert_api_response_success(update_resp, expected_status=200)

        updated_veh = data.get("data", {})
        self.assertEqual(updated_veh.get("model"), "Mustang GT")
        self.assertEqual(updated_veh.get("licensePlate"), "NEW-777")

    def test_05_get_vehicle_statistics(self):
        """TC-VEH-05: Validates vehicle service metrics endpoint."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="veh_stats")

        create_resp = auth_client.post("/api/vehicles/my", {
            "make": "Hyundai",
            "model": "Tucson",
            "year": 2022
        })
        veh_id = create_resp.json["data"]["id"]

        resp = auth_client.get(f"/api/vehicles/{veh_id}/stats")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        stats = data.get("data", {})
        self.assertIn("totalAppointments", stats)
        self.assertIn("totalSpent", stats)

    def test_06_delete_vehicle_success(self):
        """TC-VEH-06: Validates vehicle record deletion."""
        auth_client, _, _ = self.create_and_login_user(email_prefix="veh_delete")

        create_resp = auth_client.post("/api/vehicles/my", {
            "make": "Nissan",
            "model": "Altima",
            "year": 2018
        })
        veh_id = create_resp.json["data"]["id"]

        # Delete vehicle
        del_resp = auth_client.delete(f"/api/vehicles/{veh_id}")
        Assertions.assert_api_response_success(del_resp, expected_status=200)

        # Verify not found
        get_resp = auth_client.get(f"/api/vehicles/{veh_id}")
        self.assertEqual(get_resp.status, 404)
