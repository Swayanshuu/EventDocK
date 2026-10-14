# EventDock Security & Threat Model

Security is fundamental to the EventDock platform. This document outlines the threat model, protections against Server-Side Request Forgery (SSRF), secret redaction, and access controls.

---

## 1. Threat Model

| Threat | Risk | Mitigation |
| :--- | :--- | :--- |
| **SSRF via Replay Service** | Attacker abuses replay to scan internal infrastructure, access cloud metadata (`169.254.169.254`), or pivot into VPC services. | Strict destination validation, DNS resolution checks before socket connect, blocking private/loopback IPs by default, and disabling HTTP redirects. |
| **Data Leakage in Stack Traces** | Sensitive tokens, passwords, or cookies captured in error reports. | Case-insensitive header redactor and recursive JSON tree masking with `***REDACTED***`. Body capture disabled by default. |
| **Credential Theft from Database** | Compromise of PostgreSQL reveals raw API keys. | API keys are stored solely as cryptographic SHA-256 hashes (`key_hash`). Plaintext secrets are never stored. |
| **Unauthorized Project Access** | Malicious user reads or replays events from another tenant's project. | Project ownership validation on every service operation (`validateOwnership`). Firebase token identity verification. |
| **Host Application Denial of Service** | Event reporting blocks or exhausts memory in host Spring Boot app. | Bounded `ArrayBlockingQueue`, non-blocking `offer`, short network timeouts, daemon worker threads. |

---

## 2. Server-Side Request Forgery (SSRF) Defenses

The `ReplayService` implements defensive measures to prevent EventDock from acting as an open proxy:

1. **Protocol Restriction**: Only `http` and `https` schemes are accepted. Protocols such as `file://`, `ftp://`, `gopher://`, and `ldap://` are rejected.
2. **DNS Resolution Verification**: Before issuing any network socket call, the target hostname is resolved via `InetAddress.getAllByName(host)`.
3. **Restricted IP Blocking**: Any target resolving to:
   - Loopback (`127.0.0.0/8`, `::1`)
   - Link-Local (`169.254.0.0/16`)
   - RFC 1918 Private Ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`)
   - Cloud Provider Metadata Services (`169.254.169.254`, `metadata.google.internal`)
   is strictly blocked unless `eventdock.replay.allow-local-dev=true` AND the hostname is explicitly white-listed in `eventdock.replay.allowed-hosts`.
4. **Denial of Automatic HTTP Redirects**: `HttpClient.Redirect.NEVER` is configured. Following redirects automatically could permit an external server to redirect EventDock to an internal resource after initial hostname validation.
5. **Method Safety Safeguard**: Replaying state-changing HTTP methods (`POST`, `PUT`, `DELETE`, `PATCH`) requires explicit developer confirmation (`confirmUnsafeMethod=true`).

---

## 3. Secret and Data Redaction

### Headers
Configured in `eventdock.redaction.headers`. The following headers are automatically scrubbed by default:
- `Authorization`
- `Proxy-Authorization`
- `Cookie`
- `Set-Cookie`
- `X-Api-Key`
- `X-Auth-Token`
- `X-EventDock-Api-Key`

### Body Fields
When body capture is explicitly enabled (`eventdock.capture.body-enabled=true`), JSON payloads are parsed by `BodyRedactor` and keys matching the following are replaced with `"***REDACTED***"`:
- `password`, `secret`, `token`, `accessToken`, `refreshToken`, `apiKey`, `cardNumber`, `cvv`, `ssn`, `privateKey`.
