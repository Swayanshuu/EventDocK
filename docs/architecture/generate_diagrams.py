"""
EventDock Architecture Diagram Generator (Refined & Perfected Layout)
Renders high-resolution (300 DPI) publication-grade architecture, sequence,
and entity-relationship diagrams for inclusion in the architecture handbook.
All box heights, coordinate offsets, and text labels are mathematically tuned
to prevent text overlapping, border clipping, and crossing lines.
"""

import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Output directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(BASE_DIR, "diagrams")
os.makedirs(OUT_DIR, exist_ok=True)

# EventDock Brand Palette
C_BG          = '#FFFFFF'
C_PANEL_BG    = '#F9FAFB'
C_DARK        = '#171717'
C_CORAL       = '#FF7043'
C_BORDER      = '#D1D5DB'
C_TEXT        = '#111827'
C_MUTED       = '#4B5563'
C_ACCENT_BLUE = '#2563EB'
C_ACCENT_PURP = '#7C3AED'
C_ACCENT_GREN = '#059669'
C_ACCENT_AMBR = '#D97706'
C_ACCENT_RED  = '#DC2626'

def setup_canvas(width=10, height=5.8, title=""):
    fig, ax = plt.subplots(figsize=(width, height), dpi=300)
    fig.patch.set_facecolor(C_BG)
    ax.set_facecolor(C_BG)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis('off')
    if title:
        ax.text(5.0, 5.65, title, ha='center', va='center', fontsize=13, fontweight='bold', color=C_DARK)
    return fig, ax

def draw_card(ax, x, y, w, h, title, subtitle="", items=None, border_color=C_CORAL, bg_color='#FFFFFF', title_color=C_DARK):
    rect = patches.FancyBboxPatch(
        (x, y), w, h,
        boxstyle="round,pad=0.08,rounding_size=0.15",
        facecolor=bg_color,
        edgecolor=border_color,
        linewidth=1.5,
        zorder=2
    )
    ax.add_patch(rect)
    
    # Title positioning
    if subtitle:
        ax.text(x + w/2, y + h - 0.28, title, ha='center', va='center', fontsize=9.5, fontweight='bold', color=title_color, zorder=3)
        ax.text(x + w/2, y + h - 0.52, subtitle, ha='center', va='center', fontsize=7.5, fontstyle='italic', color=C_MUTED, zorder=3)
        start_y = y + h - 0.78
    else:
        ax.text(x + w/2, y + h - 0.32, title, ha='center', va='center', fontsize=9.5, fontweight='bold', color=title_color, zorder=3)
        start_y = y + h - 0.60
        
    if items:
        line_spacing = 0.24 if len(items) <= 5 else 0.20
        curr_y = start_y
        for item in items:
            ax.text(x + 0.15, curr_y, item, ha='left', va='center', fontsize=7.2, color=C_TEXT, zorder=3)
            curr_y -= line_spacing

def draw_arrow(ax, x1, y1, x2, y2, label="", color=C_CORAL, lw=1.5, style='->', label_offset=(0, 0.15), label_color=C_TEXT, label_fs=7):
    ax.annotate(
        '', xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(arrowstyle=style, color=color, lw=lw, shrinkA=4, shrinkB=4),
        zorder=4
    )
    if label:
        mx = (x1 + x2) / 2 + label_offset[0]
        my = (y1 + y2) / 2 + label_offset[1]
        ax.text(mx, my, label, ha='center', va='center', fontsize=label_fs, fontweight='bold', color=label_color,
                bbox=dict(boxstyle='square,pad=0.12', facecolor=C_BG, edgecolor='none', alpha=0.9), zorder=5)

