-- ==============================================================================
-- EventDock: Direct Frontend Waitlist Table for Supabase
-- ==============================================================================
-- Run this script in your Supabase Dashboard:
-- https://supabase.com/dashboard/project/grgtlaeinlgbrejymwts/sql/new
--
-- This creates a dedicated 'waitlist_subscribers' table decoupled from the
-- Spring Boot backend, allowing direct frontend submissions with strict
-- Row Level Security (RLS) protections.
-- ==============================================================================

-- 1. Create the waitlist_subscribers table
CREATE TABLE IF NOT EXISTS public.waitlist_subscribers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    company VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT waitlist_subscribers_email_unique UNIQUE (email)
);

-- 2. Create index on email for quick lookup & deduplication
CREATE INDEX IF NOT EXISTS idx_waitlist_subscribers_email 
    ON public.waitlist_subscribers (email);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.waitlist_subscribers ENABLE ROW LEVEL SECURITY;

-- 4. Policy: Allow anyone (anon / authenticated) to INSERT into the waitlist
DROP POLICY IF EXISTS "Allow public insert into waitlist" ON public.waitlist_subscribers;
CREATE POLICY "Allow public insert into waitlist"
ON public.waitlist_subscribers
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- 5. Policy: Restrict SELECT so public users cannot dump/scrape subscriber emails.
-- Only service_role (or Supabase dashboard users) can read the subscribers.
DROP POLICY IF EXISTS "Deny public select on waitlist" ON public.waitlist_subscribers;
CREATE POLICY "Deny public select on waitlist"
ON public.waitlist_subscribers
FOR SELECT
TO service_role
USING (true);

-- ==============================================================================
-- Verification Query (Run anytime in SQL Editor to view your waitlist subscribers)
-- ==============================================================================
-- SELECT id, email, name, company, created_at 
-- FROM public.waitlist_subscribers 
-- ORDER BY created_at DESC;
