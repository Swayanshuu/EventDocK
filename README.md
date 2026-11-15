<p align="center">
  <a href="https://eventdock.swynx.dev">
    <img src="assets/EventDocK-removebg-preview.png" alt="EventDock Logo" width="380" />
  </a>
</p>

<p align="center">
  <strong>Understand. Debug. Fix Faster.</strong><br>
  <em>A developer-first platform to detect, sanitize, inspect, and reproduce API failures in Spring Boot applications with zero ingestion latency.</em>
</p>

<p align="center">
  <a href="https://eventdock.swynx.dev"><img src="https://img.shields.io/badge/Live%20Platform-eventdock.swynx.dev-FF7043?style=for-the-badge&logo=vercel&logoColor=white" alt="Live Platform" /></a>
  <a href="https://central.sonatype.com/artifact/dev.swynx/eventdock-starter"><img src="https://img.shields.io/badge/Maven%20Central-dev.swynx%3Aeventdock--starter-blue?style=for-the-badge&logo=apache-maven&logoColor=white" alt="Maven Central" /></a>
  <a href="https://spring.io/projects/spring-boot"><img src="https://img.shields.io/badge/Spring%20Boot-3.4.x-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white" alt="Spring Boot 3.4.x" /></a>
  <a href="https://openjdk.org/projects/jdk/21/"><img src="https://img.shields.io/badge/Java-21%20LTS-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" alt="Java 21 LTS" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge" alt="License: Apache 2.0" /></a>
</p>

---

## What is EventDock?

When a backend service crashes in production or staging, diagnosing the failure is usually painful:
- Developers must search through thousands of lines in log management tools.
- Crucial context is missing, such as the exact request payload, HTTP headers, query parameters, and route parameters.
- Recreating the failure locally requires manually guessing what the client sent.
- Logging raw requests risks exposing passwords, tokens, and personally identifiable information (PII).

**EventDock solves this problem.**

EventDock is a developer-focused diagnostic platform built specifically for Spring Boot APIs. By adding a single lightweight starter dependency (`eventdock-starter`) to your Spring Boot application, any unhandled HTTP 500 error, database exception, or client failure is automatically detected, sanitized inside your own JVM, and sent to a central developer dashboard and CLI.

From the EventDock dashboard or terminal CLI, developers can see the exact error, the full stack trace, and the exact HTTP request that caused it—and can replay that exact request against a local development server with a single click.

---

## How It Works (For New Users)

You can think of EventDock as a flight recorder for your Spring Boot APIs:

1. **You add the starter to your project**: No manual try-catch blocks or custom code are needed. Spring Boot automatically configures the EventDock filter.
2. **An error happens**: A user makes an API request that causes an exception (e.g. `NullPointerException`, invalid payload, database timeout, or 404/500 response).
3. **EventDock intercepts the failure**: Before the response leaves the server, EventDock records the route, query parameters, status code, error type, and stack trace.
4. **Sensitive data is scrubbed in memory**: Passwords, authorization tokens, cookies, and credit card numbers are replaced with `[REDACTED]` right inside your application memory before anything leaves your server.
5. **The event is dispatched asynchronously**: The event is placed into an in-memory non-blocking queue and transmitted in the background. Your user's response time is not delayed by even a millisecond.
6. **You inspect and fix**: The failure immediately shows up on your EventDock dashboard and CLI, ready for you to inspect, copy as cURL, or replay directly against your local machine.

---

## What EventDock Solves (For Developers)

| Challenge in Traditional Logging | How EventDock Solves It |
| :--- | :--- |
| **Scattered Stack Traces** | Structured error reports grouped by microservice, environment, route template, and status code. |
| **Missing Request Context** | Captures the full HTTP context: method, URI, route template (e.g. `/posts/{id}`), query parameters, and request body. |
| **Security & PII Leaks** | Recursive in-JVM redaction scrubs sensitive fields (JWTs, session tokens, passwords) before network transmission. |
| **High Latency Overhead** | Non-blocking ring buffer architecture decouples capture from reporting; host threads are never blocked. |
| **Hard-to-Reproduce Bugs** | Built-in replay engine allows instant reproduction against `localhost:8080` with comprehensive SSRF protection. |

---

## Architecture Overview

EventDock operates as a four-tier architecture:

