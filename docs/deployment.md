# Production Deployment Guide

This guide covers production deployment architectures, container orchestration, environment variable configurations, database maintenance, and operational monitoring for **EventDock**.

---

## 1. Architecture Topology

A standard production deployment consists of:

```
                          Internet / Clients
                                  │
                                  ▼
                   ┌─────────────────────────────┐
                   │    TLS Reverse Proxy        │
                   │    (Nginx / Caddy / Envoy)  │
                   └──────────────┬──────────────┘
                                  │
            ┌─────────────────────┴─────────────────────┐
            │                                           │
            ▼                                           ▼
┌───────────────────────┐                   ┌───────────────────────┐
│  eventdock-dashboard  │                   │    eventdock-api      │
│  (Port 3000 / Nginx)  │                   │  (Port 8080 / Spring) │
└───────────────────────┘                   └───────────┬───────────┘
                                                        │
                                            ┌───────────┴───────────┐
                                            ▼                       ▼
                                  ┌──────────────────┐    ┌──────────────────┐
                                  │  PostgreSQL 16   │    │  Firebase Auth   │
                                  │  Primary Cluster │    │  Identity Admin  │
                                  └──────────────────┘    └──────────────────┘
```

---

## 2. Production Docker Compose

Create a `docker-compose.prod.yml` file:

```yaml
version: '3.8'

services:
  eventdock-db:
    image: postgres:16-alpine
    container_name: eventdock-db-prod
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-eventdock}
      POSTGRES_USER: ${POSTGRES_USER:-eventdock_app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Database password required}
    volumes:
      - eventdock_db_data:/var/lib/postgresql/data
    networks:
      - eventdock-internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 10s
      timeout: 5s
      retries: 5

  eventdock-api:
    image: ghcr.io/eventdock/eventdock-api:1.0.0
    container_name: eventdock-api-prod
    restart: unless-stopped
    depends_on:
      eventdock-db:
        condition: service_healthy
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SPRING_DATASOURCE_URL: jdbc:postgresql://eventdock-db:5432/${POSTGRES_DB:-eventdock}
      SPRING_DATASOURCE_USERNAME: ${POSTGRES_USER:-eventdock_app}
      SPRING_DATASOURCE_PASSWORD: ${POSTGRES_PASSWORD}
      FIREBASE_PROJECT_ID: ${FIREBASE_PROJECT_ID:?Firebase project ID required}
      FIREBASE_CREDENTIALS_PATH: /etc/eventdock/firebase-service-account.json
      JAVA_OPTS: "-XX:+UseG1GC -XX:MaxRAMPercentage=75.0"
    volumes:
      - ./secrets/firebase-service-account.json:/etc/eventdock/firebase-service-account.json:ro
    networks:
      - eventdock-internal
      - eventdock-public
    ports:
      - "8080:8080"

  eventdock-dashboard:
    image: ghcr.io/eventdock/eventdock-dashboard:1.0.0
    container_name: eventdock-dashboard-prod
    restart: unless-stopped
    networks:
      - eventdock-public
    ports:
      - "3000:80"

networks:
  eventdock-internal:
    internal: true
  eventdock-public:

volumes:
  eventdock_db_data:
```

---

## 3. Reverse Proxy Configuration (Nginx)

Route external traffic through Nginx with TLS termination:

```nginx
server {
    listen 443 ssl http2;
    server_name eventdock.swynx.dev;

    ssl_certificate /etc/letsencrypt/live/eventdock.swynx.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/eventdock.swynx.dev/privkey.pem;

    # Dashboard Web App
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Central REST API
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 10M;
    }

    # Actuator Health Check (Restricted to internal subnet)
    location /actuator/ {
        allow 10.0.0.0/8;
        deny all;
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 4. Database Maintenance & Backups

### Automated Scheduled Backups
Set up a daily cron task to create compressed PostgreSQL dumps:

```bash
0 2 * * * docker exec -t eventdock-db-prod pg_dump -U eventdock_app -d eventdock -Fc | gzip > /backups/eventdock_$(date +\%Y\%m\%d).dump.gz
```

### Event Pruning & Retention Maintenance
EventDock automatically tracks project-level data retention (`retention_days`). Run maintenance pruning via cron or Spring `@Scheduled` runner:

```sql
DELETE FROM events
WHERE created_at < NOW() - INTERVAL '30 days';
```

---

## 5. Monitoring & Health Checks

EventDock exposes standard Spring Boot Actuator endpoints:
- **Liveness probe:** `http://localhost:8080/actuator/health/liveness`
- **Readiness probe:** `http://localhost:8080/actuator/health/readiness`
- **Prometheus Metrics:** `http://localhost:8080/actuator/prometheus`

Key metrics to monitor:
- `eventdock.events.ingested.total`: Total diagnostic events recorded.
- `eventdock.replays.executed.total`: Total request replays executed.
- `jvm.memory.used`: Heap memory utilization.
- `hikaricp.connections.active`: Database connection pool saturation.
