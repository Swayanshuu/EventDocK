# Troubleshooting & Diagnostics Guide

This document contains solutions and diagnostic procedures for common operational issues encountered with **EventDock**.

---

## 1. Event Ingestion Issues

### Symptom: Events Are Not Appearing in the Dashboard
1. **Check the application logs:**
   Look for log messages with prefix `[EventDock]`.
   - If you see `[EventDock] Ingestion rejected with status 401 Unauthorized`, verify that your `eventdock.api-key` matches an active API key generated in the dashboard.
   - If you see `[EventDock] Failed to report diagnostic event: Connection refused`, verify that `eventdock.endpoint` is pointing to the correct API base URL (default: `http://localhost:8080/api/v1/events/ingest`).

2. **Verify starter queue status:**
   The starter uses an in-memory bounded queue (`AsyncEventQueue`) with capacity 1000. If the server is offline for prolonged periods, events are dropped to prevent memory leaks. Check if queue overflow warnings appear in your application logs.

3. **Verify HTTP Status Codes Captured:**
   By default, `eventdock-starter` captures requests with HTTP status `>= 400` or unhandled exceptions resulting in error status codes. Successful `2xx` and redirect `3xx` responses are intentionally ignored.

---

## 2. Request Replay Issues

### Symptom: Replay Fails With "Target URL Rejected by SSRF Security Policy"
EventDock strictly enforces SSRF protection during replay execution:
1. Destination URLs must use `http://` or `https://`.
2. Cloud metadata IPs (e.g., `169.254.169.254`) and carrier-grade NAT blocks (`100.64.0.0/10`) are strictly blocked.
3. Private network ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) are blocked in production environments unless explicitly whitelisted in `eventdock.replay.allowed-subnets`.
4. In local development environments, `localhost` and `127.0.0.1` are permitted destinations.

### Symptom: Replay Fails With "State-Changing Method Requires Confirmation"
Replaying `POST`, `PUT`, `DELETE`, or `PATCH` requests requires explicit confirmation to prevent unintended data modification:
- In the dashboard: Check the box **"I confirm executing this state-changing replay"**.
- In the CLI: Add the `--confirm` flag:
  ```bash
  eventdock replay <event-id> --target http://localhost:8081 --confirm
  ```

---

## 3. Firebase Authentication Issues

### Symptom: 401 Unauthorized When Accessing API Endpoints
1. **Expired Token:** Firebase ID tokens expire after 60 minutes. Obtain a fresh token from the Firebase SDK.
2. **Project ID Mismatch:** Verify that `FIREBASE_PROJECT_ID` configured in `eventdock-api` matches your Firebase project's audience (`aud` claim).
3. **Local Development Bypass:** If running locally without access to Firebase production keys, use the test token format:
   ```http
   Authorization: Bearer dev_usr_any_unique_id
   ```
   The `FirebaseAuthVerifier` will parse this as a mock user with email `developer@linkpeer.internal`.

---

## 4. Flutter Dashboard Issues

### Symptom: Dashboard Displays White Screen on Web
1. Ensure the web application was built with HTML or CanvasKit renderer:
   ```bash
   flutter build web --web-renderer canvaskit --release
   ```
2. Check browser developer console (`F12`) for CORS errors. If `eventdock-api` and `eventdock-dashboard` run on different ports, ensure `eventdock.cors.allowed-origins` includes `http://localhost:3000` (enabled by default in dev profile).

---

## 5. Database & Migration Issues

### Symptom: Flyway Migration Checksum Mismatch
If Flyway throws `Migration checksum mismatch for migration V1__init_schema.sql`:
1. In development, repair the schema history:
   ```bash
   mvn flyway:repair -pl eventdock-api
   ```
2. Or reset the local PostgreSQL container volume:
   ```bash
   docker compose down -v
   docker compose up -d eventdock-db
   ```