```
+-----------------------------------------------------------------------------------+
|                        Host Spring Boot Application (JVM)                         |
|                                                                                   |
|  [Incoming HTTP Request]                                                          |
|           |                                                                       |
|           v                                                                       |
|  [EventDockRequestFilter]  --->  [BodyRedactor & HeaderRedactor]                  |
|           |                      (Scrubs Authorization, Cookies, Passwords)       |
|           v                                                                       |
|  [AsyncEventQueue]         --->  [HttpEventDockReporter]                          |
|  (In-Memory Ring Buffer)         (Background HTTP Dispatch via Java HttpClient)   |
+-----------------------------------------------------------------------------------+
                                         |
                                         | Non-blocking JSON Telemetry
                                         v
+-----------------------------------------------------------------------------------+
|                        EventDock API Ingestion Backend                            |
|                                                                                   |
|  [API Key Authentication]  --->  [Event Repository]  --->  [SSRF Guardrail Engine]|
|  (SHA-256 Key Validation)        (PostgreSQL Persistence)   (Blocks Local/Metadata)|
+-----------------------------------------------------------------------------------+
                  |                                           |
                  | Database Storage                          | Safe Replay Dispatch
                  v                                           v
+-----------------------------------+       +---------------------------------------+
| PostgreSQL / Supabase Database    |       | Developer Target Server               |
| - Projects & Hashed API Keys      |       | (e.g., http://localhost:8080)         |
| - Sanitized Diagnostic Events     |       +---------------------------------------+
| - Replay Audit Logs               |                           ^
+-----------------------------------+                           |
                  ^                                             |
                  | Query API & Telemetry                       | CLI Replay Trigger
+---------------------------------------------------+           |
| Developer User Interfaces                         |-----------+
| - Web Dashboard: https://eventdock.swynx.dev       |
| - Terminal CLI:  dev.eventdock.cli.EventDockCli   |
+---------------------------------------------------+
```

### Event Lifecycle

1. **Capture**: `EventDockRequestFilter` wraps the incoming servlet request and response.
2. **Detection**: Upon request completion, the filter evaluates the status code and any unhandled exceptions against configured thresholds (`min-status-code`, `capture-client-errors`, `capture-server-errors`).
3. **In-JVM Sanitization**: `SensitiveDataRedactor` recursively inspects headers, query strings, and JSON request bodies, replacing matched patterns with `[REDACTED]`.
4. **Buffering**: The sanitized `DiagnosticEvent` is enqueued into `AsyncEventQueue`. If the queue is full under heavy load, excess events are safely dropped to ensure host application stability.
5. **Background Transmission**: A daemon worker thread batches and flushes events to `https://api.eventdock.swynx.dev/api/v1/events` using an isolated `java.net.http.HttpClient`.
6. **Ingestion & Indexing**: The backend validates the SHA-256 hash of the API key, stores the event, and updates project error statistics.
7. **Triage & Replay**: The engineer inspects the error on the dashboard or CLI, analyzes the stack trace, and can re-execute the request against a local server.

---

## Monorepo Modules

EventDock is organized as a multi-module repository:

| Module | Technology | Role | Location |
| :--- | :--- | :--- | :--- |
| **`eventdock-starter`** | Spring Boot 3.4 / 4.x, Java 21 | Auto-configuring Spring Boot starter library published to Maven Central. Embedded in your microservices. | [`eventdock-starter/`](eventdock-starter) |
| **`eventdock-api`** | Spring Boot 3.4, PostgreSQL, Flyway | Central ingestion server, project/API key manager, and SSRF-safe request replay engine. | [`eventdock-api/`](eventdock-api) |
| **`eventdock-dashboard`** | Flutter Web 3.x, Dart | Web dashboard for real-time error browsing, project settings, API key generation, and request replays. | [`eventdock-dashboard/`](eventdock-dashboard) |
| **`eventdock-cli`** | Java 21, Picocli | Command-line tool for developers to query events, stream errors, and replay requests directly from the terminal. | [`eventdock-cli/`](eventdock-cli) |

---

## Quickstart Guide

### 1. Add the Dependency

`eventdock-starter` is available directly on **Maven Central**.

#### Apache Maven (`pom.xml`):

```xml
<dependency>
    <groupId>dev.swynx</groupId>
    <artifactId>eventdock-starter</artifactId>
    <version>0.1.2</version>
</dependency>
```

#### Gradle (Groovy DSL `build.gradle`):

```groovy
dependencies {
    implementation 'dev.swynx:eventdock-starter:0.1.2'
}
```

#### Gradle (Kotlin DSL `build.gradle.kts`):

