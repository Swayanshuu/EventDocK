# EventDock Architecture

## 1. System Overview

EventDock is partitioned into modular boundaries to decouple diagnostic failure reporting from core application processing:

```
+-------------------------------------------------------------------+
| Host Spring Boot Application (e.g. LinkPeer)                      |
|                                                                   |
| [Servlet Filter] -> [HandlerExceptionResolver] -> [Async Queue]   |
+-------------------------------------------------------------------+
                               |
                               | (Non-blocking async HTTP POST)
                               v
+-------------------------------------------------------------------+
| EventDock API Backend (Spring Boot 3.4.x)                         |
|                                                                   |
| [API Key Filter] -> [Event Service] -> [SSRF Replay Service]      |
+-------------------------------------------------------------------+
         |                                           |
         v (JPA / Hibernate)                         v (SSRF-Safe Replay)
+------------------------+                +-------------------------+
| PostgreSQL (Flyway)    |                | Local / Staging Target  |
| Database               |                | (http://localhost:8081) |
+------------------------+                +-------------------------+
         ^                                           ^
         | (Firebase Auth REST)                      |
+------------------------+                           |
| Flutter Web Dashboard  |---------------------------+
+------------------------+
```

## 2. Core Subsystems

### 2.1 Failure Observation (`eventdock-starter`)
The starter intercepts requests using a two-pronged instrumentation approach:
1. `EventDockRequestFilter` (`OncePerRequestFilter`): Captures route URI, HTTP method, client IP, request start time, and final HTTP response status. Sets `X-Request-Id` correlation header.
2. `EventDockExceptionObserver` (`HandlerExceptionResolver` with `HIGHEST_PRECEDENCE`): Intercepts exceptions passing through Spring MVC without consuming or breaking standard `@ExceptionHandler` handling.

### 2.2 Deduplication Strategy
To prevent double reporting when both the filter and exception resolver detect a failure, `EventDockRequestFilter` maintains an atomic request attribute flag `dev.eventdock.reported`. The diagnostic event is emitted exactly once during filter completion.

### 2.3 Non-Blocking Event Reporting
The host application enqueues events into `AsyncEventQueue` (bounded `ArrayBlockingQueue`). A background daemon thread drains and batches events to `HttpEventDockReporter`. If the queue is saturated, incoming events are dropped with tracked metrics rather than back-pressuring host requests.

### 2.4 EventDock Backend (`eventdock-api`)
The backend provides REST APIs for:
- **SDK Ingestion**: Validates project API key SHA-256 hashes and persists events.
- **Developer Management**: Authenticates users via Firebase ID tokens and manages projects.
- **Replay Execution**: Validates target URLs against strict SSRF rules before initiating HTTP requests with `HttpClient`.

### 2.5 Replay Engine
Replay requests are audited and recorded separately in `replay_attempts`. The original event is treated as immutable historical evidence; replay attempts represent new, isolated test executions.
