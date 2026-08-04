-- Alter user_journeys table to store CSAT (Customer Satisfaction) rating from students
ALTER TABLE user_journeys ADD COLUMN IF NOT EXISTS csat_rating INTEGER DEFAULT NULL;
