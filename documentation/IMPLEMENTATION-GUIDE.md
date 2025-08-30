# 🚀 Supabase WebinarJam Implementation Guide

## Overview
Complete guide to implement the lightning-fast Supabase-based WebinarJam attendee checker system.

## 🎯 Performance Goals
- **< 50ms**: Database attendance lookups
- **< 1000ms**: Complete webhook processing
- **100K+ registrants**: Scalable architecture
- **99.9% uptime**: Production-ready reliability

---

## 📋 Implementation Checklist

### Phase 1: Supabase Setup
- [ ] Create Supabase project
- [ ] Execute database schema (`database/schema.sql`)
- [ ] Configure database indexes
- [ ] Test database connection
- [ ] Verify performance with sample data

### Phase 2: Data Synchronization
- [ ] Import `workflows/data-sync.json` to N8N
- [ ] Configure WebinarJam API credentials
- [ ] Configure Supabase database connection
- [ ] Run initial data sync
- [ ] Schedule recurring sync (every 6 hours)

### Phase 3: Lightning Attendee Checker
- [ ] Import `workflows/lightning-attendee-checker.json` to N8N
- [ ] Configure GoHighLevel API credentials
- [ ] Configure Supabase database connection
- [ ] Set up webhook URL in GoHighLevel
- [ ] Test with sample webhook data

---

## 🛠️ Step-by-Step Setup

### 1. Supabase Database Setup

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Note your project URL and API keys
4. Go to SQL Editor

#### Execute Database Schema
1. Copy contents of `database/schema.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"
4. Verify tables created:
   - `webinar_registrants`
   - `attendance_checks`

#### Test Database Performance
```sql
-- Test index performance
EXPLAIN ANALYZE 
SELECT * FROM webinar_registrants 
WHERE email = 'test@example.com' 
AND webinar_id = 13;

-- Should show "Index Scan" with < 1ms execution time
```

### 2. N8N Credentials Setup

#### WebinarJam API Credential
1. N8N → Credentials → Add Credential
2. Type: "HTTP Basic Auth"
3. Name: "WebinarJam API"
4. Username: `[your_webinarjam_api_key]`
5. Password: `[leave_blank]`

#### Supabase Database Credential
1. N8N → Credentials → Add Credential
2. Type: "Postgres"
3. Name: "Supabase Database"
4. Host: `[your_supabase_host]` (from project settings)
5. Database: `postgres`
6. User: `postgres`
7. Password: `[your_supabase_password]`
8. Port: `5432`
9. SSL: `Allow`

#### GoHighLevel API Credential
1. N8N → Credentials → Add Credential
2. Type: "GoHighLevel API"
3. Name: "GoHighLevel API"
4. API Key: `[your_ghl_api_key]`

### 3. Import N8N Workflows

#### Data Sync Workflow
1. N8N → Import from File
2. Select: `workflows/data-sync.json`
3. Configure credentials:
   - WebinarJam API → Select "WebinarJam API"
   - Postgres → Select "Supabase Database"
4. Update webinar_id in HTTP Request nodes (currently set to 13)
5. Activate workflow

#### Lightning Attendee Checker
1. N8N → Import from File
2. Select: `workflows/lightning-attendee-checker.json`
3. Configure credentials:
   - GoHighLevel API → Select "GoHighLevel API"
   - Postgres → Select "Supabase Database"
4. Copy webhook URL from webhook trigger node
5. Activate workflow

### 4. GoHighLevel Webhook Setup

1. Go to GoHighLevel → Automation → Workflows
2. Create new workflow
3. Add webhook trigger (use URL from N8N)
4. Set trigger condition: "3 hours after webinar ends"
5. Send webhook with contact data:
   ```json
   {
     "email": "{{contact.email}}",
     "contact_id": "{{contact.id}}",
     "tags": {{contact.tags}}
   }
   ```

---

## 🧪 Testing & Validation

### Test Data Sync
1. Check sync workflow execution logs
2. Verify registrants imported:
   ```sql
   SELECT COUNT(*) FROM webinar_registrants WHERE webinar_id = 13;
   ```
3. Check attendance data:
   ```sql
   SELECT 
     COUNT(*) as total,
     SUM(CASE WHEN attended_live THEN 1 ELSE 0 END) as attended
   FROM webinar_registrants WHERE webinar_id = 13;
   ```

### Test Attendance Checker
1. Send test webhook to N8N URL:
   ```bash
   curl -X POST "https://your-n8n-url/webhook/ghl-webhook-attendance" \
     -H "Content-Type: application/json" \
     -d '{
       "body": {
         "email": "test@example.com",
         "contact_id": "test_contact_123"
       }
     }'
   ```

2. Check response for performance metrics:
   ```json
   {
     "success": true,
     "performance": {
       "total_time_ms": 45,
       "database_query_ms": 12,
       "status": "🚀 Lightning Fast"
     }
   }
   ```

### Performance Benchmarks
- **Database Query**: < 50ms
- **Total Processing**: < 1000ms
- **API Calls**: < 500ms each
- **Memory Usage**: < 100MB

---

## 📊 Monitoring & Analytics

### Built-in Analytics Views

#### Webinar Performance
```sql
SELECT * FROM webinar_attendance_summary;
```

#### Recent Activity
```sql
SELECT * FROM recent_attendance_checks LIMIT 50;
```

#### Performance Metrics
```sql
SELECT 
  AVG(response_time_ms) as avg_response_time,
  MAX(response_time_ms) as max_response_time,
  COUNT(*) as total_checks,
  attendance_status,
  DATE(checked_at) as check_date
