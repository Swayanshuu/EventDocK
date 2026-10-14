# EventDock Local Development Guide

This guide walks you through setting up an end-to-end local development environment for **EventDock**, including the PostgreSQL database, Spring Boot API server, LinkPeer sample application, CLI client, and Flutter Web dashboard.

---

## 1. Prerequisites

Ensure the following tools and runtimes are installed on your machine:

| Component | Minimum Version | Verified Version | Notes |
| :--- | :--- | :--- | :--- |
| **Java JDK** | 21 LTS | 21.0.10 LTS | Eclipse Temurin or OpenJDK recommended |
| **Apache Maven** | 3.9+ | 3.9.14 | Required for building backend modules |
| **Docker & Docker Compose** | 24+ | 29.6+ | Required for PostgreSQL container |
| **Flutter SDK** | 3.22+ | 3.44.8 | Channel stable, Dart 3.12+ |
| **Git & Shell** | 2.40+ | Latest | Bash (macOS/Linux) or PowerShell 7+ (Windows) |

Verify your environment by running:
```bash
java -version
mvn -version
docker compose version
flutter --version
```

---

## 2. Monorepo Structure

```
eventdock/
├── pom.xml                     # Multi-module root reactor POM
├── docker-compose.yml          # Local PostgreSQL database and infra
├── .env.example                # Example environment variables
├── scripts/                    # dev, test, build scripts (Bash & PowerShell)
├── eventdock-starter/          # Spring Boot starter client library (autocapture & redaction)
├── eventdock-api/              # Central REST API & PostgreSQL persistence service
├── eventdock-sample/           # LinkPeer sample demo Spring Boot service
├── eventdock-cli/              # Picocli command-line terminal client
├── eventdock-dashboard/        # Flutter Web developer dashboard
└── docs/                       # Technical architecture & operational manuals
```

---

## 3. Starting the Local Database

EventDock stores projects, events, replay logs, and audit trails in PostgreSQL 16. Start the local database container via Docker Compose:

```bash
# In the repository root:
docker compose up -d eventdock-db
```

Check database container status:
```bash
docker compose ps
```

The database will be exposed locally on port `5432` with credentials:
- **Database Name:** `eventdock`
- **Username:** `postgres`
- **Password:** `postgres`

Flyway database migrations run automatically when `eventdock-api` boots up.

---

## 4. Building the Backend Modules

Build the multi-module Maven project and install `eventdock-starter` to your local Maven repository (`~/.m2/repository`):

```bash
# Build all modules and run unit tests:
mvn clean install
```

To build without running tests for faster iteration:
```bash
mvn clean install -DskipTests
```

---

## 5. Running the Backend API (`eventdock-api`)

The API server runs on port `8080` by default.

```bash
cd eventdock-api
mvn spring-boot:run
```

Or run via jar after building:
```bash
java -jar eventdock-api/target/eventdock-api-1.0.0.jar
```

Verify health endpoints:
```bash
curl http://localhost:8080/actuator/health
```

### Firebase Authentication in Local Dev
For local development, `FirebaseAuthVerifier` supports development tokens formatted as `dev_<uid>` or `test_<uid>`.
Example header:
```http
Authorization: Bearer dev_usr_developer_01
```

---

## 6. Running the Sample Application (`eventdock-sample`)

`eventdock-sample` simulates a downstream microservice called **LinkPeer** that integrates `eventdock-starter`. It runs on port `8081`.

Before starting, obtain an API key for your project in the EventDock dashboard or CLI, then start the sample app:

```bash
cd eventdock-sample
mvn spring-boot:run -Deventdock.api-key="ed_live_your_actual_key_here"
```

Test sample failure endpoints:
```bash
# Trigger an unexpected NullPointerException (500 Internal Server Error):
curl -X POST http://localhost:8081/demo/fail

# Trigger a validation error (400 Bad Request):
curl -X POST http://localhost:8081/demo/bad-request \
  -H "Content-Type: application/json" \
  -d '{"title": ""}'

# Trigger an external downstream timeout (504 Gateway Timeout):
curl -X GET http://localhost:8081/demo/timeout
```

The `eventdock-starter` library captures the failure, redacts sensitive headers, strips authorization cookies, and asynchronously dispatches a diagnostic event payload to `http://localhost:8080/api/v1/events/ingest`.

---

## 7. Running the Developer Dashboard (`eventdock-dashboard`)

The dashboard is built with Flutter Web and runs on Chrome or Edge:

```bash
cd eventdock-dashboard
flutter pub get
flutter run -d chrome --web-port 3000
```

When the dashboard opens:
1. Sign in using the default development credentials or paste a dev token (`dev_usr_demo`).
2. Create or select a project (e.g., `LinkPeer Production`).
3. Generate an API Key under **API Keys**.
4. Inspect recorded failure events under **Event Inbox**.
5. Click **Replay Request** to safely reproduce failures against `http://localhost:8081`.

---

## 8. Running the CLI Client (`eventdock-cli`)

Build the standalone CLI jar:
```bash
mvn clean package -pl eventdock-cli
```

Run CLI commands:
```bash
java -jar eventdock-cli/target/eventdock-cli-1.0.0.jar login --token dev_usr_developer_01 --email dev@linkpeer.internal
java -jar eventdock-cli/target/eventdock-cli-1.0.0.jar projects list
java -jar eventdock-cli/target/eventdock-cli-1.0.0.jar events list --project linkpeer-backend
```

---

## 9. Automated Scripts

Platform scripts are located in `scripts/`:

### Linux / macOS
- `./scripts/dev.sh`: Starts PostgreSQL and boots both API and sample services.
- `./scripts/test.sh`: Runs all Java and Flutter unit and integration test suites.
- `./scripts/build.sh`: Builds release JARs and compiles Flutter Web.

### Windows PowerShell
- `.\scripts\dev.ps1`: Starts database container and services.
- `.\scripts\test.ps1`: Executes Maven test reactor and Flutter tests.
- `.\scripts\build.ps1`: Packages all distribution artifacts.
