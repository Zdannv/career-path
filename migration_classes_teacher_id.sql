-- Alter classes table to associate each class with a specific teacher (Guidance Counselor)
ALTER TABLE classes ADD COLUMN IF NOT EXISTS teacher_id UUID DEFAULT NULL;