FROM attendance_checks 
WHERE checked_at >= NOW() - INTERVAL '7 days'
GROUP BY attendance_status, DATE(checked_at)
ORDER BY check_date DESC;
```

### Performance Alerts
Set up monitoring for:
- Response time > 1000ms
- Database query time > 100ms
- Failed webhook rate > 5%
- Sync failures

---

## 🔧 Troubleshooting

### Common Issues

#### "Connection timeout" Error
- **Cause**: Supabase connection issues
- **Fix**: Check connection credentials, verify database is accessible

#### "Registrant not found" Warnings
- **Cause**: Email address mismatch or missing sync data
- **Fix**: Run manual sync, check email formats

#### Slow Performance (> 1000ms)
- **Cause**: Missing indexes or large dataset
- **Fix**: Verify indexes are created, consider data archiving

#### Webhook Not Triggering
- **Cause**: GoHighLevel workflow not configured correctly
- **Fix**: Verify webhook URL, check workflow conditions

### Debug Queries

#### Check Index Usage
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM webinar_registrants 
WHERE email = 'test@example.com' AND webinar_id = 13;
```

#### Monitor Database Performance
```sql
SELECT 
  schemaname,
  tablename,
  n_tup_ins as inserts,
  n_tup_upd as updates,
  n_tup_del as deletes,
  seq_scan,
  idx_scan
FROM pg_stat_user_tables 
WHERE tablename IN ('webinar_registrants', 'attendance_checks');
```

---

## 🚀 Production Deployment

### Pre-Production Checklist
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Error handling tested
- [ ] Monitoring configured
- [ ] Backup strategy in place

### Go-Live Steps
1. **Gradual Rollout**: Start with 10% of webhooks
2. **Monitor Performance**: Watch response times and error rates
3. **Scale Up**: Gradually increase to 100% traffic
4. **Document Issues**: Track any performance problems
5. **Optimize**: Fine-tune based on real-world data

### Maintenance Schedule
- **Daily**: Check error logs and performance metrics
- **Weekly**: Review attendance data accuracy
- **Monthly**: Optimize database, clean old logs
- **Quarterly**: Update WebinarJam sync, review architecture

---

## 💡 Advanced Features

### Custom Tagging Rules
Modify the tagging logic in the Lightning Checker:
```javascript
// Custom tag based on attendance and purchase behavior
const tag = lookupData.attended_live 
  ? (lookupData.purchased_live ? 'VIP Attendee' : 'Attended Webinar')
  : 'No Show Webinar';
```

### Multi-Webinar Support
Update the database lookup to handle multiple webinars:
```sql
-- Dynamic webinar selection based on contact tags
WHERE email = $1 
  AND webinar_id = COALESCE($2, webinar_id)
  AND event_date >= NOW() - INTERVAL '30 days'
ORDER BY event_date DESC
```

### Revenue Tracking
Add purchase data to the response:
```javascript
revenue: {
  live_purchase: lookupData.purchased_live,
  live_revenue: lookupData.revenue_live,
  replay_purchase: lookupData.purchased_replay,
  replay_revenue: lookupData.revenue_replay,
  total_revenue: lookupData.revenue_live + lookupData.revenue_replay
}
```

---

## 🎯 Success Metrics

### Key Performance Indicators
- **Response Time**: < 1000ms average
- **Accuracy Rate**: > 99% correct tagging
- **Uptime**: > 99.9% availability
- **Data Freshness**: < 6 hour sync lag

### Business Impact
- **Time Saved**: 15 minutes → 5 seconds per check
- **Scalability**: 285 → 100,000+ registrants
- **Reliability**: Manual errors eliminated
- **Insights**: Real-time attendance analytics

---

## 📞 Support

### Documentation
- `database/schema.sql`: Database schema
- `workflows/data-sync.json`: Data synchronization workflow
- `workflows/lightning-attendee-checker.json`: Main attendance checker

### Contact
For technical support or feature requests, refer to the workflow documentation or create a support ticket with detailed error logs and performance metrics.