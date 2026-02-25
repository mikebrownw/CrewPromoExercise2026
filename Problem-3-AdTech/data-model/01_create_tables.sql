-- SQL Server (T-SQL)
-- Complete Data Model for AdTech Analytics

-- Create users table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    country VARCHAR(2) NOT NULL,  -- ISO country code (US, CA, etc.)
    created_at DATETIME2 DEFAULT GETDATE(),
    -- Added index recommendation
    CONSTRAINT chk_country CHECK (country IN ('US', 'CA', 'UK', 'FR', 'DE', 'AU', 'JP'))
);

-- Create events table with JSON support
CREATE TABLE events (
    event_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    event_time DATETIME2 NOT NULL,
    payload_json NVARCHAR(MAX) NOT NULL,  -- SQL Server uses NVARCHAR for JSON
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    -- Add constraint to ensure valid JSON
    CONSTRAINT chk_valid_json CHECK (ISJSON(payload_json) = 1)
);

-- Create indexes for performance
CREATE INDEX idx_events_user_time ON events(user_id, event_time) INCLUDE (payload_json);
CREATE INDEX idx_events_time_country ON events(event_time) INCLUDE (user_id);  -- Will join to users

PRINT 'AdTech tables created successfully';
