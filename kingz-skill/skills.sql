-- Check if skills column exists, if not add it
ALTER TABLE players ADD COLUMN IF NOT EXISTS skills TEXT DEFAULT '{}';

-- Check if reputation column exists, if not add it
ALTER TABLE players ADD COLUMN IF NOT EXISTS reputation TEXT DEFAULT '{}';

-- Insert default skills for all players
UPDATE players SET skills = '{"cooking":{"xp":0,"level":0,"maxXP":100}}' WHERE skills = '{}' OR skills IS NULL;
