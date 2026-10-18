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

## Overview

**EventDock** bridges the gap between backend runtime failures and developer resolution. Instead of sifting through massive, noisy log aggregators or trying to manually reconstruct broken HTTP payloads, developers simply add `eventdock-starter` to their Spring Boot microservices.

When an unhandled HTTP 500 error, database deadlock, or unexpected exception occurs:

1. **Automatic Capture**: Intercepts HTTP request metadata, headers, query parameters, bodies, and nested exception stack traces.
2. **Automated PII & Secret Scrubbing**: Recursively sanitizes authorization headers, session cookies, JWTs, passwords, and sensitive keys _before_ payloads leave your JVM.
3. **Zero Ingestion Latency**: Dispatches diagnostic telemetry via an asynchronous non-blocking ring buffer, preventing thread exhaustion or API performance degradation.
4. **1-Click Request Replay**: Safely re-executes captured failure payloads against local dev (`http://localhost:8080`) or staging environments with full SSRF guardrails.

---

## Architecture

```
+-------------------------------------------------------------------------+
|                  Host Spring Boot Application (JVM)                     |
|                                                                         |
|  [Servlet Filter]  --->  [HandlerExceptionResolver]  --->  [Redactor]   |
+-------------------------------------------------------------------------+
                                    |
                                    | (Non-blocking Async Ingestion)
                                    v
+-------------------------------------------------------------------------+
|                  EventDock Ingestion API (Spring Boot 3.4)              |
|                                                                         |
|  [API Key Validator]  --->  [Event Repository]  --->  [SSRF Guardrail]  |
+-------------------------------------------------------------------------+
            |                                             |
            v (PostgreSQL / Supabase)                     v (Safe HTTP Replay)
+-----------------------+                     +---------------------------+
| Persistent Database   |                     | Local / Staging Target    |
| - Tenant Projects     |                     | (http://localhost:8081)   |
| - Sanitized Payloads  |                     +---------------------------+
| - Replay Audits       |                                   ^
+-----------------------+                                   |
            ^                                               |
            | (Secure Auth & REST)                          |
+-----------------------------------------+                 |
| Flutter Web Platform & Interactive CLI  |-----------------+
| • Web: https://eventdock.swynx.dev      |
| • CLI: java -jar eventdock-cli.jar      |
+-----------------------------------------+
```

---

## Monorepo Modules

EventDock is maintained as a cohesive Maven multi-module architecture:

| Module                    | Technology                     | Description                                                                                             | Path                                          |
| :------------------------ | :----------------------------- | :------------------------------------------------------------------------------------------------------ | :-------------------------------------------- |
| **`eventdock-starter`**   | Spring Boot 3.4, Java 21       | Lightweight auto-configuring client starter library embedded into user microservices (Published to Maven Central). | [`eventdock-starter/`](eventdock-starter)     |
| **`eventdock-api`**       | Spring Boot 3.4, PostgreSQL    | Core backend service for ingestion, tenant project management, and SSRF-safe request replay.            | [`eventdock-api/`](eventdock-api)             |
| **`eventdock-dashboard`** | Flutter 3.x Web, Glassmorphism | Dark-mode developer web dashboard for real-time failure triage and waitlist landing page.               | [`eventdock-dashboard/`](eventdock-dashboard) |
| **`eventdock-cli`**       | Java 21, Picocli               | High-velocity terminal CLI tool for querying failures, inspecting stack traces, and triggering replays. | [`eventdock-cli/`](eventdock-cli)             |

---

## Adding EventDock Starter to Your Spring Boot Application

`eventdock-starter` is officially published to **Maven Central**. You can add it directly to any Spring Boot 3.x project running on Java 17 or Java 21:

### 1. Artifact Coordinates

