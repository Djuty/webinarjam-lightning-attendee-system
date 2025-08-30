-- EverWebinar Compatible Database Schema
-- Updated to match actual EverWebinar API response structure

-- Drop existing tables if they exist
DROP TABLE IF EXISTS attendance_logs CASCADE;
DROP TABLE IF EXISTS webinar_registrants CASCADE;

-- Create webinar_registrants table with EverWebinar fields
CREATE TABLE webinar_registrants (
    id SERIAL PRIMARY KEY,
    
    -- Contact Information
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(50),
    
    -- Webinar Information
    webinar_id INTEGER NOT NULL,
    schedule_id INTEGER,
    event_id INTEGER,
    lead_id INTEGER,
    
    -- Dates and Times
    registration_date TIMESTAMPTZ,
    webinar_date TIMESTAMPTZ,
    timezone VARCHAR(100) DEFAULT 'Europe/Amsterdam',
    
    -- Attendance Status
    attended BOOLEAN DEFAULT FALSE,
    attended_live BOOLEAN DEFAULT FALSE,
    attended_replay BOOLEAN DEFAULT FALSE,
    
    -- EverWebinar Specific Fields
    date_live VARCHAR(100),
    entered_live VARCHAR(20),
    time_live VARCHAR(20),
    purchased_live BOOLEAN DEFAULT FALSE,
    revenue_live DECIMAL(10,2) DEFAULT 0,
    
    date_replay VARCHAR(100),
    time_replay VARCHAR(20),
    purchased_replay BOOLEAN DEFAULT FALSE,
    revenue_replay DECIMAL(10,2) DEFAULT 0,
    
    -- URLs and Links
    live_room_url TEXT,
    replay_room_url TEXT,
    thank_you_url TEXT,
    unsubscribe_url TEXT,
    
    -- Subscription and GDPR
    subscribed BOOLEAN DEFAULT TRUE,
    gdpr_status VARCHAR(20) DEFAULT 'Off',
    gdpr_communications VARCHAR(20) DEFAULT 'Off',
    gdpr_status_date TIMESTAMPTZ,
    gdpr_status_ip VARCHAR(45),
    twilio_consented_at TIMESTAMPTZ,
    
    -- UTM Tracking
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    utm_term VARCHAR(255),
    utm_content VARCHAR(255),
    
    -- System Fields
    ip_address VARCHAR(45),
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint for email + webinar + schedule combination
    UNIQUE(email, webinar_id, schedule_id)
);

-- Create attendance_logs table for tracking checks
CREATE TABLE attendance_logs (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    contact_id VARCHAR(100),
    webinar_id INTEGER NOT NULL,
    schedule_id INTEGER,
    attended BOOLEAN DEFAULT FALSE,
    tag_added VARCHAR(100),
    check_timestamp TIMESTAMPTZ DEFAULT NOW(),
    response_data JSONB,
    error_message TEXT,
    processing_time_ms INTEGER
);

-- Create performance indexes for lightning-fast lookups
CREATE INDEX idx_registrants_email_webinar ON webinar_registrants(email, webinar_id);
CREATE INDEX idx_registrants_schedule ON webinar_registrants(schedule_id);
CREATE INDEX idx_registrants_webinar_date ON webinar_registrants(webinar_date);
CREATE INDEX idx_registrants_attended ON webinar_registrants(attended);
CREATE INDEX idx_registrants_last_updated ON webinar_registrants(last_updated);

-- Create composite index for the most common lookup pattern
CREATE INDEX idx_registrants_lookup ON webinar_registrants(email, webinar_id, schedule_id);

-- Create indexes for attendance_logs table
CREATE INDEX idx_attendance_logs_email ON attendance_logs(email);
CREATE INDEX idx_attendance_logs_timestamp ON attendance_logs(check_timestamp);
CREATE INDEX idx_attendance_logs_webinar ON attendance_logs(webinar_id);

