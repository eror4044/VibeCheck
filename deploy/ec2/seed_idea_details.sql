BEGIN;

-- Update seeded ideas with rich, short and clear details.
-- Idempotent: updates by title prefix.

UPDATE ideas
SET
  stage = 'prototype',
  one_liner = 'A 25-minute focus timer that ends with a single actionable note.',
  problem = 'Most focus apps track time but don’t help you capture what mattered in that sprint.',
  solution = 'One tap start, one tap end, then a tiny prompt to save the key outcome.',
  audience = 'People who do deep work (students, makers, engineers).',
  differentiator = 'Outcome-first: less tracking, more clarity.',
  links = jsonb_build_object('demo_url', 'https://example.com/focus-sprint')
WHERE title = '[seed] Focus Sprint';

UPDATE ideas
SET
  stage = 'beta',
  one_liner = 'Snap a meal photo and get a simple macro estimate + weekly patterns.',
  problem = 'Nutrition tracking is too time-consuming for most people to sustain.',
  solution = 'Photo-first logging + lightweight estimates and trend summaries.',
  audience = 'People who want healthier eating without meticulous logging.',
  differentiator = 'Fast enough to use daily.',
  links = jsonb_build_object('waitlist_url', 'https://example.com/meal-snap')
WHERE title = '[seed] Meal Snap';

UPDATE ideas
SET
  stage = 'idea',
  one_liner = 'Turn your commute into a personalized micro-podcast from your saved links.',
  problem = 'Saved links pile up and never get read.',
  solution = 'Auto-summarize your list into short audio you can listen to on the go.',
  audience = 'Busy people with long reading lists.',
  differentiator = 'From “read later” to “listen now”.'
WHERE title = '[seed] Commute Remix';

-- Generic defaults for the rest of [seed] ideas that still have empty one_liner
UPDATE ideas
SET
  one_liner = COALESCE(NULLIF(one_liner, ''), short_pitch),
  stage = COALESCE(stage, 'idea')
WHERE title LIKE '[seed]%' AND (one_liner = '' OR one_liner IS NULL);

COMMIT;

SELECT COUNT(*) AS seeded_with_details
FROM ideas
WHERE title LIKE '[seed]%' AND one_liner IS NOT NULL AND one_liner <> '';