- **Group ID**: `dev.swynx`
- **Artifact ID**: `eventdock-starter`
- **Latest Version**: `0.1.0`
- **Direct Repository URL**: [https://repo1.maven.org/maven2/dev/swynx/eventdock-starter/0.1.0/](https://repo1.maven.org/maven2/dev/swynx/eventdock-starter/0.1.0/)
- **Central Sonatype Portal**: [https://central.sonatype.com/artifact/dev.swynx/eventdock-starter/0.1.0](https://central.sonatype.com/artifact/dev.swynx/eventdock-starter/0.1.0)

> [!NOTE]
> **Maven Central vs Third-Party Indexers (like MVNRepository)**:
> The artifact is fully published and immediately resolvable from the primary Maven Central canonical repository (`repo1.maven.org`). Third-party directory mirrors like `mvnrepository.com` run scheduled crawlers that may take 24–48 hours to update their web search listings. However, Maven and Gradle fetch directly from `repo1.maven.org` and will resolve the dependency right away!

---

### 2. Dependency Declaration

#### Apache Maven (`pom.xml`):

```xml
<dependency>
    <groupId>dev.swynx</groupId>
    <artifactId>eventdock-starter</artifactId>
    <version>0.1.0</version>
</dependency>
```

#### Gradle (Groovy DSL `build.gradle`):

```groovy
dependencies {
    implementation 'dev.swynx:eventdock-starter:0.1.0'
}
```

#### Gradle (Kotlin DSL `build.gradle.kts`):

```kotlin
dependencies {
    implementation("dev.swynx:eventdock-starter:0.1.0")
}
```

---

### 3. Configuration (`application.yml` or `application.properties`)

Create or update your `src/main/resources/application.yml`:

```yaml
eventdock:
  # Enable or disable the starter (useful for disabling in local unit tests)
  enabled: true

  # EventDock cloud ingestion endpoint (default) or self-hosted API
  endpoint: "https://api.eventdock.swynx.dev"

  # Your project ingestion API key generated from the dashboard (ed_live_...)
  api-key: "${EVENTDOCK_API_KEY}"

  # Logical identifier for your service
  service-name: "order-service"

  # Environment tag attached to telemetry (e.g. production, staging, dev)
  environment: "${SPRING_PROFILES_ACTIVE:production}"

  # Status code threshold to capture (default: 400 captures client and server errors)
  min-status-code: 400
  capture-client-errors: true
  capture-server-errors: true

  # Request body capture parameters
  capture:
    body-enabled: true
    max-body-length: 4096
    max-stack-trace-frames: 35

  # In-JVM secret scrubbing rules (scrubbed BEFORE network transmission)
  redaction:
    headers:
      - "authorization"
      - "cookie"
      - "x-api-key"
      - "set-cookie"
    body-fields:
      - "password"
      - "secret"
      - "token"
      - "creditCard"
      - "ssn"

  # Asynchronous non-blocking queue (zero thread latency impact)
  queue:
    capacity: 500
    batch-size: 20
    flush-interval-ms: 500
```

Or using `application.properties`:

```properties
eventdock.enabled=true
eventdock.endpoint=https://api.eventdock.swynx.dev
eventdock.api-key=${EVENTDOCK_API_KEY}
eventdock.service-name=order-service
eventdock.environment=production
eventdock.min-status-code=400
eventdock.capture-client-errors=true
eventdock.capture-server-errors=true
```

---

### 4. Zero Custom Code Required

`eventdock-starter` uses standard Spring Boot auto-configuration (`@AutoConfiguration`). When included on the classpath:
- It automatically registers the non-blocking servlet filter to buffer and capture requests safely.
- It attaches an MVC exception resolver to capture root causes and stack traces on unexpected failures.
- It begins asynchronous background dispatch to EventDock with zero ingestion latency and automatic PII sanitization.
- No `@EnableEventDock` or manual bean configuration is required!

---

### 5. Verifying Your Setup

To test that your application is reporting errors to EventDock:

1. Add a temporary test controller endpoint to your application:
   ```java
   @RestController
   public class DiagnosticTestController {
       @GetMapping("/test-eventdock-failure")
       public String triggerFailure() {
           throw new IllegalStateException("EventDock verification test exception");
       }
   }
   ```
2. Start your application and curl the endpoint:
   ```bash
   curl -i http://localhost:8080/test-eventdock-failure
   ```
3. Open your project on [https://eventdock.swynx.dev](https://eventdock.swynx.dev) or inspect via CLI (`eventdock events`) to see the captured event with sanitized payload, headers, and full stack trace.

---

## Running the Platform Locally

For contributors running the full EventDock backend platform locally:

### One-Command Launch (Windows PowerShell)

```powershell
# Compiles starter, launches API (8080), and opens Dashboard:
.\run-all.ps1
```

### Clean Shutdown

```powershell
# Shuts down all running background processes and frees ports:
.\stop-all.ps1
```

---

## Security & SSRF Protection

EventDock is built with defense-in-depth principles:

- **Hashed API Keys**: Ingestion API keys (`ed_live_...`) are stored in the database exclusively as SHA-256 hashes (`key_hash`). Plaintext keys are shown only once upon creation.
- **Client-Side Sanitization**: Redaction happens inside your host JVM _before_ network transport. Passwords and tokens never leave your network boundary.
- **SSRF Replay Guardrails**:
  - DNS pre-resolution blocks loopbacks, link-local addresses (`169.254.169.254`), and cloud metadata endpoints unless explicitly overridden in developer mode.
  - Automatically disables HTTP redirect following (`HttpClient.Redirect.NEVER`).
  - Strict method whitelisting with confirmation required for state-changing calls (`POST`, `PUT`, `DELETE`).
- **Row-Level Tenant Isolation**: All projects and events are cryptographically bound to authenticated user accounts.

---

## Command-Line Interface (`eventdock-cli`)

Inspect errors directly from your terminal:

```bash
# Build standalone shaded CLI binary:
mvn clean package -pl eventdock-cli -DskipTests

# Run the CLI:
java -jar eventdock-cli/target/eventdock-cli-0.1.0-shaded.jar --help
```

### Example Commands:

```bash
# Authenticate session
eventdock login

# List all monitored microservices
eventdock projects

# Stream recent 5xx failure events
eventdock events --project <PROJECT_UUID> --status 500

# Replay a specific failure against your local machine
eventdock replay <EVENT_UUID> --target http://localhost:8080/api/endpoint
```

---

## Comprehensive Documentation

Explore detailed architectural specifications and design guides:

- [**ABOUT.md**](ABOUT.md) — 18-section comprehensive platform blueprint and component breakdown.
- [**Architecture Guide**](docs/architecture.md) — Subsystem sequence diagrams and event lifecycle.
- [**API Reference**](docs/api-reference.md) — OpenAPI / REST endpoint specifications and schemas.
- [**Database Schema**](docs/database-schema.md) — PostgreSQL table definitions, indexes, and migrations.
- [**Security & Threat Model**](docs/security.md) — Threat vectors, sanitization policies, and SSRF mitigations.
- [**Troubleshooting**](docs/troubleshooting.md) — Common operational issues and resolutions.

---

## Community & Early Access

Join developers triaging backend errors with zero overhead:

- **Live Landing & Waitlist**: [https://eventdock.swynx.dev](https://eventdock.swynx.dev)
- **Maven Central Repository**: [dev.swynx:eventdock-starter](https://central.sonatype.com/artifact/dev.swynx/eventdock-starter)
- **Support & Inquiries**: [swynx.dev@gmail.com](mailto:swynx.dev@gmail.com)

---

## 📄 License

EventDock is distributed under the [Apache 2.0 License](LICENSE).