-- Create function for upsert operations
CREATE OR REPLACE FUNCTION upsert_registrant(
    p_email VARCHAR(255),
    p_first_name VARCHAR(255),
    p_last_name VARCHAR(255),
    p_phone VARCHAR(50),
    p_webinar_id INTEGER,
    p_schedule_id INTEGER,
    p_registration_date TIMESTAMPTZ,
    p_webinar_date TIMESTAMPTZ,
    p_timezone VARCHAR(100),
    p_live_room_url TEXT,
    p_replay_room_url TEXT,
    p_attended BOOLEAN,
    p_attended_live BOOLEAN,
    p_attended_replay BOOLEAN,
    p_event_id INTEGER,
    p_lead_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    result_id INTEGER;
BEGIN
    INSERT INTO webinar_registrants (
        email, first_name, last_name, phone, webinar_id, schedule_id,
        registration_date, webinar_date, timezone, live_room_url, 
        replay_room_url, attended, attended_live, attended_replay,
        event_id, lead_id, last_updated
    ) VALUES (
        p_email, p_first_name, p_last_name, p_phone, p_webinar_id, p_schedule_id,
        p_registration_date, p_webinar_date, p_timezone, p_live_room_url,
        p_replay_room_url, p_attended, p_attended_live, p_attended_replay,
        p_event_id, p_lead_id, NOW()
    )
    ON CONFLICT (email, webinar_id, schedule_id) 
    DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        phone = EXCLUDED.phone,
        registration_date = EXCLUDED.registration_date,
        webinar_date = EXCLUDED.webinar_date,
        timezone = EXCLUDED.timezone,
        live_room_url = EXCLUDED.live_room_url,
        replay_room_url = EXCLUDED.replay_room_url,
        attended = EXCLUDED.attended,
        attended_live = EXCLUDED.attended_live,
        attended_replay = EXCLUDED.attended_replay,
        event_id = EXCLUDED.event_id,
        lead_id = EXCLUDED.lead_id,
        last_updated = NOW()
    RETURNING id INTO result_id;
    
    RETURN result_id;
END;
$$ LANGUAGE plpgsql;

-- Create function for lightning-fast attendance lookup
CREATE OR REPLACE FUNCTION check_attendance(
    p_email VARCHAR(255),
    p_webinar_id INTEGER,
    p_schedule_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    email VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(50),
    webinar_id INTEGER,
    schedule_id INTEGER,
    webinar_date TIMESTAMPTZ,
    attended BOOLEAN,
    attended_live BOOLEAN,
    attended_replay BOOLEAN,
    registration_date TIMESTAMPTZ,
    live_room_url TEXT,
    replay_room_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.email,
        r.first_name,
        r.last_name,
        r.phone,
        r.webinar_id,
        r.schedule_id,
        r.webinar_date,
        r.attended,
        r.attended_live,
        r.attended_replay,
        r.registration_date,
        r.live_room_url,
        r.replay_room_url
    FROM webinar_registrants r
    WHERE r.email = p_email 
      AND r.webinar_id = p_webinar_id
      AND (p_schedule_id IS NULL OR r.schedule_id = p_schedule_id)
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Create view for easy reporting
CREATE VIEW attendance_summary AS
SELECT 
    webinar_id,
    schedule_id,
    COUNT(*) as total_registrants,
    COUNT(*) FILTER (WHERE attended = true) as total_attended,
    COUNT(*) FILTER (WHERE attended_live = true) as attended_live,
    COUNT(*) FILTER (WHERE attended_replay = true) as attended_replay,
    COUNT(*) FILTER (WHERE attended = false) as no_shows,
    ROUND(
        (COUNT(*) FILTER (WHERE attended = true)::DECIMAL / COUNT(*)) * 100, 
        2
    ) as attendance_rate_percent
FROM webinar_registrants
GROUP BY webinar_id, schedule_id
ORDER BY webinar_id, schedule_id;

-- Insert sample data for testing (optional)
-- This matches the structure from your EverWebinar API response
INSERT INTO webinar_registrants (
    email, first_name, last_name, phone, webinar_id, schedule_id,
    registration_date, webinar_date, timezone, live_room_url, replay_room_url,
    attended, attended_live, attended_replay, event_id, lead_id
) VALUES 
(
    'annettelamberts@hotmail.com', 'Annette', '', '+31622440610', 13, 46,
    '2025-08-25T19:46:00Z', '2025-09-01T18:30:00Z', 'Europe/Amsterdam',
    'https://event.webinarjam.com/go/live/13/g4z89hvh4otzowoi3gx0',
    'https://event.webinarjam.com/go/replay/13/g4z89hvh4otzowoi3gx0',
    false, false, false, 27431, 20384
),
(
    'mib36645@gmail.com', 'Michael', '', '+31615062651', 13, 46,
    '2025-08-25T19:25:00Z', '2025-08-25T18:30:00Z', 'Europe/Amsterdam',
    'https://event.webinarjam.com/go/live/13/5y6nxizhyot5v1qtn1g8',
    'https://event.webinarjam.com/go/replay/13/5y6nxizhyot5v1qtn1g8',
    false, false, false, 27430, 14870
);

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON webinar_registrants TO your_app_user;
-- GRANT ALL PRIVILEGES ON attendance_logs TO your_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_app_user;

-- Performance verification query
-- Run this to verify indexes are working
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM webinar_registrants 
WHERE email = 'annettelamberts@hotmail.com' 
  AND webinar_id = 13 
  AND schedule_id = 46;

-- Success message
SELECT 'EverWebinar database schema created successfully! 🚀' as status;