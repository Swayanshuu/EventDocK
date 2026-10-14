<p align="center">
  <a href="https://eventdock.swynx.dev">
    <img src="../assets/EventDocK-removebg-preview.png" alt="EventDock Logo" width="300" />
  </a>
</p>

# EventDock Dashboard ⚓

> **High-performance developer web platform for inspecting diagnostic API failure events, triaging stack traces, and triggering request replays.**

Built with **Flutter Web 3.x** and styled with an adaptive dark-mode glassmorphism developer design system.

---

## ⚡ Highlights

- **Live Landing & Waitlist**: Framer-style glassmorphism waitlist page with animated glowing aurora backdrop, inline pill input bar, animated spinning completion wheel with checkmark transitions, and instant email dispatch via Resend.
- **Google Sign-In**: Authentication integrated with EventDock backend and Firebase.
- **Responsive Layout**: Pixel-perfect responsive rendering for mobile (<640px), tablet (640–1024px), and desktop viewports (>1024px).
- **Project & Key Management**: Create projects, view telemetry, and generate/revoke project ingestion API keys (`ed_live_...`).
- **Event Inbox**: Real-time failure event monitoring with status code badges (5xx, 4xx), route templates, and search/filtering.
- **Stack Trace Inspection**: Clean formatted stack trace viewer with copy support and request metadata inspector.
- **SSRF-Safe Request Replay**: Interactive dialog to trigger request replays against local or staging target URLs.

---

## 🚀 Running Locally

```bash
# Install dependencies
flutter pub get

# Run locally in Chrome:
flutter run -d chrome

# Run automated test suite:
flutter test

# Build optimized production bundle:
flutter build web --release
```

Production builds will output to `build/web/`, ready to deploy to Vercel, Cloudflare Pages, Netlify, or Nginx.

---

## 🌐 Production Deployment

- **Custom Domain**: [https://eventdock.swynx.dev](https://eventdock.swynx.dev)
- **Vercel Project**: `eventdock-waitlist`
- **Mailing Integration**: Resend API (`/api/send` Node.js serverless proxy)

---

## 📄 License

Distributed under the [Apache 2.0 License](../LICENSE).