```kotlin
dependencies {
    implementation("dev.swynx:eventdock-starter:0.1.2")
}
```

---

### 2. Configure Your Application

Add the following properties to your `application.properties` or `application.yml`:

#### Using `application.properties`:

```properties
# Enable EventDock
eventdock.enabled=true

# Project Ingestion API key (obtain from https://eventdock.swynx.dev)
eventdock.api-key=ed_live_your_api_key_here

# Service identity
eventdock.service-name=order-service
eventdock.environment=production

# Error capture filter (capture 400 and above, or set to 500 for server errors only)
eventdock.min-status-code=400
eventdock.capture-client-errors=true
eventdock.capture-server-errors=true
```

#### Using `application.yml`:

```yaml
eventdock:
  enabled: true
  api-key: "${EVENTDOCK_API_KEY}"
  service-name: "order-service"
  environment: "${SPRING_PROFILES_ACTIVE:production}"
  min-status-code: 400
  capture-client-errors: true
  capture-server-errors: true
```

---

### 3. Verify Live Event Capture

No custom annotations or `@Bean` declarations are needed. The starter activates automatically.

To verify integration:
1. Trigger any error on your application (for example, call a non-existent endpoint or invoke an endpoint that throws an unhandled exception).
2. Check your backend console logs:
   ```text
   INFO  dev.eventdock.starter.EventDockAutoConfiguration - EventDock diagnostic starter active for service 'order-service' [production]
   DEBUG dev.eventdock.starter.filter.EventDockRequestFilter - Diagnostic event captured: GET /api/orders/99999 (500)
   DEBUG dev.eventdock.starter.reporting.HttpEventDockReporter - Dispatched diagnostic event to https://api.eventdock.swynx.dev/api/v1/events (HTTP 200)
   ```
