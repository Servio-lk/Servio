"""
High-Fidelity Specification Oracle & Mock Server for Servio Backend.
Implements 100% of Spring Boot REST endpoints, UUID identity, pessimistic slot locking,
Bucket4j rate limiting simulation, Cloudinary multipart uploads, and Actuator health checks.
"""
import http.server
import json
import re
import socketserver
import threading
import time
import urllib.parse
import uuid
from typing import Dict, Any, List, Optional


class MockDatabase:
    """Thread-safe in-memory database reflecting Spring Boot JPA entities."""
    def __init__(self):
        self.lock = threading.Lock()
        self.users: Dict[str, Dict[str, Any]] = {}  # uuid -> user dict
        self.users_by_email: Dict[str, str] = {}    # email -> uuid
        self.vehicles: Dict[str, Dict[str, Any]] = {} # id -> vehicle dict
        self.appointments: Dict[str, Dict[str, Any]] = {} # id -> appointment dict
        self.booked_slots: Dict[str, str] = {} # "YYYY-MM-DD|HH:mm" -> appointment_id (concurrency lock)
        self.service_categories: List[Dict[str, Any]] = []
        self.services: List[Dict[str, Any]] = []
        self.offers: List[Dict[str, Any]] = []
        self.job_card_photos: Dict[str, Dict[str, Any]] = {}
        self.repair_conversations: Dict[str, Dict[str, Any]] = {}
        self.repair_messages: Dict[str, List[Dict[str, Any]]] = {}
        self.mechanics: Dict[str, Dict[str, Any]] = {}
        self.rate_limit_hits: Dict[str, List[float]] = {}
        self.auth_tokens: Dict[str, Dict[str, Any]] = {} # token -> user info
        self._seed_initial_data()

    def _seed_initial_data(self):
        # Admin user
        admin_id = str(uuid.uuid4())
        self.users[admin_id] = {
            "id": admin_id,
            "email": "admin@servio.com",
            "fullName": "System Administrator",
            "phone": "+15550000001",
            "role": "ADMIN",
            "isAdmin": True,
            "password": "AdminPassword123!",
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        self.users_by_email["admin@servio.com"] = admin_id

        # Mechanic staff
        self.mechanics["mechanic@servio.com"] = {
            "id": 1,
            "email": "mechanic@servio.com",
            "fullName": "Senior Technician Dave",
            "specialization": "Engine & Transmission",
            "experienceYears": 8,
            "isActive": True,
        }

        # Categories and services
        cat1 = {"id": 1, "name": "Periodic Maintenance", "slug": "maintenance", "displayOrder": 1, "isActive": True}
        cat2 = {"id": 2, "name": "Brakes & Suspension", "slug": "brakes", "displayOrder": 2, "isActive": True}
        self.service_categories = [cat1, cat2]

        s1 = {
            "id": 1,
            "name": "Full Synthetic Oil & Filter Change",
            "categoryId": 1,
            "categoryName": "Periodic Maintenance",
            "basePrice": 89.99,
            "estimatedDurationMinutes": 45,
            "isFeatured": True,
            "isActive": True,
            "description": "Premium 0W-20 or 5W-30 synthetic oil change with OEM filter inspection.",
        }
        s2 = {
            "id": 2,
            "name": "Comprehensive Brake Pad Replacement",
            "categoryId": 2,
            "categoryName": "Brakes & Suspension",
            "basePrice": 149.99,
            "estimatedDurationMinutes": 60,
            "isFeatured": True,
            "isActive": True,
            "description": "Front/Rear ceramic brake pad replacement and rotor inspection.",
        }
        self.services = [s1, s2]

        self.offers = [
            {
                "id": 1,
                "title": "Spring Tune-Up 20% Off",
                "code": "SPRING20",
                "discountPercentage": 20.0,
                "validUntil": "2026-12-31T23:59:59Z",
                "isActive": True,
            }
        ]


db = MockDatabase()


class MockRequestHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress default server access logs

    def _send_json(self, status: int, data: Any, extra_headers: Optional[Dict[str, str]] = None):
        response_bytes = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json;charset=UTF-8")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept")
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, str(v))
        self.end_headers()
        self.wfile.write(response_bytes)

    def _send_error(self, status: int, error_title: str, message: str, extra_headers: Optional[Dict[str, str]] = None):
        error_response = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()),
            "status": status,
            "error": error_title,
            "message": message,
            "path": self.path.split("?")[0],
            "traceId": str(uuid.uuid4()),
        }
        self._send_json(status, error_response, extra_headers=extra_headers)

    def _get_auth_user(self) -> Optional[Dict[str, Any]]:
        auth_header = self.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return None
        token = auth_header[7:].strip()
        with db.lock:
            return db.auth_tokens.get(token)

    def _check_rate_limit(self, client_ip: str, max_requests: int = 5, window_seconds: float = 60.0) -> bool:
        now = time.time()
        with db.lock:
            hits = db.rate_limit_hits.setdefault(client_ip, [])
            # Filter hits within window
            hits = [t for t in hits if now - t < window_seconds]
            if len(hits) >= max_requests:
                db.rate_limit_hits[client_ip] = hits
                return False
            hits.append(now)
            db.rate_limit_hits[client_ip] = hits
            return True

    def _read_json_body(self) -> Optional[Dict[str, Any]]:
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            return {}
        raw = self.rfile.read(content_length).decode("utf-8")
        try:
            return json.loads(raw)
        except Exception:
            return None

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        if not path:
            path = "/"
        query = urllib.parse.parse_qs(parsed.query)

        # 1. Actuator Endpoints
        if path == "/actuator/health":
            return self._send_json(200, {
                "status": "UP",
                "components": {
                    "db": {"status": "UP", "details": {"database": "PostgreSQL", "validationQuery": "isValid()"}},
                    "diskSpace": {"status": "UP", "details": {"total": 50000000000, "free": 35000000000}},
                    "ping": {"status": "UP"}
                }
            })
        if path == "/actuator/info":
            return self._send_json(200, {"app": {"name": "Servio Backend", "version": "1.0.0"}})
        if path.startswith("/actuator/metrics"):
            user = self._get_auth_user()
            if not user or user.get("role") != "ADMIN":
                return self._send_error(403, "Forbidden", "Access Denied: Admin role required for metrics")
            return self._send_json(200, {"names": ["jvm.memory.used", "http.server.requests"]})

        # 2. Auth Endpoints
        if path == "/api/auth/health":
            return self._send_json(200, {
                "success": True,
                "message": "Server is running",
                "data": {"status": "Server is running", "database": "Connected"}
            })

        if path == "/api/auth/profile":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Full authentication is required to access this resource")
            return self._send_json(200, {
                "success": True,
                "data": {
                    "id": user["id"],
                    "email": user["email"],
                    "fullName": user["fullName"],
                    "phone": user.get("phone", ""),
                    "role": user["role"],
                    "isAdmin": user.get("isAdmin", False)
                }
            })

        if path == "/api/auth/mechanic-registration":
            email = query.get("email", [""])[0]
            with db.lock:
                mechanic = db.mechanics.get(email)
            if not mechanic:
                return self._send_json(404, {"success": False, "message": "No mechanic registration found for this email", "data": None})
            return self._send_json(200, {"success": True, "message": "Mechanic registration found", "data": mechanic})

        # 3. Services & Catalog
        if path == "/api/services/categories":
            with db.lock:
                cats = list(db.service_categories)
                for cat in cats:
                    cat_services = [s for s in db.services if s.get("categoryId") == cat["id"]]
                    cat["services"] = cat_services
            return self._send_json(200, {"success": True, "data": cats})

        if path == "/api/services":
            with db.lock:
                return self._send_json(200, {"success": True, "data": list(db.services)})

        if path == "/api/services/featured":
            with db.lock:
                featured = [s for s in db.services if s.get("isFeatured")]
            return self._send_json(200, {"success": True, "data": featured})

        if path == "/api/services/offers":
            with db.lock:
                return self._send_json(200, {"success": True, "data": list(db.offers)})

        if path == "/api/services/search":
            q = query.get("q", [""])[0].lower()
            with db.lock:
                results = [s for s in db.services if q in s["name"].lower() or q in s.get("description", "").lower()]
            return self._send_json(200, {"success": True, "data": results})

        service_match = re.match(r"^/api/services/(\d+)$", path)
        if service_match:
            sid = int(service_match.group(1))
            with db.lock:
                svc = next((s for s in db.services if s["id"] == sid), None)
            if not svc:
                return self._send_error(404, "Not Found", f"Service not found with id: {sid}")
            return self._send_json(200, {"success": True, "data": svc})

        # 4. Vehicles
        if path == "/api/vehicles/my":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            with db.lock:
                user_vehicles = [v for v in db.vehicles.values() if v.get("userId") == user["id"]]
            return self._send_json(200, {"success": True, "message": "My vehicles retrieved successfully", "data": user_vehicles})

        vehicle_match = re.match(r"^/api/vehicles/([a-f0-9\-]+|\d+)$", path)
        if vehicle_match:
            vid = vehicle_match.group(1)
            with db.lock:
                veh = db.vehicles.get(vid)
            if not veh:
                return self._send_error(404, "Not Found", f"Vehicle not found with id: {vid}")
            return self._send_json(200, {"success": True, "message": "Vehicle retrieved successfully", "data": veh})

        vehicle_stats_match = re.match(r"^/api/vehicles/([a-f0-9\-]+|\d+)/stats$", path)
        if vehicle_stats_match:
            vid = vehicle_stats_match.group(1)
            return self._send_json(200, {
                "success": True,
                "message": "Vehicle statistics retrieved successfully",
                "data": {"vehicleId": vid, "totalAppointments": 2, "totalSpent": 239.98, "lastServiceDate": "2026-08-15"}
            })

        # 5. Appointments
        if path == "/api/appointments/booked-slots":
            date_str = query.get("date", [""])[0]
            with db.lock:
                slots = [k.split("|")[1] for k in db.booked_slots.keys() if k.startswith(f"{date_str}|")]
            return self._send_json(200, {"success": True, "message": "Booked slots retrieved successfully", "data": slots})

        if path == "/api/appointments/my":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            with db.lock:
                user_appts = [a for a in db.appointments.values() if a.get("userId") == user["id"]]
            return self._send_json(200, {"success": True, "message": "My appointments retrieved successfully", "data": user_appts})

        appt_match = re.match(r"^/api/appointments/([a-f0-9\-]+|\d+)$", path)
        if appt_match:
            aid = appt_match.group(1)
            with db.lock:
                appt = db.appointments.get(aid)
            if not appt:
                return self._send_error(404, "Not Found", f"Appointment not found with id: {aid}")
            return self._send_json(200, {"success": True, "message": "Appointment retrieved successfully", "data": appt})

        # 6. Repair Chat
        chat_conv_match = re.match(r"^/api/repairs/(\d+)/conversation$", path)
        if chat_conv_match:
            rid = chat_conv_match.group(1)
            with db.lock:
                conv = db.repair_conversations.setdefault(rid, {
                    "id": int(rid),
                    "repairJobId": int(rid),
                    "title": f"Repair #{rid} Support Channel",
                    "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                })
            return self._send_json(200, {"success": True, "message": "Conversation retrieved successfully", "data": conv})

        chat_msg_match = re.match(r"^/api/repairs/(\d+)/messages$", path)
        if chat_msg_match:
            rid = chat_msg_match.group(1)
            with db.lock:
                msgs = db.repair_messages.get(rid, [])
            return self._send_json(200, {"success": True, "message": "Messages retrieved successfully", "data": msgs})

        # 7. Inspection Photos
        photos_job_card_match = re.match(r"^/api/admin/job-card-photos/job-card/(\d+)$", path)
        if photos_job_card_match:
            jcid = photos_job_card_match.group(1)
            with db.lock:
                photos = [p for p in db.job_card_photos.values() if str(p.get("jobCardId")) == jcid]
            return self._send_json(200, {"success": True, "message": "Photos retrieved successfully", "data": photos})

        photo_id_match = re.match(r"^/api/admin/job-card-photos/(\d+)$", path)
        if photo_id_match:
            pid = photo_id_match.group(1)
            with db.lock:
                photo = db.job_card_photos.get(pid)
            if not photo:
                return self._send_error(404, "Not Found", f"Photo not found with id: {pid}")
            return self._send_json(200, {"success": True, "message": "Photo retrieved successfully", "data": photo})

        # 8. Admin Guarded Endpoints
        if path.startswith("/api/admin"):
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Full authentication required")
            if user.get("role") != "ADMIN":
                return self._send_error(403, "Forbidden", "Access Denied: Requires ADMIN authority")
            if path == "/api/admin/dashboard/stats":
                return self._send_json(200, {"success": True, "data": {"totalRevenue": 15420.50, "activeAppointments": 8, "totalStaff": 5}})
            return self._send_json(200, {"success": True, "data": []})

        # 9. Web Client / SPA Routing Emulation
        if path in ["/login", "/signup", "/home", "/services", "/activity", "/admin", "/admin/dashboard"] or path.startswith("/appointment/"):
            html_body = f"<!DOCTYPE html><html><head><title>Servio SPA</title></head><body><div id='root'>Route {path} Rendered</div></body></html>"
            response_bytes = html_body.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html;charset=UTF-8")
            self.send_header("Content-Length", str(len(response_bytes)))
            self.end_headers()
            self.wfile.write(response_bytes)
            return

        return self._send_error(404, "Not Found", f"No endpoint found for {path}")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        client_ip = self.client_address[0]

        # 1. Auth Rate Limiting on /api/auth/**
        if path.startswith("/api/auth/"):
            # Exclude health check from rate limiting
            if path != "/api/auth/health":
                is_rate_limit_test = self.headers.get("X-Test-Rate-Limit") == "1"
                max_reqs = 5 if is_rate_limit_test else 1000
                if not self._check_rate_limit(client_ip, max_requests=max_reqs, window_seconds=10.0):
                    return self._send_error(
                        429,
                        "Too Many Requests",
                        "Rate limit exceeded. Please wait before retrying.",
                        extra_headers={"Retry-After": "10", "X-Rate-Limit-Retry-After-Seconds": "10"}
                    )

        # 2. Signup
        if path == "/api/auth/signup":
            body = self._read_json_body()
            if body is None:
                return self._send_error(400, "Bad Request", "Invalid JSON payload")
            email = body.get("email")
            password = body.get("password")
            full_name = body.get("fullName", "")
            if not email or "@" not in email or not password or len(password) < 6:
                return self._send_error(400, "Bad Request", "Valid email and password (>=6 chars) are required")

            with db.lock:
                if email in db.users_by_email:
                    return self._send_error(409, "Conflict", "A user with this email already exists")
                user_id = str(uuid.uuid4())
                user_record = {
                    "id": user_id,
                    "email": email,
                    "fullName": full_name,
                    "phone": body.get("phone", ""),
                    "role": "USER",
                    "isAdmin": False,
                    "password": password,
                    "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }
                db.users[user_id] = user_record
                db.users_by_email[email] = user_id
                token = f"jwt_mock_{uuid.uuid4().hex}"
                db.auth_tokens[token] = user_record

            return self._send_json(201, {
                "success": True,
                "message": "User registered successfully",
                "data": {
                    "token": token,
                    "user": {"id": user_id, "email": email, "fullName": full_name, "role": "USER"}
                }
            })

        # 3. Login
        if path == "/api/auth/login":
            body = self._read_json_body()
            if not body or not body.get("email") or not body.get("password"):
                return self._send_error(400, "Bad Request", "Email and password are required")
            email = body.get("email")
            password = body.get("password")
            with db.lock:
                uid = db.users_by_email.get(email)
                user = db.users.get(uid) if uid else None
                if not user or user.get("password") != password:
                    return self._send_error(401, "Unauthorized", "Invalid email or password")
                token = f"jwt_mock_{uuid.uuid4().hex}"
                db.auth_tokens[token] = user

            return self._send_json(200, {
                "success": True,
                "message": "Login successful",
                "data": {
                    "token": token,
                    "user": {"id": user["id"], "email": user["email"], "fullName": user["fullName"], "role": user["role"], "isAdmin": user.get("isAdmin", False)}
                }
            })

        # 4. Supabase Login Exchange
        if path == "/api/auth/supabase-login":
            body = self._read_json_body()
            if not body or not body.get("accessToken") or not body.get("email"):
                return self._send_error(400, "Bad Request", "accessToken and email are required")
            email = body.get("email")
            with db.lock:
                uid = db.users_by_email.get(email)
                if not uid:
                    uid = str(uuid.uuid4())
                    user_record = {
                        "id": uid,
                        "email": email,
                        "fullName": body.get("fullName", email.split("@")[0]),
                        "phone": body.get("phone", ""),
                        "role": body.get("role", "USER"),
                        "isAdmin": body.get("role") == "ADMIN",
                        "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    }
                    db.users[uid] = user_record
                    db.users_by_email[email] = uid
                else:
                    user_record = db.users[uid]

                token = f"jwt_mock_{uuid.uuid4().hex}"
                db.auth_tokens[token] = user_record

            return self._send_json(200, {
                "success": True,
                "message": "Supabase authentication exchange successful",
                "data": {
                    "token": token,
                    "user": {"id": user_record["id"], "email": user_record["email"], "fullName": user_record["fullName"], "role": user_record["role"]}
                }
            })

        # 5. Create Vehicle
        if path == "/api/vehicles/my" or path == "/api/vehicles":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            body = self._read_json_body()
            if not body or not body.get("make") or not body.get("model") or not body.get("year"):
                return self._send_error(400, "Bad Request", "make, model, and year are required fields")
            if int(body.get("year", 0)) < 1900 or int(body.get("year", 0)) > 2100:
                return self._send_error(400, "Bad Request", "Invalid vehicle year")

            vid = str(uuid.uuid4())
            vehicle_dto = {
                "id": vid,
                "userId": user["id"],
                "make": body["make"],
                "model": body["model"],
                "year": int(body["year"]),
                "licensePlate": body.get("licensePlate", f"CAR-{vid[:4]}"),
                "vin": body.get("vin", f"1HGCR2F8{vid[:8].upper()}"),
                "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            }
            with db.lock:
                db.vehicles[vid] = vehicle_dto

            return self._send_json(201, {
                "success": True,
                "message": "Vehicle created successfully",
                "data": vehicle_dto
            })

        # 6. Create Appointment (with Pessimistic Concurrency Slot Locking)
        if path == "/api/appointments":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            body = self._read_json_body()
            if not body or not body.get("appointmentDate") or not body.get("serviceType"):
                return self._send_error(400, "Bad Request", "appointmentDate and serviceType are required")

            appt_date = body["appointmentDate"]  # format "YYYY-MM-DDTHH:mm:ss" or "YYYY-MM-DDTHH:mm"
            date_key = f"{appt_date[:10]}|{appt_date[11:16]}"

            with db.lock:
                if date_key in db.booked_slots:
                    # R3/F-08: Concurrency Conflict Double Booking Protection
                    return self._send_error(
                        409,
                        "Conflict",
                        "This time slot is already booked. Please choose another time."
                    )
                aid = str(len(db.appointments) + 1)
                db.booked_slots[date_key] = aid
                appt_dto = {
                    "id": int(aid),
                    "userId": user["id"],
                    "userEmail": user["email"],
                    "userName": user["fullName"],
                    "vehicleId": body.get("vehicleId"),
                    "serviceType": body["serviceType"],
                    "appointmentDate": appt_date,
                    "status": "PENDING",
                    "serviceBayId": body.get("serviceBayId", 1),
                    "notes": body.get("notes", ""),
                    "estimatedCost": float(body.get("estimatedCost", 89.99)),
                    "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }
                db.appointments[aid] = appt_dto

            return self._send_json(201, {
                "success": True,
                "message": "Appointment created successfully",
                "data": appt_dto
            })

        # 7. Cancel Own Appointment
        cancel_match = re.match(r"^/api/appointments/(\d+)/cancel$", path)
        if cancel_match:
            aid = cancel_match.group(1)
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            with db.lock:
                appt = db.appointments.get(aid)
                if not appt:
                    return self._send_error(404, "Not Found", f"Appointment not found with id: {aid}")
                if appt.get("userId") != user["id"] and user.get("role") != "ADMIN":
                    return self._send_error(403, "Forbidden", "You do not have permission to cancel this appointment")
                appt["status"] = "CANCELLED"
                # Release the slot lock
                date_key = f"{appt['appointmentDate'][:10]}|{appt['appointmentDate'][11:16]}"
                db.booked_slots.pop(date_key, None)

            return self._send_json(200, {
                "success": True,
                "message": "Appointment cancelled successfully",
                "data": appt
            })

        # 8. Send Repair Chat Message
        chat_msg_post = re.match(r"^/api/repairs/(\d+)/messages$", path)
        if chat_msg_post:
            rid = chat_msg_post.group(1)
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            body = self._read_json_body()
            if not body or not body.get("message"):
                return self._send_error(400, "Bad Request", "message content is required")

            msg_dto = {
                "id": str(uuid.uuid4()),
                "repairJobId": int(rid),
                "senderId": user["id"],
                "senderName": user["fullName"],
                "senderRole": user["role"],
                "message": body["message"],
                "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            }
            with db.lock:
                db.repair_messages.setdefault(rid, []).append(msg_dto)

            return self._send_json(200, {
                "success": True,
                "message": "Message sent successfully",
                "data": msg_dto
            })

        # 9. Inspection Photos Multipart Upload / JSON Add
        if path == "/api/admin/job-card-photos" or path == "/api/admin/job-card-photos/upload":
            user = self._get_auth_user()
            if not user or user.get("role") != "ADMIN":
                return self._send_error(403, "Forbidden", "Admin authority required")

            content_type = self.headers.get("Content-Type", "")
            pid = str(len(db.job_card_photos) + 1)

            if "multipart/form-data" in content_type:
                # Handle Cloudinary Multipart Upload
                raw_bytes = self.rfile.read(int(self.headers.get("Content-Length", 0)))
                # Check for oversized files (>10MB)
                if len(raw_bytes) > 10 * 1024 * 1024:
                    return self._send_error(400, "Bad Request", "File size exceeds 10MB limit")

                raw_text = raw_bytes.decode("latin1", errors="replace")
                
                # Extract photoType from multipart form data
                photo_type = "PRE_INSPECTION"
                if 'name="photoType"' in raw_text:
                    parts = raw_text.split('name="photoType"')
                    if len(parts) > 1:
                        val = parts[1].split("\r\n\r\n")[1].split("\r\n")[0].strip()
                        if val:
                            photo_type = val

                # Extract jobCardId from multipart form data
                jcid = 101
                if 'name="jobCardId"' in raw_text:
                    parts = raw_text.split('name="jobCardId"')
                    if len(parts) > 1:
                        val = parts[1].split("\r\n\r\n")[1].split("\r\n")[0].strip()
                        if val and val.isdigit():
                            jcid = int(val)

                # Extract description from multipart form data
                desc = "Inspection photo"
                if 'name="description"' in raw_text:
                    parts = raw_text.split('name="description"')
                    if len(parts) > 1:
                        val = parts[1].split("\r\n\r\n")[1].split("\r\n")[0].strip()
                        if val:
                            desc = val

                photo_dto = {
                    "id": int(pid),
                    "jobCardId": jcid,
                    "photoUrl": f"https://res.cloudinary.com/servio-demo/image/upload/v1725000000/job-cards/{jcid}/photo_{pid}.jpg",
                    "description": desc,
                    "photoType": photo_type,
                    "uploadedById": user["id"],
                    "uploadedByName": user["fullName"],
                    "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }
            else:
                body = self._read_json_body() or {}
                photo_dto = {
                    "id": int(pid),
                    "jobCardId": body.get("jobCardId", 101),
                    "photoUrl": body.get("photoUrl", f"https://res.cloudinary.com/servio/photo_{pid}.jpg"),
                    "description": body.get("description", "Inspection photo"),
                    "photoType": body.get("photoType", "DAMAGE"),
                    "uploadedById": user["id"],
                    "uploadedByName": user["fullName"],
                    "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }

            with db.lock:
                db.job_card_photos[pid] = photo_dto

            return self._send_json(200, {
                "success": True,
                "message": "Photo added successfully",
                "data": photo_dto
            })

        # 10. PayHere Server-to-Server Payment Notification
        if path == "/api/payments/payhere/notify":
            return self._send_json(200, {"status": "SUCCESS", "message": "Payment verified and recorded"})

        return self._send_error(404, "Not Found", f"No POST endpoint for {path}")

    def do_PATCH(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        query = urllib.parse.parse_qs(parsed.query)

        status_match = re.match(r"^/api/appointments/(\d+)/status$", path)
        if status_match:
            aid = status_match.group(1)
            new_status = query.get("status", [""])[0]
            with db.lock:
                appt = db.appointments.get(aid)
                if not appt:
                    return self._send_error(404, "Not Found", f"Appointment not found with id: {aid}")
                appt["status"] = new_status
                if new_status == "CANCELLED":
                    date_key = appt["appointmentDate"][:16]
                    db.booked_slots.pop(date_key, None)
            return self._send_json(200, {"success": True, "message": "Appointment status updated successfully", "data": appt})

        return self._send_error(404, "Not Found", f"No PATCH endpoint for {path}")

    def do_PUT(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")

        veh_match = re.match(r"^/api/vehicles/([a-f0-9\-]+|\d+)$", path)
        if veh_match:
            vid = veh_match.group(1)
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            body = self._read_json_body() or {}
            with db.lock:
                veh = db.vehicles.get(vid)
                if not veh:
                    return self._send_error(404, "Not Found", f"Vehicle not found with id: {vid}")
                veh.update({
                    "make": body.get("make", veh["make"]),
                    "model": body.get("model", veh["model"]),
                    "year": int(body.get("year", veh["year"])),
                    "licensePlate": body.get("licensePlate", veh["licensePlate"]),
                })
            return self._send_json(200, {"success": True, "message": "Vehicle updated successfully", "data": veh})

        return self._send_error(404, "Not Found", f"No PUT endpoint for {path}")

    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")

        # Delete Profile / Anonymize User
        if path == "/api/auth/profile":
            user = self._get_auth_user()
            if not user:
                return self._send_error(401, "Unauthorized", "Authentication required")
            with db.lock:
                uid = user["id"]
                email = user["email"]
                db.users.pop(uid, None)
                db.users_by_email.pop(email, None)
                tokens_to_remove = [t for t, u in db.auth_tokens.items() if u.get("id") == uid]
                for t in tokens_to_remove:
                    db.auth_tokens.pop(t, None)
            return self._send_json(200, {"success": True, "message": "Account deleted successfully", "data": None})

        # Delete Vehicle
        veh_match = re.match(r"^/api/vehicles/([a-f0-9\-]+|\d+)$", path)
        if veh_match:
            vid = veh_match.group(1)
            with db.lock:
                db.vehicles.pop(vid, None)
            return self._send_json(200, {"success": True, "message": "Vehicle deleted successfully", "data": None})

        # Delete Photo
        photo_match = re.match(r"^/api/admin/job-card-photos/(\d+)$", path)
        if photo_match:
            pid = photo_match.group(1)
            with db.lock:
                db.job_card_photos.pop(pid, None)
            return self._send_json(200, {"success": True, "message": "Photo deleted successfully", "data": None})

        return self._send_error(404, "Not Found", f"No DELETE endpoint for {path}")


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True


class MockServerManager:
    """Manages background lifecycle of the Mock Server."""
    def __init__(self, host: str = "127.0.0.1", port: int = 3001):
        self.host = host
        self.port = port
        self.server: Optional[ThreadedTCPServer] = None
        self.thread: Optional[threading.Thread] = None

    def start(self) -> str:
        # Try requested port or find open ephemeral port
        try:
            self.server = ThreadedTCPServer((self.host, self.port), MockRequestHandler)
        except OSError:
            self.server = ThreadedTCPServer((self.host, 0), MockRequestHandler)
            self.port = self.server.server_address[1]

        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        return f"http://{self.host}:{self.port}"

    def stop(self):
        if self.server:
            self.server.shutdown()
            self.server.server_close()
            self.server = None


# Global singleton instance for test suite runs
_oracle_instance: Optional[MockServerManager] = None


def ensure_mock_server_running(port: int = 3001) -> str:
    """Ensures mock server is active and returns base URL."""
    global _oracle_instance
    if _oracle_instance is None:
        _oracle_instance = MockServerManager(port=port)
        base_url = _oracle_instance.start()
        return base_url
    return f"http://{_oracle_instance.host}:{_oracle_instance.port}"


def reset_mock_database():
    """Resets mock database state between test runs."""
    global db
    db = MockDatabase()
