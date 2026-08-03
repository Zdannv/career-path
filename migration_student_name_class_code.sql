-- Alter user_journeys table to add student_name and class_code columns
ALTER TABLE user_journeys ADD COLUMN IF NOT EXISTS student_name VARCHAR DEFAULT NULL;
ALTER TABLE user_journeys ADD COLUMN IF NOT EXISTS class_code VARCHAR DEFAULT NULL;
