-- Community Connect Core Service Database Initialization
-- This script sets up the basic database structure for the core service

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create basic schema structure (tables will be created by Spring Boot JPA)
-- This is just for initial setup and common functions

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create indexes for common queries (will be useful when tables are created)
-- Note: These will be created by JPA, this is just a placeholder for custom indexes

-- Log initialization
INSERT INTO information_schema.sql_features (feature_id, feature_name, sub_feature_id, sub_feature_name, is_supported, comments)
VALUES ('CC001', 'Community Connect Core Service', '1', 'Database Initialized', 'YES', 'Core service database initialized successfully')
ON CONFLICT DO NOTHING;