# -----------------------------------------------------------------------------
# DIAGRAM 1: High-Level System Architecture
# -----------------------------------------------------------------------------
def gen_diagram_1():
    fig, ax = setup_canvas(10, 6.0, "EventDock High-Level System Architecture")
    ax.text(5.0, 5.38, "End-to-end telemetry flow from host Spring Boot microservices to developer triage",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    # 1. Host Spring Boot App
    draw_card(ax, 0.4, 2.7, 2.8, 2.4, "Host Spring Boot App", "Client JVM Microservice", [
        "* Spring Boot 3.3.4 Microservice",
        "* EventDockRequestFilter (Caching)",
        "* EventDockExceptionObserver",
        "* SensitiveDataRedactor (PII Scrub)",
        "* AsyncEventQueue (Ring Buffer)",
        "* HttpEventDockReporter (Batch)"
    ], border_color=C_CORAL, bg_color='#FFF7ED')

    # 2. EventDock API Gateway
    draw_card(ax, 3.6, 2.7, 2.8, 2.4, "EventDock API Core", "Ingestion & Security Gateway", [
        "* ApiKeyAuthenticationFilter",
        "* FirebaseAuthFilter & Verifier",
        "* EventController & Service",
        "* ReplayController & Service",
        "* SSRF Guard & DNS Validator",
        "* Audit & Metrics Logging"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    # 3. PostgreSQL & Supabase
    draw_card(ax, 6.8, 2.7, 2.8, 2.4, "Database Layer", "PostgreSQL 16 / Supabase", [
        "* users (Firebase Synced)",
        "* projects & project_api_keys",
        "* events (Truncated 32KB)",
        "* replay_attempts (Audited)",
        "* audit_logs & waitlist_signups",
        "* Flyway Automated Schema"
    ], border_color=C_ACCENT_BLUE, bg_color='#EFF6FF')

    # 4. Flutter Dashboard
    draw_card(ax, 0.4, 0.4, 2.8, 1.8, "Flutter Web Dashboard", "Console: eventdock.swynx.dev", [
        "* Real-time Telemetry Triage",
        "* Formatted Stack Trace Viewer",
        "* Single-Click Replay Trigger",
        "* API Key Provisioning (Single-Reveal)"
    ], border_color=C_ACCENT_PURP, bg_color='#FAF5FF')

    # 5. CLI Tool
    draw_card(ax, 3.6, 0.4, 2.8, 1.8, "EventDock CLI", "Picocli Standalone Terminal", [
        "* Browser OAuth on port 8976",
        "* Cached ~/.eventdock/credentials",
        "* Local Defect Inspection",
        "* Remote Replay Invocation"
    ], border_color=C_DARK, bg_color='#F9FAFB')

    # 6. Replay Target
    draw_card(ax, 6.8, 0.4, 2.8, 1.8, "Replay Target", "Localhost / Staging Service", [
        "* DNS Pinning & RFC-1918 Block",
        "* Redirect Suppression (NEVER)",
        "* State-changing Confirmation",
        "* Captures Real Status & Latency"
    ], border_color=C_ACCENT_RED, bg_color='#FEF2F2')

    # Connectors
    draw_arrow(ax, 3.2, 3.9, 3.6, 3.9, "Async Batch HTTP\n(X-EventDock-Api-Key)", color=C_CORAL, label_offset=(0, 0.22))
    draw_arrow(ax, 6.4, 3.9, 6.8, 3.9, "JPA / Flyway\nSQL / RLS", color=C_ACCENT_BLUE, label_offset=(0, 0.22))
    draw_arrow(ax, 1.8, 2.2, 4.4, 2.7, "Bearer JWT REST", color=C_ACCENT_PURP, label_offset=(-0.6, -0.15))
    draw_arrow(ax, 5.0, 2.2, 5.0, 2.7, "REST Client", color=C_DARK, label_offset=(0.35, -0.1))
    draw_arrow(ax, 5.0, 2.7, 7.8, 2.2, "Safe Replay HTTP", color=C_ACCENT_RED, label_offset=(0.65, 0.15))

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_1_system_architecture.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 2: Module Dependencies
# -----------------------------------------------------------------------------
def gen_diagram_2():
    fig, ax = setup_canvas(10, 5.6, "EventDock Monorepo Module Dependency Hierarchy")
    ax.text(5.0, 5.25, "Maven multi-module hierarchy and runtime integration boundaries",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    # Root POM
    draw_card(ax, 3.6, 4.2, 2.8, 0.9, "eventdock (Root POM)", "Parent POM / Dependency Management", [
        "Java 21 LTS | Spring Boot 3.3.4"
    ], border_color=C_DARK, bg_color='#F3F4F6')

    # Core SDK & API
    draw_card(ax, 0.6, 2.6, 2.6, 1.2, "eventdock-starter", "Spring Boot Starter SDK", [
        "Auto-configuration, Filters,",
        "Redactors, Async Queue"
    ], border_color=C_CORAL, bg_color='#FFF7ED')

    draw_card(ax, 3.7, 2.6, 2.6, 1.2, "eventdock-api", "Ingestion Gateway Backend", [
        "REST API, Security, JPA,",
        "Replay Engine, Flyway, Resend"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    draw_card(ax, 6.8, 2.6, 2.6, 1.2, "eventdock-cli", "Standalone Terminal CLI", [
        "Picocli Java 21, OAuth2",
        "Ephemeral Server (port 8976)"
    ], border_color=C_ACCENT_AMBR, bg_color='#FEF3C7')

    # Sample & Dashboard
    draw_card(ax, 0.6, 0.7, 2.6, 1.2, "eventdock-sample", "LinkPeer Microservice", [
        "Simulates 502, 504, 400,",
        "Tests starter instrumentation"
    ], border_color=C_ACCENT_BLUE, bg_color='#EFF6FF')

    draw_card(ax, 3.7, 0.7, 2.6, 1.2, "eventdock-dashboard", "Flutter Web Frontend", [
        "Firebase Auth, Telemetry UI,",
        "Replay Console, Waitlist"
    ], border_color=C_ACCENT_PURP, bg_color='#FAF5FF')

    # Arrows from Root POM down
    draw_arrow(ax, 4.0, 4.2, 2.0, 3.8, "", color=C_DARK)
    draw_arrow(ax, 5.0, 4.2, 5.0, 3.8, "", color=C_DARK)
    draw_arrow(ax, 6.0, 4.2, 8.0, 3.8, "", color=C_DARK)

    # Starter consumed by Sample
    draw_arrow(ax, 1.9, 2.6, 1.9, 1.9, "Maven Dependency", color=C_CORAL, label_offset=(0.6, 0))

    # API consumed by Dashboard and CLI
    draw_arrow(ax, 5.0, 2.6, 5.0, 1.9, "REST API (HTTP)", color=C_ACCENT_GREN, label_offset=(0.55, 0))
    draw_arrow(ax, 8.1, 2.6, 6.3, 3.0, "REST Client", color=C_ACCENT_AMBR, label_offset=(-0.5, 0.15))

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_2_module_dependencies.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 3: Flow A Sequence - Onboarding & Auth
# -----------------------------------------------------------------------------
def gen_diagram_3():
    fig, ax = setup_canvas(10, 5.6, "Flow A: Developer Onboarding & Identity Sync Sequence")
    
    # Lifelines
    actors = [
        ("Developer", 1.2, C_DARK),
        ("Dashboard (Flutter)", 3.4, C_ACCENT_PURP),
        ("Firebase Auth", 5.6, C_ACCENT_AMBR),
        ("FirebaseAuthFilter", 7.6, C_CORAL),
        ("PostgreSQL (users)", 9.2, C_ACCENT_BLUE)
    ]
    for name, x, col in actors:
        ax.text(x, 5.1, name, ha='center', va='center', fontsize=8.5, fontweight='bold', color=col,
                bbox=dict(boxstyle='round,pad=0.2', facecolor='#F3F4F6', edgecolor=col))
        ax.plot([x, x], [0.5, 4.8], color='#D1D5DB', linestyle='--', lw=1, zorder=1)

    steps = [
        (4.4, 1.2, 3.4, "1. Enters email/password or Google OAuth", C_DARK),
        (3.9, 3.4, 5.6, "2. Authenticate credentials", C_ACCENT_PURP),
        (3.4, 5.6, 3.4, "3. Return Firebase ID Token (JWT)", C_ACCENT_AMBR),
        (2.9, 3.4, 7.6, "4. GET /api/v1/projects (Authorization: Bearer <jwt>)", C_ACCENT_PURP),
        (2.4, 7.6, 7.6, "5. FirebaseAuthVerifier validates signature", C_CORAL),
        (1.9, 7.6, 9.2, "6. findByFirebaseUid() / INSERT INTO users", C_CORAL),
        (1.4, 9.2, 7.6, "7. User entity resolved (UUID established)", C_ACCENT_BLUE),
        (0.9, 7.6, 3.4, "8. 200 OK + Project List (Authenticated User ID)", C_ACCENT_GREN)
    ]
    for y, x1, x2, lbl, col in steps:
        if x1 == x2:
            rect = patches.Rectangle((x1, y-0.12), 1.6, 0.24, facecolor='#FEF3C7', edgecolor=C_CORAL, lw=1)
            ax.add_patch(rect)
            ax.text(x1 + 0.8, y, lbl, ha='center', va='center', fontsize=6.8, fontweight='bold', color=C_DARK)
        else:
            draw_arrow(ax, x1, y, x2, y, lbl, color=col, lw=1.2, label_offset=(0, 0.12), label_fs=6.8)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_3_onboarding_auth.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 4: Flow C - API Key Lifecycle
# -----------------------------------------------------------------------------
def gen_diagram_4():
    fig, ax = setup_canvas(10, 5.8, "Flow C: Cryptographic Project API Key Lifecycle")
    
    actors = [
        ("Developer UI", 1.2, C_DARK),
        ("ProjectController", 3.4, C_CORAL),
        ("ApiKeyService", 5.8, C_ACCENT_PURP),
        ("PostgreSQL DB", 8.8, C_ACCENT_BLUE)
    ]
    for name, x, col in actors:
        ax.text(x, 5.2, name, ha='center', va='center', fontsize=8.5, fontweight='bold', color=col,
                bbox=dict(boxstyle='round,pad=0.2', facecolor='#F3F4F6', edgecolor=col))
        ax.plot([x, x], [0.5, 4.9], color='#D1D5DB', linestyle='--', lw=1, zorder=1)

    steps = [
        (4.5, 1.2, 3.4, "POST /api/v1/projects/{id}/keys {label}", C_DARK),
        (4.0, 3.4, 5.8, "generateApiKey(userId, projId, label)", C_CORAL),
        # Cryptographic box (spaced cleanly)
        (3.3, 5.8, 5.8, "CRYPTO_BOX", C_ACCENT_PURP),
        (2.6, 5.8, 8.8, "INSERT INTO project_api_keys (key_prefix, key_hash, label...)", C_ACCENT_PURP),
        (2.0, 8.8, 5.8, "Record Persisted (id UUID, is_active=true)", C_ACCENT_BLUE),
        (1.4, 5.8, 3.4, "Return ApiKeyCreatedResponse (rawKey + prefix)", C_ACCENT_PURP),
        (0.8, 3.4, 1.2, "201 Created (Raw key shown ONCE to developer)", C_CORAL)
    ]
    for y, x1, x2, lbl, col in steps:
        if lbl == "CRYPTO_BOX":
            rect = patches.FancyBboxPatch(
                (4.4, 3.0), 2.8, 0.65,
                boxstyle="round,pad=0.05",
                facecolor='#FAF5FF',
                edgecolor=C_ACCENT_PURP,
                linewidth=1.2
            )
            ax.add_patch(rect)
            ax.text(5.8, 3.42, "1. SecureRandom.nextBytes(24) -> ed_live_...", ha='center', va='center', fontsize=6.8, fontweight='bold', color=C_ACCENT_PURP)
            ax.text(5.8, 3.18, "2. SHA-256(rawKey) -> key_hash | prefix=chars[0..16]", ha='center', va='center', fontsize=6.5, color=C_DARK)
        else:
            draw_arrow(ax, x1, y, x2, y, lbl, color=col, lw=1.2, label_offset=(0, 0.12), label_fs=6.8)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_4_api_key_lifecycle.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 5: Flow E - Failure Capture Lifecycle
# -----------------------------------------------------------------------------
def gen_diagram_5():
    fig, ax = setup_canvas(10, 5.8, "Flow E: Non-Blocking Telemetry Capture Sequence")
    
    actors = [
        ("Client Request", 0.9, C_DARK),
        ("RequestFilter (Wrapper)", 2.7, C_CORAL),
        ("Business Service", 4.7, C_ACCENT_RED),
        ("ExceptionObserver", 6.8, C_ACCENT_AMBR),
        ("AsyncEventQueue", 8.8, C_ACCENT_GREN)
    ]
    for name, x, col in actors:
        ax.text(x, 5.2, name, ha='center', va='center', fontsize=8, fontweight='bold', color=col,
                bbox=dict(boxstyle='round,pad=0.18', facecolor='#F3F4F6', edgecolor=col))
        ax.plot([x, x], [0.5, 4.9], color='#D1D5DB', linestyle='--', lw=1, zorder=1)

    steps = [
        (4.5, 0.9, 2.7, "1. POST /api/payments/checkout", C_DARK),
        (4.1, 2.7, 4.7, "2. ContentCachingRequestWrapper(req)", C_CORAL),
        (3.6, 4.7, 4.7, "ERROR_BOX", C_ACCENT_RED),
        (3.0, 4.7, 6.8, "4. Intercepts Exception + extracts cached payload", C_ACCENT_RED),
        (2.4, 6.8, 6.8, "REDACT_BOX", C_ACCENT_AMBR),
        (1.8, 6.8, 8.8, "6. queue.offer(event) [NON-BLOCKING]", C_ACCENT_GREN),
        (1.2, 4.7, 0.9, "7. HTTP 504 Returned to Client (Unblocked)", C_ACCENT_RED),
        (0.7, 8.8, 8.8, "8. Background Daemon flushes batch to API Gateway", C_ACCENT_GREN)
    ]
    for y, x1, x2, lbl, col in steps:
        if lbl == "ERROR_BOX":
            rect = patches.Rectangle((4.0, 3.4), 1.5, 0.28, facecolor='#FEE2E2', edgecolor=C_ACCENT_RED, lw=1)
            ax.add_patch(rect)
            ax.text(4.75, 3.54, "3. Upstream Timeout (504)", ha='center', va='center', fontsize=6.8, fontweight='bold', color=C_ACCENT_RED)
        elif lbl == "REDACT_BOX":
            rect = patches.Rectangle((5.8, 2.22), 2.0, 0.30, facecolor='#FEF3C7', edgecolor=C_ACCENT_AMBR, lw=1)
            ax.add_patch(rect)
            ax.text(6.8, 2.37, "5. SensitiveDataRedactor (PII Scrub)", ha='center', va='center', fontsize=6.6, fontweight='bold', color=C_ACCENT_AMBR)
        elif x1 == x2:
            rect = patches.Rectangle((x1-0.8, y-0.12), 1.6, 0.24, facecolor='#DCFCE7', edgecolor=C_ACCENT_GREN, lw=1)
            ax.add_patch(rect)
            ax.text(x1, y, lbl, ha='center', va='center', fontsize=6.5, fontweight='bold', color=C_ACCENT_GREN)
        else:
            draw_arrow(ax, x1, y, x2, y, lbl, color=col, lw=1.2, label_offset=(0, 0.12), label_fs=6.8)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_5_failure_capture.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 6: Flow F - Telemetry Sanitization & Ingestion Pipeline
# -----------------------------------------------------------------------------
def gen_diagram_6():
    fig, ax = setup_canvas(10, 5.6, "Flow F: Telemetry Sanitization & Ingestion Pipeline")
    ax.text(5.0, 5.25, "Client-side privacy scrubbing and backend authentication pipeline",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    # 4 stages spaced evenly
    draw_card(ax, 0.4, 1.2, 2.0, 3.6, "1. Raw Defect", "Host Application", [
        "* Captured Exception",
        "* HTTP Request Headers",
        "* Request Body Stream",
        "* Response Status Code",
        "* Microservice Metadata"
    ], border_color=C_ACCENT_RED, bg_color='#FEF2F2')

    draw_card(ax, 2.7, 1.2, 2.1, 3.6, "2. Client Redaction", "eventdock-starter", [
        "* HeaderRedactor:",
        "  - Authorization",
        "  - Cookie / Set-Cookie",
        "  - X-Api-Key",
        "* BodyRedactor:",
        "  - Passwords & Tokens",
        "  - Credit Card Regex",
        "* Truncation (32KB)"
    ], border_color=C_CORAL, bg_color='#FFF7ED')

    draw_card(ax, 5.1, 1.2, 2.1, 3.6, "3. Async Queue", "Ring Buffer", [
        "* Capacity: 500 items",
        "* Non-blocking offer()",
        "* Drop counter metric",
        "* Scheduled flusher",
        "* Batch size: 25 items",
        "* Interval: 1000ms"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    draw_card(ax, 7.5, 1.2, 2.1, 3.6, "4. Ingestion API", "eventdock-api", [
        "* POST /api/v1/events",
        "* ApiKeyAuthFilter",
        "* SHA-256 Hash Lookup",
        "* Resolves Project ID",
        "* Schema Validation",
        "* Inserts into events table"
    ], border_color=C_ACCENT_BLUE, bg_color='#EFF6FF')

    # Top-level transition arrows
    draw_arrow(ax, 2.4, 3.0, 2.7, 3.0, "", color=C_CORAL, lw=2.0)
    draw_arrow(ax, 4.8, 3.0, 5.1, 3.0, "", color=C_ACCENT_GREN, lw=2.0)
    draw_arrow(ax, 7.2, 3.0, 7.5, 3.0, "X-EventDock-Api-Key", color=C_ACCENT_BLUE, lw=2.0, label_offset=(0, 0.20), label_fs=6.5)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_6_sanitization_ingestion.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 7: Flow H - SSRF-Safe Replay Engine
# -----------------------------------------------------------------------------
def gen_diagram_7():
    fig, ax = setup_canvas(10, 5.8, "Flow H: SSRF-Safe Replay Engine Sequence")
    
    actors = [
        ("Developer", 1.0, C_DARK),
        ("ReplayController", 2.8, C_ACCENT_PURP),
        ("SSRF Validator", 5.0, C_ACCENT_RED),
        ("HttpClient (No Redirect)", 7.2, C_ACCENT_GREN),
        ("Target Service", 9.0, C_ACCENT_BLUE)
    ]
    for name, x, col in actors:
        ax.text(x, 5.2, name, ha='center', va='center', fontsize=8, fontweight='bold', color=col,
                bbox=dict(boxstyle='round,pad=0.18', facecolor='#F3F4F6', edgecolor=col))
        ax.plot([x, x], [0.5, 4.9], color='#D1D5DB', linestyle='--', lw=1, zorder=1)

    steps = [
        (4.5, 1.0, 2.8, "1. POST /api/v1/events/{id}/replay {targetUrl}", C_DARK),
        (4.0, 2.8, 5.0, "2. validateTarget(targetUrl)", C_ACCENT_PURP),
        (3.4, 5.0, 5.0, "SSRF_CHECK", C_ACCENT_RED),
        (2.7, 5.0, 2.8, "4. Target Verified Safe (Public IP / Whitelisted)", C_ACCENT_GREN),
        (2.1, 2.8, 7.2, "5. Dispatch Request (Strip Auth/Cookies)", C_ACCENT_PURP),
        (1.5, 7.2, 9.0, "6. Forward Replayed HTTP Request", C_ACCENT_GREN),
        (1.0, 9.0, 7.2, "7. Upstream HTTP Response (Status, Body, Latency)", C_ACCENT_BLUE),
        (0.6, 7.2, 2.8, "8. Persist into replay_attempts table", C_ACCENT_PURP)
    ]
    for y, x1, x2, lbl, col in steps:
        if lbl == "SSRF_CHECK":
            rect = patches.FancyBboxPatch(
                (3.8, 3.15), 2.4, 0.55,
                boxstyle="round,pad=0.05",
                facecolor='#FEE2E2',
                edgecolor=C_ACCENT_RED,
                linewidth=1.2
            )
            ax.add_patch(rect)
            ax.text(5.0, 3.48, "3. DNS Resolution check", ha='center', va='center', fontsize=6.8, fontweight='bold', color=C_ACCENT_RED)
            ax.text(5.0, 3.28, "Blocks Loopback & RFC-1918 Private IPs", ha='center', va='center', fontsize=6.2, color=C_DARK)
        else:
            draw_arrow(ax, x1, y, x2, y, lbl, color=col, lw=1.2, label_offset=(0, 0.12), label_fs=6.8)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_7_ssrf_replay.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 8: Database ER Diagram
# -----------------------------------------------------------------------------
def gen_diagram_8():
    fig, ax = setup_canvas(10, 6.2, "EventDock PostgreSQL Relational Schema (ER Diagram)")
    ax.text(5.0, 5.85, "Physical tables, UUID primary keys, foreign key constraints, and 1:N topology",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    # Row 1: Users, Projects, Project API Keys
    draw_card(ax, 0.4, 3.5, 2.6, 2.1, "USERS", "Table: users", [
        "id: UUID [PK]",
        "firebase_uid: VARCHAR(128) [UQ]",
        "email: VARCHAR(255) [IDX]",
        "display_name: VARCHAR(255)",
        "created_at: TIMESTAMPTZ",
        "updated_at: TIMESTAMPTZ"
    ], border_color=C_ACCENT_BLUE, bg_color='#EFF6FF')

    draw_card(ax, 3.7, 3.5, 2.6, 2.1, "PROJECTS", "Table: projects", [
        "id: UUID [PK]",
        "owner_id: UUID [FK -> users]",
        "name: VARCHAR(100)",
        "slug: VARCHAR(100) [UQ]",
        "description: TEXT",
        "created_at: TIMESTAMPTZ"
    ], border_color=C_CORAL, bg_color='#FFF7ED')

    draw_card(ax, 7.0, 3.5, 2.6, 2.1, "PROJECT_API_KEYS", "Table: project_api_keys", [
        "id: UUID [PK]",
        "project_id: UUID [FK -> projects]",
        "key_prefix: VARCHAR(16) [IDX]",
        "key_hash: VARCHAR(64) [UQ]",
        "label: VARCHAR(100)",
        "is_active: BOOLEAN"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    # Row 2: Audit Logs, Events, Replay Attempts
    draw_card(ax, 0.4, 0.5, 2.6, 2.5, "AUDIT_LOGS", "Table: audit_logs", [
        "id: UUID [PK]",
        "user_id: UUID [FK -> users]",
        "action: VARCHAR(64)",
        "entity_type: VARCHAR(64)",
        "entity_id: VARCHAR(64)",
        "details: JSONB",
        "ip_address: VARCHAR(45)",
        "created_at: TIMESTAMPTZ"
    ], border_color=C_DARK, bg_color='#F9FAFB')

    draw_card(ax, 3.7, 0.5, 2.6, 2.5, "EVENTS", "Table: events", [
        "id: UUID [PK]",
        "project_id: UUID [FK -> projects]",
        "tracking_id: VARCHAR(64) [UQ]",
        "exception_class: VARCHAR(255)",
        "message: TEXT",
        "stack_trace: TEXT (32KB)",
        "http_method: VARCHAR(16)",
        "request_uri: VARCHAR(1024)",
        "headers: JSONB | body: TEXT"
    ], border_color=C_ACCENT_RED, bg_color='#FEF2F2')

    draw_card(ax, 7.0, 0.5, 2.6, 2.5, "REPLAY_ATTEMPTS", "Table: replay_attempts", [
        "id: UUID [PK]",
        "event_id: UUID [FK -> events]",
        "target_url: VARCHAR(1024)",
        "executed_by: UUID [FK -> users]",
        "response_status: INT",
        "response_body: TEXT",
        "latency_ms: BIGINT",
        "status: VARCHAR(32)"
    ], border_color=C_ACCENT_PURP, bg_color='#FAF5FF')

    # Relational connectors
    draw_arrow(ax, 3.0, 4.5, 3.7, 4.5, "1 : N (CASCADE)", color=C_CORAL, label_offset=(0, 0.15), label_fs=6.5)
    draw_arrow(ax, 6.3, 4.5, 7.0, 4.5, "1 : N (CASCADE)", color=C_ACCENT_GREN, label_offset=(0, 0.15), label_fs=6.5)
    draw_arrow(ax, 5.0, 3.5, 5.0, 3.0, "1 : N (CASCADE)", color=C_ACCENT_RED, label_offset=(0.6, 0), label_fs=6.5)
    draw_arrow(ax, 6.3, 1.7, 7.0, 1.7, "1 : N (CASCADE)", color=C_ACCENT_PURP, label_offset=(0, 0.15), label_fs=6.5)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_8_database_er.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 9: Security Boundaries
# -----------------------------------------------------------------------------
def gen_diagram_9():
    fig, ax = setup_canvas(10, 5.6, "EventDock Security Boundaries & Threat Defense Model")
    ax.text(5.0, 5.25, "Layered security architecture across ingress, secret management, and replay execution",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    draw_card(ax, 0.4, 1.0, 2.8, 3.9, "1. Ingress Auth Firewall", "Boundary: Edge Network", [
        "* ApiKeyAuthenticationFilter:",
        "  - SHA-256 hash lookup",
        "  - Requires active project key",
        "  - Disregards client project ID",
        "* FirebaseAuthFilter:",
        "  - Firebase Bearer JWT",
        "  - Verifies Google token signature",
        "  - Enforces ROLE_DEVELOPER"
    ], border_color=C_ACCENT_AMBR, bg_color='#FFFBEB')

    draw_card(ax, 3.6, 1.0, 2.8, 3.9, "2. Tenant & Data Defense", "Boundary: Business Logic", [
        "* Multi-Tenant Isolation:",
        "  - ProjectService.verifyOwnership()",
        "  - Rejects cross-tenant access (403)",
        "* Secret & PII Scrubbing:",
        "  - Authorization, Cookie redactor",
        "  - Regex masking (Cards, Passwords)",
        "* Single-Reveal Key Storage:",
        "  - Raw key NEVER stored in DB"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    draw_card(ax, 6.8, 1.0, 2.8, 3.9, "3. SSRF Replay Firewall", "Boundary: Outbound Network", [
        "* Protocol Whitelist (HTTP/S only)",
        "* DNS Pinning & Resolution",
        "* RFC-1918 Private Subnet Block:",
        "  - 10.0.0.0/8, 172.16.0.0/12",
        "  - 192.168.0.0/16, 127.0.0.1",
        "* Redirect Suppression (NEVER)",
        "* State-changing Confirmation"
    ], border_color=C_ACCENT_RED, bg_color='#FEF2F2')

    draw_arrow(ax, 3.2, 3.0, 3.6, 3.0, "Verified Identity", color=C_ACCENT_GREN, label_offset=(0, 0.15), label_fs=6.5)
    draw_arrow(ax, 6.4, 3.0, 6.8, 3.0, "Isolated Telemetry", color=C_ACCENT_RED, label_offset=(0, 0.15), label_fs=6.5)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_9_security_boundaries.png"), dpi=300)
    plt.close()

# -----------------------------------------------------------------------------
# DIAGRAM 10: Deployment Topology
# -----------------------------------------------------------------------------
def gen_diagram_10():
    fig, ax = setup_canvas(10, 5.6, "EventDock Production Deployment Topology")
    ax.text(5.0, 5.25, "Containerized microservice architecture and managed external integrations",
            ha='center', va='center', fontsize=8, fontstyle='italic', color=C_MUTED)

    draw_card(ax, 0.4, 2.8, 2.6, 2.1, "Edge Reverse Proxy", "Nginx / Cloudflare", [
        "* SSL Termination (HTTPS:443)",
        "* CORS Policy & Host Whitelist",
        "* Static Flutter Asset CDN",
        "* Rate Limiting & DDoS Shield"
    ], border_color=C_DARK, bg_color='#F3F4F6')

    draw_card(ax, 3.7, 2.8, 2.6, 2.1, "EventDock API (Spring)", "Docker: eventdock-api:latest", [
        "* Java 21 LTS Container",
        "* Port 8080 (REST / Actuator)",
        "* Flyway Automated Migrations",
        "* Replay Engine & SSRF Guard"
    ], border_color=C_CORAL, bg_color='#FFF7ED')

    draw_card(ax, 7.0, 2.8, 2.6, 2.1, "PostgreSQL 16 Engine", "Docker / Managed Cloud SQL", [
        "* Port 5432 (eventdock DB)",
        "* ACID Compliance & UUID PKs",
        "* Multi-Tenant Foreign Keys",
        "* Indexed Query Execution"
    ], border_color=C_ACCENT_BLUE, bg_color='#EFF6FF')

    draw_card(ax, 0.4, 0.5, 2.6, 1.8, "Client Microservices", "Spring Boot Apps", [
        "* Integrated eventdock-starter",
        "* Non-blocking Async Queue",
        "* Outbound Telemetry Dispatch"
    ], border_color=C_ACCENT_PURP, bg_color='#FAF5FF')

    draw_card(ax, 3.7, 0.5, 2.6, 1.8, "External Services", "SaaS & Cloud APIs", [
        "* Firebase Auth (Identity/JWT)",
        "* Resend API (Waitlist Emails)",
        "* Supabase (Subscriber Sync)"
    ], border_color=C_ACCENT_AMBR, bg_color='#FEF3C7')

    draw_card(ax, 7.0, 0.5, 2.6, 1.8, "Developer Interfaces", "Web & Terminal Tools", [
        "* Flutter Web Console",
        "* Picocli Terminal CLI",
        "* Local Loopback Callback (8976)"
    ], border_color=C_ACCENT_GREN, bg_color='#F0FDF4')

    draw_arrow(ax, 3.0, 3.8, 3.7, 3.8, "Proxy Pass :8080", color=C_DARK, label_offset=(0, 0.15), label_fs=6.5)
    draw_arrow(ax, 6.3, 3.8, 7.0, 3.8, "JDBC :5432", color=C_ACCENT_BLUE, label_offset=(0, 0.15), label_fs=6.5)
    draw_arrow(ax, 1.7, 2.3, 3.7, 3.2, "POST /api/v1/events", color=C_CORAL, label_offset=(-0.4, 0.15), label_fs=6.5)
    draw_arrow(ax, 5.0, 2.8, 5.0, 2.3, "OAuth / Mail / Edge", color=C_ACCENT_AMBR, label_offset=(0.6, 0), label_fs=6.5)
    draw_arrow(ax, 7.0, 1.4, 1.7, 2.8, "Management Console", color=C_ACCENT_GREN, label_offset=(0.8, -0.2), label_fs=6.5)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "diagram_10_deployment_topology.png"), dpi=300)
    plt.close()

def main():
    print("Generating refined, high-resolution diagrams...")
    gen_diagram_1()
    gen_diagram_2()
    gen_diagram_3()
    gen_diagram_4()
    gen_diagram_5()
    gen_diagram_6()
    gen_diagram_7()
    gen_diagram_8()
    gen_diagram_9()
    gen_diagram_10()
    print("All 10 refined architecture diagrams generated successfully!")

if __name__ == '__main__':
    main()
