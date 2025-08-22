-- Community Connect Transaction Service Database Initialization
-- This script sets up the basic database structure for the transaction service

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a function for credit balance calculations
CREATE OR REPLACE FUNCTION calculate_credit_balance(user_uuid UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    balance DECIMAL(10,2) := 0.00;
BEGIN
    -- This will be implemented when transaction tables are created
    -- For now, return 0
    RETURN balance;
END;
$$ language 'plpgsql';

-- Create a function for transaction validation
CREATE OR REPLACE FUNCTION validate_transaction(
    from_user UUID,
    to_user UUID,
    credit_amount DECIMAL(10,2)
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Basic validation rules
    IF from_user = to_user THEN
        RETURN FALSE; -- Cannot transfer to self
    END IF;
    
    IF credit_amount <= 0 THEN
        RETURN FALSE; -- Amount must be positive
    END IF;
    
    -- Add more validation rules as needed
    RETURN TRUE;
END;
$$ language 'plpgsql';

-- Log initialization
INSERT INTO information_schema.sql_features (feature_id, feature_name, sub_feature_id, sub_feature_name, is_supported, comments)
VALUES ('CC002', 'Community Connect Transaction Service', '1', 'Database Initialized', 'YES', 'Transaction service database initialized successfully')
ON CONFLICT DO NOTHING;