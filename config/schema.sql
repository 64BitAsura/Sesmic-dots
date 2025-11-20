-- PostgreSQL schema for seismic events

-- Create database (run separately if needed)
-- CREATE DATABASE seismic;

-- Create seismic_events table
CREATE TABLE IF NOT EXISTS seismic_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(50),
    magnitude DECIMAL(4, 2),
    magnitude_type VARCHAR(10),
    depth DECIMAL(8, 2),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    time TIMESTAMP,
    last_update TIMESTAMP,
    flynn_region VARCHAR(255),
    auth VARCHAR(100),
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_seismic_events_magnitude ON seismic_events(magnitude);
CREATE INDEX IF NOT EXISTS idx_seismic_events_time ON seismic_events(time);
CREATE INDEX IF NOT EXISTS idx_seismic_events_flynn_region ON seismic_events(flynn_region);
CREATE INDEX IF NOT EXISTS idx_seismic_events_created_at ON seismic_events(created_at);

-- Create index on JSONB column for querying raw data
CREATE INDEX IF NOT EXISTS idx_seismic_events_raw_data ON seismic_events USING gin(raw_data);

-- Create a view for recent significant events
CREATE OR REPLACE VIEW recent_significant_events AS
SELECT 
    event_id,
    magnitude,
    magnitude_type,
    depth,
    latitude,
    longitude,
    time,
    flynn_region
FROM seismic_events
WHERE magnitude >= 5.0
ORDER BY time DESC
LIMIT 100;

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_seismic_events_updated_at 
    BEFORE UPDATE ON seismic_events 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON TABLE seismic_events TO postgres;
-- GRANT ALL PRIVILEGES ON SEQUENCE seismic_events_id_seq TO postgres;
