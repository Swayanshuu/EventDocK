# EventDock REST API Reference

All requests and responses use `application/json`. Endpoints are versioned under `/api/v1`.

---

## 1. Authentication

- **User Authentication**: Send `Authorization: Bearer <firebaseIdToken>` header.
- **SDK Ingestion**: Send `X-EventDock-Api-Key: <ed_live_...>` header.

---

## 2. Ingestion Endpoints

### Ingest Diagnostic Event
`POST /api/v1/events`

**Headers**:
```http
X-EventDock-Api-Key: ed_live_38bf8c9912048f029a
Content-Type: application/json
```

**Request Body**:
```json
{
  "requestId": "corr-4a9f-88b1",
  "httpMethod": "POST",
  "requestUri": "/posts",
  "routeTemplate": "/posts",
  "statusCode": 500,
  "errorType": "java.sql.SQLException",
  "errorMessage": "Database connection pool exhausted",
  "stackTrace": "java.sql.SQLException: connection pool exhausted...",
  "durationMs": 142,
  "occurredAt": "2026-10-11T12:00:00Z",
  "metadata": {
    "User-Agent": "Mozilla/5.0",
    "Authorization": "***REDACTED***"
  },
  "serviceName": "LinkPeer",
  "environment": "staging"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Diagnostic event accepted",
  "data": {
    "id": "e72b4c10-82a1-42db-bb24-7cb529940bb2",
    "status": "RECEIVED",
    "receivedAt": "2026-10-11T12:00:00.120Z"
  }
}
```

---

## 3. Project Management

### Create Project
`POST /api/v1/projects`

**Request Body**:
```json
{
  "name": "LinkPeer Microservice",
  "description": "Feed and posts service",
  "retentionDays": 30
}
```

### List Projects
`GET /api/v1/projects`

### Generate Project Ingestion Key
`POST /api/v1/projects/{projectId}/keys`

**Request Body**:
```json
{
  "name": "Staging Cluster Key"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "data": {
    "id": "3b29c910-128a-49ca-9fa1-42d829188a10",
    "name": "Staging Cluster Key",
    "keyPrefix": "ed_live_7a91b2c4",
    "rawKey": "ed_live_7a91b2c4819a0f44bc19280d92",
    "createdAt": "2026-10-11T12:05:00Z",
    "revoked": false
  }
}
```

---

## 4. Query Events

### List Events for Project
`GET /api/v1/projects/{projectId}/events?page=0&size=20&statusCode=500&search=posts`

### Get Event Detail
`GET /api/v1/events/{eventId}`

---

## 5. Replays

### Execute Replay
`POST /api/v1/events/{eventId}/replays`

**Request Body**:
```json
{
  "destinationUrl": "http://localhost:8081",
  "confirmUnsafeMethod": true
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": "f891b201-92ab-41c3-8fa0-482a101b2c89",
    "eventId": "e72b4c10-82a1-42db-bb24-7cb529940bb2",
    "destinationUrl": "http://localhost:8081/posts",
    "startedAt": "2026-10-11T12:10:00Z",
    "completedAt": "2026-10-11T12:10:00.080Z",
    "responseStatus": 200,
    "durationMs": 80,
    "outcome": "SUCCESS",
    "responseSnippet": "{\"status\": \"PUBLISHED\"}"
  }
}
```
