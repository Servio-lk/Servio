"""
Tier 1: Feature Coverage — Inspection Photos & Cloudinary Storage APIs.
Tests multipart photo uploads, JSON photo metadata, job card photos retrieval, deletion, and role security.
"""
from e2e_tests.base import ServioE2ETestCase
from e2e_tests.utils.assertions import Assertions


class TestInspectionPhotosFeature(ServioE2ETestCase):

    def test_01_multipart_photo_upload_cloudinary(self):
        """TC-PHOTO-01: Validates multipart/form-data upload returning Cloudinary CDN URL."""
        admin_client = self.get_admin_client()
        fake_jpeg_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00"

        fields = {
            "jobCardId": "101",
            "photoType": "PRE_INSPECTION",
            "description": "Pre-existing scratch on front bumper"
        }
        files = {
            "file": ("bumper_scratch.jpg", fake_jpeg_bytes, "image/jpeg")
        }

        resp = admin_client.post_multipart("/api/admin/job-card-photos/upload", fields=fields, files=files)
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        photo = data.get("data", {})
        self.assertIsNotNone(photo.get("id"))
        self.assertIn("cloudinary", photo.get("photoUrl", "").lower())
        self.assertEqual(photo.get("photoType"), "PRE_INSPECTION")

    def test_02_add_photo_json_metadata(self):
        """TC-PHOTO-02: Validates adding photo metadata with existing CDN URL."""
        admin_client = self.get_admin_client()
        payload = {
            "jobCardId": 102,
            "photoUrl": "https://res.cloudinary.com/servio/image/upload/v1/job-cards/102/damage_1.jpg",
            "description": "Worn brake rotor scoring",
            "photoType": "DAMAGE"
        }

        resp = admin_client.post("/api/admin/job-card-photos", payload)
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        photo = data.get("data", {})
        self.assertEqual(photo.get("jobCardId"), 102)
        self.assertEqual(photo.get("photoType"), "DAMAGE")

    def test_03_get_photos_by_job_card_id(self):
        """TC-PHOTO-03: Validates GET /api/admin/job-card-photos/job-card/{id} returns all photos."""
        admin_client = self.get_admin_client()
        job_card_id = 103

        # Add two photos
        admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": job_card_id,
            "photoUrl": "https://res.cloudinary.com/servio/p1.jpg",
            "photoType": "PRE_INSPECTION"
        })
        admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": job_card_id,
            "photoUrl": "https://res.cloudinary.com/servio/p2.jpg",
            "photoType": "COMPLETED"
        })

        resp = admin_client.get(f"/api/admin/job-card-photos/job-card/{job_card_id}")
        data = Assertions.assert_api_response_success(resp, expected_status=200)

        photos = data.get("data", [])
        self.assertIsInstance(photos, list)
        self.assertEqual(len(photos), 2)

    def test_04_get_single_photo_by_id(self):
        """TC-PHOTO-04: Validates GET /api/admin/job-card-photos/{id} retrieves photo by ID."""
        admin_client = self.get_admin_client()
        add_resp = admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": 104,
            "photoUrl": "https://res.cloudinary.com/servio/p_single.jpg",
            "photoType": "DAMAGE"
        })
        photo_id = add_resp.json["data"]["id"]

        resp = admin_client.get(f"/api/admin/job-card-photos/{photo_id}")
        data = Assertions.assert_api_response_success(resp, expected_status=200)
        self.assertEqual(data.get("data", {}).get("id"), photo_id)

    def test_05_delete_inspection_photo(self):
        """TC-PHOTO-05: Validates deleting inspection photo."""
        admin_client = self.get_admin_client()
        add_resp = admin_client.post("/api/admin/job-card-photos", {
            "jobCardId": 105,
            "photoUrl": "https://res.cloudinary.com/servio/to_delete.jpg"
        })
        photo_id = add_resp.json["data"]["id"]

        # Delete photo
        del_resp = admin_client.delete(f"/api/admin/job-card-photos/{photo_id}")
        Assertions.assert_api_response_success(del_resp, expected_status=200)

        # Confirm deleted
        get_resp = admin_client.get(f"/api/admin/job-card-photos/{photo_id}")
        self.assertEqual(get_resp.status, 404)

    def test_06_non_admin_photo_upload_forbidden(self):
        """TC-PHOTO-06: Validates regular customer token is rejected with HTTP 403 Forbidden."""
        customer_client, _, _ = self.create_and_login_user(email_prefix="cust_unauthorized")

        resp = customer_client.post("/api/admin/job-card-photos", {
            "jobCardId": 106,
            "photoUrl": "https://res.cloudinary.com/servio/unauth.jpg"
        })
        self.assertEqual(resp.status, 403)
