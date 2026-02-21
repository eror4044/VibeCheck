BEGIN;

-- Idempotent seed: insert only if title doesn't already exist.
-- Notes:
-- - media_url is NOT NULL in schema.
-- - tags column is JSONB.

WITH seed(title, short_pitch, category, tags, media_url, created_at) AS (
  VALUES
    ('[seed] Focus Sprint', 'A 25-minute focus timer with lightweight post-sprint notes.', 'productivity', '["focus","timer","habits"]'::jsonb, 'https://placehold.co/600x900/png?text=Focus+Sprint', now() - interval '1 minute'),
    ('[seed] Meal Snap', 'Take a photo of a meal and get a simple macro estimate + weekly patterns.', 'health', '["nutrition","tracking"]'::jsonb, 'https://placehold.co/600x900/png?text=Meal+Snap', now() - interval '2 minutes'),
    ('[seed] Commute Remix', 'Turn your commute into a personalized micro-podcast from your saved links.', 'media', '["audio","learning"]'::jsonb, 'https://placehold.co/600x900/png?text=Commute+Remix', now() - interval '3 minutes'),
    ('[seed] Quiet Desk', 'Ambient soundscapes that adapt to your typing speed and time of day.', 'productivity', '["ambient","focus"]'::jsonb, 'https://placehold.co/600x900/png?text=Quiet+Desk', now() - interval '4 minutes'),
    ('[seed] Budget Buddy', 'A friendly weekly spending recap with 3 actionable suggestions.', 'finance', '["budget","insights"]'::jsonb, 'https://placehold.co/600x900/png?text=Budget+Buddy', now() - interval '5 minutes'),
    ('[seed] Tiny Workout', '7-minute routines based on available space and equipment.', 'fitness', '["workout","short"]'::jsonb, 'https://placehold.co/600x900/png?text=Tiny+Workout', now() - interval '6 minutes'),
    ('[seed] Language Loop', 'Daily 3-minute speaking drills with instant playback.', 'education', '["language","practice"]'::jsonb, 'https://placehold.co/600x900/png?text=Language+Loop', now() - interval '7 minutes'),
    ('[seed] Sleep Winddown', 'A winddown checklist that learns which steps actually help you sleep.', 'health', '["sleep","routine"]'::jsonb, 'https://placehold.co/600x900/png?text=Sleep+Winddown', now() - interval '8 minutes'),
    ('[seed] Idea Vault', 'Save fleeting ideas in 5 seconds and auto-cluster them later.', 'productivity', '["ideas","notes"]'::jsonb, 'https://placehold.co/600x900/png?text=Idea+Vault', now() - interval '9 minutes'),
    ('[seed] Local Explorer', 'A map of nearby “good enough” spots based on your vibe, not ratings.', 'lifestyle', '["local","discovery"]'::jsonb, 'https://placehold.co/600x900/png?text=Local+Explorer', now() - interval '10 minutes'),
    ('[seed] Study Streak', 'A streak tracker that rewards consistency without guilt mechanics.', 'education', '["study","habits"]'::jsonb, 'https://placehold.co/600x900/png?text=Study+Streak', now() - interval '11 minutes'),
    ('[seed] Pantry Planner', 'Plan meals based on what you already have + 3-item shopping list.', 'food', '["cooking","planning"]'::jsonb, 'https://placehold.co/600x900/png?text=Pantry+Planner', now() - interval '12 minutes'),
    ('[seed] Travel Lite', 'Auto-generate a lightweight itinerary with buffer time blocks.', 'travel', '["itinerary","planning"]'::jsonb, 'https://placehold.co/600x900/png?text=Travel+Lite', now() - interval '13 minutes'),
    ('[seed] Pet Routine', 'Track walks/feeding with one tap and share only with your household.', 'home', '["pets","routine"]'::jsonb, 'https://placehold.co/600x900/png?text=Pet+Routine', now() - interval '14 minutes'),
    ('[seed] Habit Garden', 'Visualize habits as a simple garden; the goal is clarity, not dopamine.', 'productivity', '["habits","visual"]'::jsonb, 'https://placehold.co/600x900/png?text=Habit+Garden', now() - interval '15 minutes')
)
INSERT INTO ideas(title, short_pitch, category, tags, media_url, created_at)
SELECT s.title, s.short_pitch, s.category, s.tags, s.media_url, s.created_at
FROM seed s
WHERE NOT EXISTS (SELECT 1 FROM ideas i WHERE i.title = s.title);

COMMIT;

-- Quick verification
SELECT COUNT(*) AS seed_ideas_count FROM ideas WHERE title LIKE '[seed]%';
