-- V1__init_schema.sql
-- EventDock Database Schema Initialization (with Firebase Auth user mapping)

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'DEVELOPER',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    retention_days INT NOT NULL DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS project_api_keys (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    key_prefix VARCHAR(16) NOT NULL,
    key_hash VARCHAR(64) NOT NULL UNIQUE,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    request_id VARCHAR(100) NOT NULL,
    http_method VARCHAR(16) NOT NULL,
    route_template VARCHAR(255),
    request_uri VARCHAR(1024) NOT NULL,
    status_code INT NOT NULL,
    error_type VARCHAR(255),
    sanitized_error_message TEXT,
    stack_trace TEXT,
    duration_ms BIGINT,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    service_name VARCHAR(100),
    environment VARCHAR(50),
    metadata_json TEXT,
    request_body TEXT,
    response_body TEXT
);

CREATE TABLE IF NOT EXISTS replay_attempts (
    id UUID PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    initiated_by VARCHAR(100) NOT NULL,
    destination_url VARCHAR(1024) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    response_status INT,
    duration_ms BIGINT,
    outcome VARCHAR(50) NOT NULL,
    safe_error_summary TEXT
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY,
    project_id UUID,
    user_id UUID,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(100),
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_events_project_time ON events(project_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_request_id ON events(request_id);
CREATE INDEX IF NOT EXISTS idx_events_status_code ON events(status_code);
CREATE INDEX IF NOT EXISTS idx_events_error_type ON events(error_type);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON project_api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_replay_event_time ON replay_attempts(event_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_project_time ON audit_logs(project_id, created_at DESC);
