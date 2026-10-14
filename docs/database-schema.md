# EventDock Database Schema Documentation

The database schema is managed via Flyway in `eventdock-api/src/main/resources/db/migration/`.

---

## 1. Tables Overview

### `users`
Maps Firebase Auth identities to EventDock.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Internal user ID |
| `firebase_uid` | VARCHAR(128) | NOT NULL, UNIQUE | Firebase Auth user identifier |
| `email` | VARCHAR(255) | NOT NULL | User email address |
| `display_name`| VARCHAR(255) | | Display name |
| `role` | VARCHAR(50) | NOT NULL DEFAULT 'DEVELOPER' | User permission role |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT CURRENT_TIMESTAMP | Last update timestamp |

---

### `projects`
Developer projects / microservices.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Project ID |
| `name` | VARCHAR(150) | NOT NULL | Project name |
| `slug` | VARCHAR(150) | NOT NULL, UNIQUE | URL-safe slug |
| `description` | TEXT | | Optional description |
| `owner_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Project owner |
| `retention_days` | INT | NOT NULL DEFAULT 30 | Event retention threshold |
| `created_at` | TIMESTAMPTZ | NOT NULL | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL | Last update timestamp |

---

### `project_api_keys`
API keys used by `eventdock-starter` to submit diagnostic events.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Key ID |
| `project_id` | UUID | NOT NULL, REFERENCES projects(id) ON DELETE CASCADE | Associated project |
| `name` | VARCHAR(100) | NOT NULL | Label/description |
| `key_prefix` | VARCHAR(16) | NOT NULL | Public key prefix (e.g. `ed_live_7a91b2c4`) |
| `key_hash` | VARCHAR(64) | NOT NULL, UNIQUE | SHA-256 hash of raw key |
| `revoked` | BOOLEAN | NOT NULL DEFAULT FALSE | Revocation flag |
| `created_at` | TIMESTAMPTZ | NOT NULL | Issuance timestamp |
| `revoked_at` | TIMESTAMPTZ | | Revocation timestamp |

---

### `events`
Diagnostic failure records.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Diagnostic event ID |
| `project_id` | UUID | NOT NULL, REFERENCES projects(id) ON DELETE CASCADE | Project ID |
| `request_id` | VARCHAR(100) | NOT NULL | Correlation ID |
| `http_method` | VARCHAR(16) | NOT NULL | HTTP Method (POST, GET, etc.) |
| `route_template` | VARCHAR(255) | | Spring MVC route template |
| `request_uri` | VARCHAR(1024) | NOT NULL | Full request path |
| `status_code` | INT | NOT NULL | Response status code (e.g. 500) |
| `error_type` | VARCHAR(255) | | Exception class name |
| `sanitized_error_message` | TEXT | | Sanitized message |
| `stack_trace` | TEXT | | Sanitized stack trace |
| `duration_ms` | BIGINT | | Duration in milliseconds |
| `occurred_at` | TIMESTAMPTZ | NOT NULL | Timestamp when failure occurred |
| `received_at` | TIMESTAMPTZ | NOT NULL | Timestamp when event ingested |
| `service_name` | VARCHAR(100) | | Logical service name |
| `environment` | VARCHAR(50) | | Environment (staging, dev) |
| `metadata_json` | TEXT | | Sanitized headers and params JSON |
| `request_body` | TEXT | | Redacted request body |
| `response_body`| TEXT | | Redacted response body |

---

### `replay_attempts`
Audit history of request reproduction attempts.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PRIMARY KEY | Replay attempt ID |
| `event_id` | UUID | NOT NULL, REFERENCES events(id) ON DELETE CASCADE | Original event ID |
| `initiated_by` | VARCHAR(100) | NOT NULL | User identifier who triggered replay |
| `destination_url`| VARCHAR(1024) | NOT NULL | Approved destination URL |
| `started_at` | TIMESTAMPTZ | NOT NULL | Replay start time |
| `completed_at` | TIMESTAMPTZ | | Replay end time |
| `response_status` | INT | | HTTP status returned by destination |
| `duration_ms` | BIGINT | | Execution duration |
| `outcome` | VARCHAR(50) | NOT NULL | SUCCESS, REPRODUCED_FAILURE, NETWORK_ERROR |
| `safe_error_summary` | TEXT | | Error summary |

---

## 2. Indexes

- `idx_users_firebase_uid`: on `users(firebase_uid)` for instant user resolution.
- `idx_events_project_time`: on `events(project_id, occurred_at DESC)` for efficient inbox sorting.
- `idx_events_request_id`: on `events(request_id)` for correlation lookup.
- `idx_events_status_code`: on `events(status_code)` for status filtering (4xx vs 5xx).
- `idx_api_keys_hash`: on `project_api_keys(key_hash)` for authentication.
- `idx_replay_event_time`: on `replay_attempts(event_id, started_at DESC)`.
