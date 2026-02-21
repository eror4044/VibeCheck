-- 0003: User-created ideas (author, status) + idea_media table

-- Author tracking & draft/published status
ALTER TABLE ideas
  ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'published';

-- Media gallery for ideas (photos / videos)
CREATE TABLE IF NOT EXISTS idea_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idea_id UUID NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
  media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('image', 'video')),
  s3_key VARCHAR(500) NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_idea_media_idea ON idea_media(idea_id);
CREATE INDEX IF NOT EXISTS idx_ideas_author ON ideas(author_id);
CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas(status);

-- Feed should only show published ideas
-- Existing seed data already has status='published' via DEFAULT.