3. Open the EventDock Dashboard at [https://eventdock.swynx.dev](https://eventdock.swynx.dev) to view the failure report.

---

## Configuration Reference

The following table lists all configuration properties supported by `eventdock-starter`:

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `eventdock.enabled` | boolean | `true` | Globally enable or disable the starter (useful for test profiles). |
| `eventdock.api-key` | String | *(required)* | Ingestion API key (`ed_live_...`) generated in the dashboard. |
| `eventdock.endpoint` | String | `https://api.eventdock.swynx.dev` | Ingestion endpoint URL. Override when self-hosting `eventdock-api`. |
| `eventdock.service-name` | String | `default-service` | Logical identifier for your microservice. |
| `eventdock.environment` | String | `development` | Deployment environment tag (e.g. `production`, `staging`, `dev`). |
| `eventdock.min-status-code` | int | `400` | Minimum HTTP status code to capture. Set to `500` to capture only server errors. |
| `eventdock.capture-client-errors` | boolean | `true` | Whether to capture 4xx client errors (400 to 499). |
| `eventdock.capture-server-errors` | boolean | `true` | Whether to capture 5xx server errors (500 to 599). |
| `eventdock.capture.body-enabled` | boolean | `true` | Capture request body payloads for debugging. |
| `eventdock.capture.max-body-length` | int | `4096` | Maximum request body bytes to capture before truncation. |
| `eventdock.capture.max-stack-trace-frames` | int | `35` | Maximum stack trace lines retained per exception. |
| `eventdock.redaction.headers` | List | `authorization, cookie, x-api-key, set-cookie` | Headers to redact before transmission. |
| `eventdock.redaction.body-fields` | List | `password, secret, token, creditCard, ssn` | JSON body fields to recursively redact before transmission. |
| `eventdock.queue.capacity` | int | `500` | In-memory ring buffer capacity for un-sent events. |
| `eventdock.queue.batch-size` | int | `20` | Maximum number of events sent in a single batch. |
| `eventdock.queue.flush-interval-ms` | long | `500` | Frequency in milliseconds at which the queue flushes events. |

---

## Capturing 5xx Server Errors Only

If you wish to keep your dashboard focused purely on unhandled backend exceptions and exclude user-driven 4xx errors (like 400 Bad Request or 404 Not Found), configure:

```properties
eventdock.min-status-code=500
eventdock.capture-client-errors=false
```

With this setting, client mistakes are ignored, and only genuine 5xx server failures are captured and reported.

---

## Security and Privacy Design

EventDock is built with defense-in-depth security principles:

1. **Client-Side Secret Redaction (In-JVM)**: Sensitive headers (tokens, cookies, auth credentials) and payload fields (passwords, card numbers, secrets) are redacted inside the host application JVM before transmission. Plaintext secrets never leave your network boundary.
2. **Hashed API Keys**: Ingestion API keys are stored in the database exclusively as SHA-256 hashes (`key_hash`). The raw key is displayed to the user only once at generation time.
3. **SSRF Replay Guardrails**:
   - Replay requests undergo DNS pre-resolution to block loopback addresses, link-local addresses (`169.254.169.254`), and cloud provider metadata services by default.
   - HTTP redirect following is strictly disabled (`HttpClient.Redirect.NEVER`).
   - High-impact methods (`POST`, `PUT`, `DELETE`) require explicit user confirmation.
4. **Tenant Isolation**: All projects, API keys, and captured diagnostic events are scoped to authenticated account tenants via foreign keys and row-level authorization.

---

## Command-Line Interface (`eventdock-cli`)

EventDock provides a dedicated command-line interface for terminal-centric workflows:

```bash
# Build the shaded CLI executable:
mvn clean package -pl eventdock-cli -DskipTests

# Run the CLI:
java -jar eventdock-cli/target/eventdock-cli-0.1.2-shaded.jar --help
```

### Common CLI Operations:

```bash
# Log in to your EventDock account
eventdock login

# List all projects
eventdock projects

# Stream recent 500 error events for a project
eventdock events --project <PROJECT_UUID> --status 500

# Inspect full stack trace and metadata for a specific event
eventdock event <EVENT_UUID>

# Safely replay a failure payload against a local development endpoint
eventdock replay <EVENT_UUID> --target http://localhost:8080/api/endpoint
```

---

## Local Development and Contribution

If you are developing or contributing to the EventDock platform itself:

### Prerequisites:
- Java 21 LTS
- Apache Maven 3.9+
- Flutter SDK 3.x (for dashboard)
- PostgreSQL 15+

### Quick Start (Windows PowerShell):

```powershell
# Launches API backend (port 8080) and Dashboard (port 5173):
.\run-all.ps1

# Stops all local EventDock background processes:
.\stop-all.ps1
```

---

## Documentation Directory

The EventDock repository includes extensive technical guides and specifications. Use the links below to explore each topic:

| Document | Purpose & Contents |
| :--- | :--- |
| [**ABOUT.md**](ABOUT.md) | Platform overview, 18-section architectural blueprint, subsystem breakdowns, and design philosophy. |
| [**CONTRIBUTING.md**](CONTRIBUTING.md) | Contribution standards, code style guidelines, pull request procedures, and branch management. |
| [**TODO.md**](TODO.md) | Production release roadmap, completed features, and upcoming milestone deliverables. |
| [**docs/how-starter-captures-exceptions.md**](docs/how-starter-captures-exceptions.md) | Clear explanation of the internal servlet filter and exception resolver mechanics that capture errors without manual try-catch code. |
| [**docs/architecture.md**](docs/architecture.md) | Formal architectural specification, system diagrams, sequence flows, and component interaction models. |
| [**docs/api-reference.md**](docs/api-reference.md) | Complete REST API documentation for ingestion endpoints, project administration, API keys, and replay services. |
| [**docs/database-schema.md**](docs/database-schema.md) | Database schema documentation covering tables, relations, indexes, constraints, and Flyway migrations. |
| [**docs/security.md**](docs/security.md) | Security policy, threat model, SSRF defense mechanisms, and data redaction specifications. |
| [**docs/local-development.md**](docs/local-development.md) | Detailed walkthrough for configuring a complete local environment (API, starter, database, CLI, dashboard). |
| [**docs/deployment.md**](docs/deployment.md) | Production deployment instructions, Docker containerization, environment variable configurations, and monitoring. |
| [**docs/publishing.md**](docs/publishing.md) | Release workflows, semantic versioning rules, and distribution procedures for all monorepo artifacts. |
| [**docs/publishing-guide.md**](docs/publishing-guide.md) | Step-by-step guide for publishing `eventdock-starter` to Maven Central via Sonatype Central Portal and GPG signing. |
| [**docs/troubleshooting.md**](docs/troubleshooting.md) | Diagnostic runbooks and solutions for common integration, serialization, network, and database issues. |
| [**eventdock-dashboard/README.md**](eventdock-dashboard/README.md) | Flutter Web dashboard setup, architectural design system, responsive layouts, and local running instructions. |

---

## License

EventDock is distributed under the [Apache License 2.0](LICENSE).
