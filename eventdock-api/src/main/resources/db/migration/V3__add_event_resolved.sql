-- Migration V3: Add resolved boolean flag to diagnostic events
ALTER TABLE events ADD COLUMN IF NOT EXISTS resolved BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_events_project_resolved ON events(project_id, resolved);
