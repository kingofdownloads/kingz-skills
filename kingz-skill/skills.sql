

-- Check if skills column exists, if not add it
ALTER TABLE players ADD COLUMN IF NOT EXISTS skills TEXT DEFAULT '{}';

-- Check if reputation column exists, if not add it
ALTER TABLE players ADD COLUMN IF NOT EXISTS reputation TEXT DEFAULT '{}';
