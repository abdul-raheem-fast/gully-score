-- Migration: Add scorecard columns to matches table
-- These columns store the final scores, result string, and winning team
-- so that match history can be loaded directly from the database.

ALTER TABLE matches
  ADD COLUMN IF NOT EXISTS score_a  TEXT DEFAULT '0/0',
  ADD COLUMN IF NOT EXISTS score_b  TEXT DEFAULT '0/0',
  ADD COLUMN IF NOT EXISTS result   TEXT,       -- e.g. "Alpha Blasters won by 23 runs"
  ADD COLUMN IF NOT EXISTS winner   TEXT;       -- winning team name, empty string = tie

-- Update existing live/completed rows to have default score values if null
UPDATE matches
SET score_a = '0/0'
WHERE score_a IS NULL;

UPDATE matches
SET score_b = '0/0'
WHERE score_b IS NULL;
