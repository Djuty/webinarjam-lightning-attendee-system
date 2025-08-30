-- WebinarJam Database Setup for Supabase (FIXED VERSION)
-- Execute this in your Supabase SQL Editor

-- ============================================================================
-- 0. CLEAN SLATE - DROP EXISTING OBJECTS IF THEY EXIST
-- ============================================================================

-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS recent_attendance_checks CASCADE;
DROP VIEW IF EXISTS webinar_attendance_summary CASCADE;

-- Drop function
DROP FUNCTION IF EXISTS upsert_webinar_registrant CASCADE;

-- Drop tables (attendance_checks first due to foreign key)
DROP TABLE IF EXISTS attendance_checks CASCADE;
DROP TABLE IF EXISTS webinar_registrants CASCADE;

-- ============================================================================
-- 1. CREATE WEBINAR REGISTRANTS TABLE
-- ============================================================================

CREATE TABLE webinar_registrants (
    id BIGSERIAL PRIMARY KEY,
    
    -- WebinarJam Data
    webinarjam_id INTEGER UNIQUE NOT NULL,
    lead_id INTEGER,
    webinar_id INTEGER NOT NULL,
    schedule_id INTEGER NOT NULL,
    event_id INTEGER,
    
    -- Contact Info
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone_country_code VARCHAR(10),
    phone_number VARCHAR(50),
    
    -- Webinar Details
    webinar_name VARCHAR(255),
    schedule VARCHAR(255),
    event_date TIMESTAMP,
    signup_date TIMESTAMP,
    
    -- Attendance Status
    attended_live BOOLEAN DEFAULT FALSE,
    date_live TIMESTAMP NULL,
    entered_live INTERVAL NULL,
    time_live INTERVAL NULL,
    
    -- Purchase Data
    purchased_live BOOLEAN DEFAULT FALSE,
    revenue_live DECIMAL(10,2) DEFAULT 0,
    
    -- Replay Data
    attended_replay BOOLEAN DEFAULT FALSE,
    date_replay TIMESTAMP NULL,
    time_replay INTERVAL NULL,
    purchased_replay BOOLEAN DEFAULT FALSE,
    revenue_replay DECIMAL(10,2) DEFAULT 0,
    
    -- Subscription Status
    subscribed BOOLEAN DEFAULT TRUE,
    gdpr_status VARCHAR(50),
    gdpr_communications VARCHAR(50),
    
    -- UTM Tracking
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    utm_term VARCHAR(255),
    utm_content VARCHAR(255),
    
    -- Tracking
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_synced_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 2. CREATE ATTENDANCE CHECKS TABLE
-- ============================================================================

CREATE TABLE attendance_checks (
    id BIGSERIAL PRIMARY KEY,
    
    -- Reference Data
    registrant_id BIGINT REFERENCES webinar_registrants(id),
    ghl_contact_id VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    
    -- Check Details
    webinar_id INTEGER,
    schedule_id INTEGER,
    check_event_date TIMESTAMP,  -- Renamed to avoid confusion
    
    -- Results
    attended BOOLEAN,
    attendance_status VARCHAR(50), -- 'attended', 'no_show'
    tag_added VARCHAR(100),
    tag_removed VARCHAR(100),
    
    -- Performance
    response_time_ms INTEGER,
    
    -- Timestamps
    checked_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Fast email lookups
CREATE INDEX idx_webinar_registrants_email 
ON webinar_registrants(email);

-- Fast webinar/schedule lookups
CREATE INDEX idx_webinar_registrants_webinar_schedule 
ON webinar_registrants(webinar_id, schedule_id);

-- Fast event date lookups
CREATE INDEX idx_webinar_registrants_event_date 
ON webinar_registrants(event_date);

-- Fast attendance lookups
CREATE INDEX idx_webinar_registrants_attended 
ON webinar_registrants(attended_live);

-- Composite index for fast attendance checks
CREATE INDEX idx_webinar_registrants_lookup 
ON webinar_registrants(email, webinar_id, schedule_id);

-- Attendance checks indexes
CREATE INDEX idx_attendance_checks_email 
ON attendance_checks(email);

CREATE INDEX idx_attendance_checks_ghl_contact 
ON attendance_checks(ghl_contact_id);

CREATE INDEX idx_attendance_checks_date 
ON attendance_checks(checked_at);

-- ============================================================================
-- 4. CREATE HELPFUL VIEWS FOR ANALYTICS
-- ============================================================================

-- Attendance summary by webinar
CREATE VIEW webinar_attendance_summary AS
SELECT 
    webinar_name,
    webinar_id,
    schedule_id,
    COUNT(*) as total_registrants,
    SUM(CASE WHEN attended_live THEN 1 ELSE 0 END) as total_attendees,
    ROUND(AVG(CASE WHEN attended_live THEN 1.0 ELSE 0.0 END) * 100, 2) as attendance_rate_percent,
    SUM(CASE WHEN purchased_live THEN 1 ELSE 0 END) as live_purchases,
    SUM(revenue_live) as live_revenue,
    SUM(CASE WHEN purchased_replay THEN 1 ELSE 0 END) as replay_purchases,
    SUM(revenue_replay) as replay_revenue,
    SUM(revenue_live + revenue_replay) as total_revenue
FROM webinar_registrants 
GROUP BY webinar_name, webinar_id, schedule_id
ORDER BY total_registrants DESC;

-- Recent attendance checks
CREATE VIEW recent_attendance_checks AS
SELECT 
    ac.*,
    wr.first_name,
    wr.last_name,
    wr.webinar_name,
    wr.event_date
FROM attendance_checks ac
LEFT JOIN webinar_registrants wr ON wr.id = ac.registrant_id
ORDER BY ac.checked_at DESC;

-- ============================================================================
-- 5. CREATE FUNCTIONS FOR UPSERTS
-- ============================================================================

-- Function to upsert registrant data from WebinarJam API
CREATE FUNCTION upsert_webinar_registrant(
    p_webinarjam_id INTEGER,
    p_lead_id INTEGER,
    p_webinar_id INTEGER,
    p_schedule_id INTEGER,
    p_event_id INTEGER,
    p_email VARCHAR(255),
    p_first_name VARCHAR(255),
    p_last_name VARCHAR(255),
    p_phone_country_code VARCHAR(10),
    p_phone_number VARCHAR(50),
    p_webinar_name VARCHAR(255),
    p_schedule VARCHAR(255),
    p_event_date TIMESTAMP,
    p_signup_date TIMESTAMP,
    p_attended_live BOOLEAN,
    p_date_live TIMESTAMP,
    p_entered_live INTERVAL,
    p_time_live INTERVAL,
    p_purchased_live BOOLEAN,
    p_revenue_live DECIMAL(10,2),
    p_attended_replay BOOLEAN,
    p_date_replay TIMESTAMP,
    p_time_replay INTERVAL,
    p_purchased_replay BOOLEAN,
    p_revenue_replay DECIMAL(10,2),
    p_subscribed BOOLEAN,
    p_gdpr_status VARCHAR(50),
    p_gdpr_communications VARCHAR(50),
    p_utm_source VARCHAR(255),
    p_utm_medium VARCHAR(255),
    p_utm_campaign VARCHAR(255),
    p_utm_term VARCHAR(255),
    p_utm_content VARCHAR(255)
) RETURNS BIGINT AS $$
DECLARE
    result_id BIGINT;
BEGIN
    INSERT INTO webinar_registrants (
        webinarjam_id, lead_id, webinar_id, schedule_id, event_id,
        email, first_name, last_name, phone_country_code, phone_number,
        webinar_name, schedule, event_date, signup_date,
        attended_live, date_live, entered_live, time_live,
        purchased_live, revenue_live,
        attended_replay, date_replay, time_replay, purchased_replay, revenue_replay,
        subscribed, gdpr_status, gdpr_communications,
        utm_source, utm_medium, utm_campaign, utm_term, utm_content,
        last_synced_at
    ) VALUES (
        p_webinarjam_id, p_lead_id, p_webinar_id, p_schedule_id, p_event_id,
        p_email, p_first_name, p_last_name, p_phone_country_code, p_phone_number,
        p_webinar_name, p_schedule, p_event_date, p_signup_date,
        p_attended_live, p_date_live, p_entered_live, p_time_live,
        p_purchased_live, p_revenue_live,
        p_attended_replay, p_date_replay, p_time_replay, p_purchased_replay, p_revenue_replay,
        p_subscribed, p_gdpr_status, p_gdpr_communications,
        p_utm_source, p_utm_medium, p_utm_campaign, p_utm_term, p_utm_content,
        NOW()
    )
    ON CONFLICT (webinarjam_id) 
    DO UPDATE SET
        lead_id = p_lead_id,
        webinar_id = p_webinar_id,
        schedule_id = p_schedule_id,
        event_id = p_event_id,
        email = p_email,
        first_name = p_first_name,
        last_name = p_last_name,
        phone_country_code = p_phone_country_code,
        phone_number = p_phone_number,
        webinar_name = p_webinar_name,
        schedule = p_schedule,
        event_date = p_event_date,
        signup_date = p_signup_date,
        attended_live = p_attended_live,
        date_live = p_date_live,
        entered_live = p_entered_live,
        time_live = p_time_live,
        purchased_live = p_purchased_live,
        revenue_live = p_revenue_live,
        attended_replay = p_attended_replay,
        date_replay = p_date_replay,
        time_replay = p_time_replay,
        purchased_replay = p_purchased_replay,
        revenue_replay = p_revenue_replay,
        subscribed = p_subscribed,
        gdpr_status = p_gdpr_status,
        gdpr_communications = p_gdpr_communications,
        utm_source = p_utm_source,
        utm_medium = p_utm_medium,
        utm_campaign = p_utm_campaign,
        utm_term = p_utm_term,
        utm_content = p_utm_content,
        updated_at = NOW(),
        last_synced_at = NOW()
    RETURNING id INTO result_id;
    
    RETURN result_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. VERIFICATION QUERY
-- ============================================================================

-- Verify setup
SELECT
    'Database setup completed successfully!' as status,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_name IN ('webinar_registrants', 'attendance_checks')) as tables_created,
    (SELECT COUNT(*) FROM information_schema.views
     WHERE table_name IN ('webinar_attendance_summary', 'recent_attendance_checks')) as views_created;

-- Simple test to verify tables work
SELECT 'Tables are functional!' as test_status;

-- Performance test query (should use index)
-- EXPLAIN ANALYZE SELECT * FROM webinar_registrants 
-- WHERE email = 'test@example.com' AND webinar_id = 13 AND schedule_id = 46;

COMMENT ON TABLE webinar_registrants IS 'WebinarJam registrants with attendance data';
COMMENT ON TABLE attendance_checks IS 'Log of attendance checks performed via GHL webhooks';
COMMENT ON VIEW webinar_attendance_summary IS 'Analytics view for webinar performance';
COMMENT ON VIEW recent_attendance_checks IS 'Recent attendance check activity';