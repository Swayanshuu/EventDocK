# EventDock — Release & Deployment Roadmap (What's Left To Do)

This document tracks all remaining tasks required to take **EventDock** from local development to production release and distribution.

---

## Current Status Overview

- [x] **Core Functionality**: Starter instrumentation, deduplication, secret redaction, and async dispatch.
- [x] **Backend API**: Supabase PostgreSQL 17 live integration, project management, API key hashing, event ingestion, and SSRF-safe replays.
- [x] **Dashboard**: Responsive Flutter Web UI with Google Sign-In, project onboarding, Event Inbox, stack trace inspection, and replay modal.
- [x] **Developer CLI**: Picocli CLI executable JAR (`login`, `projects`, `events`, `replay`).
- [x] **End-to-End Verification**: Tested and verified live with `eventdock-sample` (*LinkPeer*).
- [x] **Maven Publishing Prep**: Group `dev.swynx`, GPG signing keys, Central Publishing plugin, and Sonatype credentials configured.

---

## Phase 1: Publish Starter to Maven Central

Distribute `dev.swynx:eventdock-starter:0.1.0` so external developers can add it to their `pom.xml`.

- [ ] **Run Release Deployment**:
  ```powershell
  mvn clean deploy -P release -DskipTests
  ```
- [ ] **Enter GPG Passphrase** when prompted by desktop pinentry (or pass `-Dgpg.passphrase="..."`).
- [ ] **Verify on Sonatype Central Portal**:
  - Visit [central.sonatype.com](https://central.sonatype.com).
  - Verify deployment status for namespace `dev.swynx`.
  - Confirm artifacts are published: `eventdock-starter-0.1.0.jar`, `-sources.jar`, `-javadoc.jar`, and `.pom` with `.asc` signatures.
- [ ] **Verify Dependency Resolution**:
  - Test pulling `dev.swynx:eventdock-starter:0.1.0` in an external test project once indexed by Maven Central (usually 15–30 minutes).

---

## Phase 2: Deploy Backend API (`eventdock-api`) to Production

Deploy the central backend to a cloud host so it runs continuously pointing to Supabase PostgreSQL.

- [ ] **Choose Cloud Provider**:
  - Recommended options: **Railway**, **Render**, **Fly.io**, **AWS App Runner**, or **Linux VPS (Docker)**.
- [ ] **Build Production Container Image**:
  ```bash
  docker build -t ghcr.io/swayanshuu/eventdock-api:0.1.0 -f eventdock-api/Dockerfile .
  ```
- [ ] **Configure Production Environment Variables**:
  ```ini
  SPRING_PROFILES_ACTIVE=prod
  SPRING_DATASOURCE_URL=jdbc:postgresql://aws-0-ap-northeast-2.pooler.supabase.com:5432/postgres?sslmode=require
  SPRING_DATASOURCE_USERNAME=postgres.grgtlaeinlgbrejymwts
  SPRING_DATASOURCE_PASSWORD=<your-supabase-password>
  EVENTDOCK_BASE_URL=https://api.eventdock.swynx.dev
  EVENTDOCK_ALLOWED_ORIGINS=https://eventdock.swynx.dev,http://eventdock.swynx.dev
  EVENTDOCK_JWT_SECRET=<generate-min-32-char-random-secret>
  ```
- [ ] **Verify Production Health**:
  - Request `https://api.eventdock.swynx.dev/actuator/health` and verify `{"status": "UP"}`.

---

## Phase 3: Deploy Web Dashboard (`eventdock-dashboard`) to `eventdock.swynx.dev`

Deploy the compiled Flutter Web static bundle to a static hosting provider.

- [ ] **Compile Flutter Web Release**:
  ```bash
  cd eventdock-dashboard
  flutter build web --release --dart-define=EVENTDOCK_API_URL=https://api.eventdock.swynx.dev/api/v1
  ```
  *(Output is generated in `eventdock-dashboard/build/web/`)*
- [ ] **Deploy Static Files**:
  - **Option 1 (Cloudflare Pages)**: Connect repository or drag-and-drop `build/web`.
  - **Option 2 (Vercel)**: Run `vercel deploy --prod` on `eventdock-dashboard/build/web`.
  - **Option 3 (Nginx on VPS)**: Point Nginx web root to `build/web`.
- [ ] **Verify Routing**:
  - Ensure single-page application (SPA) rewrite rules are configured so all route requests fallback to `index.html`.

---

## Phase 4: Configure Production Google OAuth & Firebase

Enable real users to sign in with their Google accounts on the production domain.

- [ ] **Google Cloud Console Setup**:
  - Open **Google Cloud Console** > **APIs & Services** > **Credentials**.
  - Select / create your OAuth 2.0 Client ID (Web Application).
  - Add Authorized JavaScript Origins:
    - `https://eventdock.swynx.dev`
  - Add Authorized Redirect URIs:
    - `https://eventdock.swynx.dev`
- [ ] **Firebase Authentication Setup**:
  - In Firebase Console > Authentication > Settings > **Authorized Domains**, add:
    - `eventdock.swynx.dev`
    - `api.eventdock.swynx.dev`
- [ ] **Update Frontend Client ID**:
  - Add your production Google Client ID to `eventdock-dashboard/lib/services/auth_service.dart` or `index.html`.

---

## Phase 5: DNS Records Configuration (`swynx.dev`)

Configure your DNS records (Cloudflare, Namecheap, etc.) for domain routing:

| Record Type | Host / Name | Target / Value | Purpose |
| :--- | :--- | :--- | :--- |
| **CNAME** | `eventdock` | `<your-cloudflare-pages-or-vercel-url>` | Flutter Web Dashboard (`eventdock.swynx.dev`) |
| **CNAME** / **A** | `api.eventdock` | `<your-backend-host-or-vps-ip>` | Central REST API (`api.eventdock.swynx.dev`) |

- [ ] Verify SSL certificates issue successfully via Let's Encrypt / Cloudflare SSL.

---

## Phase 6: Setup GitHub Actions CI/CD Pipeline

Automate tests, Docker builds, and releases on GitHub.

- [ ] **Create `.github/workflows/ci.yml`**:
  - Run `mvn test` across all Java modules.
  - Run `flutter test` for the dashboard.
- [ ] **Create `.github/workflows/deploy.yml`** (Optional):
  - On push to `main` or tag creation `v*`:
    - Automatically build & push Docker image to GitHub Container Registry (GHCR).
    - Deploy dashboard to Cloudflare Pages / Vercel.

---

## Phase 7: Post-Launch Enhancements & Polish

Nice-to-have features for future iterations after launch:

- [ ] **API Key Rotation Endpoint**:
  - Add dedicated `POST /api/v1/projects/{projectId}/keys/{keyId}/rotate` to rotate in one click.
- [ ] **Slack / Discord Alert Webhooks**:
  - Allow projects to configure webhook URLs to receive notifications when 5xx errors occur.
- [ ] **Team Collaboration**:
  - Support inviting team members to projects with Role-Based Access Control (`ADMIN`, `DEVELOPER`, `VIEWER`).
- [ ] **Standalone CLI Binary Releases**:
  - Use GraalVM Native Image to build standalone native executables (`eventdock.exe` and `eventdock` for Linux/macOS) and upload to GitHub Releases.

---

## Quick Reference Commands

| Task | Command |
| :--- | :--- |
| **Deploy to Maven Central** | `mvn clean deploy -P release -DskipTests` |
| **Build Web Dashboard** | `cd eventdock-dashboard && flutter build web --release` |
| **Package Docker API** | `docker build -t eventdock-api:latest -f eventdock-api/Dockerfile .` |
| **Build Fat CLI JAR** | `mvn clean package -pl eventdock-cli -DskipTests` |
| **Run Everything Locally** | `.\run-all.ps1` |
| **Stop Everything Locally** | `.\stop-all.ps1` |
