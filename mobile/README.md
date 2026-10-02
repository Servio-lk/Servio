# Servio Mobile Development Guide

This directory contains the Flutter multi-app workspace managed via Melos:
- **`apps/customer_app`**: Customer mobile application for booking and tracking vehicle services.
- **`apps/mechanic_app`**: Staff & mechanic application for service tracking, inspection, and task completion.
- **`packages/shared_core`**: Shared UI design system, authentication flows, API client, models, and Supabase integration.

---

## Backend API Connectivity & Device Setup

By default, the Flutter apps connect to the Spring Boot REST API on port `3001`. The networking behavior differs depending on whether you run on an **Android Emulator**, a **Physical Android Device (via USB/Wi-Fi)**, or **iOS/Desktop/Web**.

### 1. Running on a Physical Android Device (e.g., via USB or Wireless ADB)

> [!IMPORTANT]
> `http://10.0.2.2:3001` only exists inside the Android Studio Virtual Device (AVD). On a physical phone, `10.0.2.2` does not route anywhere and will cause `ApiException: Request timed out. Please try again.` after 15 seconds.

#### Method A: ADB Reverse Port Forwarding (Recommended)
Forward the phone's local port `3001` over ADB directly to your development machine:

```bash
# 1. Reverse port 3001 from device to your computer
adb reverse tcp:3001 tcp:3001

# 2. Run the app pointing to loopback (127.0.0.1)
flutter run --dart-define=SERVIO_API_BASE_URL=http://127.0.0.1:3001/api
```

*(If you have multiple devices connected, specify the device ID: `adb -s <DEVICE_ID> reverse tcp:3001 tcp:3001`)*.

#### Method B: Local Network (Wi-Fi IP)
Ensure both your development computer and your physical phone are connected to the **same Wi-Fi network**.

1. Find your computer's local IP address:
   - **macOS**: `ipconfig getifaddr en0` (or `ipconfig getifaddr en1`)
   - **Linux**: `hostname -I | awk '{print $1}'`
   - **Windows**: `ipconfig` (look for IPv4 Address)

2. Run the Flutter app with your computer's IP:
   ```bash
   flutter run --dart-define=SERVIO_API_BASE_URL=http://<YOUR_LAN_IP>:3001/api
   ```
   *Example:*
   ```bash
   flutter run --dart-define=SERVIO_API_BASE_URL=http://10.212.214.182:3001/api
   ```

---

### 2. Running on the Android Studio Emulator (AVD)

The emulator has an internal alias `10.0.2.2` that automatically maps to your host machine's `localhost`.

No extra flags are needed:
```bash
flutter run
```
`ApiConfig` automatically defaults to `http://10.0.2.2:3001/api` when `Platform.isAndroid` is detected without an override.

---

### 3. Running on macOS / iOS Simulator / Chrome

For iOS Simulator or Web/Desktop, `localhost` maps directly to your host machine:
```bash
flutter run -d macos
# or
flutter run -d chrome
```

---

## App Launch Commands

### Mechanic App
```bash
cd apps/mechanic_app

# For physical Android device with adb reverse:
adb reverse tcp:3001 tcp:3001
flutter run --dart-define=SERVIO_API_BASE_URL=http://127.0.0.1:3001/api
```

### Customer App
```bash
cd apps/customer_app

# For physical Android device with adb reverse:
adb reverse tcp:3001 tcp:3001
flutter run --dart-define=SERVIO_API_BASE_URL=http://127.0.0.1:3001/api
```

---

## Troubleshooting

### 1. `ApiException: Request timed out. Please try again.`
- **Cause**: The app is trying to reach `http://10.0.2.2:3001/api` from a physical device, or the backend server is not running.
- **Fix**: Run `adb reverse tcp:3001 tcp:3001` and pass `--dart-define=SERVIO_API_BASE_URL=http://127.0.0.1:3001/api`, or use your Mac's Wi-Fi IP address. Ensure your Spring Boot backend (`mvn spring-boot:run` in `backend/`) is active and listening on port `3001`.

### 2. `Cleartext HTTP traffic is not allowed for non-local endpoints`
- **Cause**: Network security policy blocked unencrypted HTTP traffic.
- **Fix**: `ApiClient` allows `localhost`, `127.0.0.1`, `10.0.2.2`, and standard private LAN ranges (`10.x.x.x`, `192.168.x.x`, `172.x.x.x`). For public/production endpoints, always use `https://`.

### 3. `ApiException [401]: API request failed with status code 401`
- **Cause**: The backend requires a valid Spring Boot JWT token.
- **Fix**: `SupabaseService.syncWithBackend(...)` automatically synchronizes the Supabase login session with `/api/auth/supabase-login` and caches the backend token for subsequent `ApiClient` calls.
