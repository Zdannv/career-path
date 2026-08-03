-- Alter user_journeys table to add cost_forecast column
ALTER TABLE user_journeys ADD COLUMN IF NOT EXISTS cost_forecast JSONB DEFAULT NULL;
