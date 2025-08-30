-- WebinarJam Minimal Database Setup (For Testing)
-- Use this if the full schema has issues

-- Clean slate
DROP TABLE IF EXISTS attendance_checks CASCADE;
DROP TABLE IF EXISTS webinar_registrants CASCADE;

-- Minimal registrants table
CREATE TABLE webinar_registrants (
    id BIGSERIAL PRIMARY KEY,
    webinarjam_id INTEGER UNIQUE NOT NULL,
    webinar_id INTEGER NOT NULL,
    schedule_id INTEGER NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    webinar_name VARCHAR(255),
    event_date TIMESTAMP,
    attended_live BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Minimal attendance checks table  
CREATE TABLE attendance_checks (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    ghl_contact_id VARCHAR(255),
    attended BOOLEAN,
    attendance_status VARCHAR(50),
    tag_added VARCHAR(100),
    response_time_ms INTEGER,
    checked_at TIMESTAMP DEFAULT NOW()
);

-- Essential indexes only
CREATE INDEX idx_registrants_email ON webinar_registrants(email);
CREATE INDEX idx_registrants_lookup ON webinar_registrants(email, webinar_id, schedule_id);

-- Test query
SELECT 'Minimal database setup completed!' as status;