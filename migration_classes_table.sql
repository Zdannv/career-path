-- Create classes table to store registered class codes for teachers
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_code VARCHAR UNIQUE NOT NULL,
    class_name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
