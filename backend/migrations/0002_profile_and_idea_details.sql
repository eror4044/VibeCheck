-- Users: profile fields
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS display_name TEXT NULL,
  ADD COLUMN IF NOT EXISTS about TEXT NULL,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT NULL;

-- Ideas: rich details for swipe-up panel
DO $$ BEGIN
  CREATE TYPE idea_stage AS ENUM ('idea', 'prototype', 'beta', 'live');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE ideas
  ADD COLUMN IF NOT EXISTS one_liner TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS problem TEXT NULL,
  ADD COLUMN IF NOT EXISTS solution TEXT NULL,
  ADD COLUMN IF NOT EXISTS audience TEXT NULL,
  ADD COLUMN IF NOT EXISTS differentiator TEXT NULL,
  ADD COLUMN IF NOT EXISTS stage idea_stage NOT NULL DEFAULT 'idea',
  ADD COLUMN IF NOT EXISTS links JSONB NULL;

-- Backfill for existing rows: keep UX consistent.
UPDATE ideas
SET one_liner = short_pitch
WHERE one_liner = '';
