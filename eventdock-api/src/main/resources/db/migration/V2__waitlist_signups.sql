-- V2__waitlist_signups.sql
-- Waitlist registrations for EventDock early access

CREATE TABLE IF NOT EXISTS waitlist_signups (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255),
    company VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_waitlist_signups_email ON waitlist_signups(email);
