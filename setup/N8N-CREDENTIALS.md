# 🔑 N8N Credentials Setup Guide

## Overview
Step-by-step guide to configure all API credentials needed for the WebinarJam Lightning System.

---

## 📋 Required Credentials

You need to set up **3 credentials** in N8N:
1. **WebinarJam API** - For data synchronization
2. **Supabase Database** - For lightning-fast lookups  
3. **GoHighLevel API** - For contact tagging

---

## 🛠️ Setup Instructions

### 1. WebinarJam API Credential

#### In N8N:
1. Go to **Credentials** → **Add Credential**
2. Type: **"HTTP Basic Auth"**
3. Name: `WebinarJam API`
4. Configure:
   ```
   Username: [your-webinarjam-api-key]
   Password: [leave blank]
   ```

#### Get WebinarJam API Key:
1. Login to [WebinarJam Dashboard](https://home.webinarjam.com)
2. Go to **Account** → **API Access**
3. Copy your **API Key**
4. Use this as the **Username** in N8N (not password!)

---

### 2. Supabase Database Credential

#### In N8N:
1. Go to **Credentials** → **Add Credential**
2. Type: **"Postgres"**
3. Name: `Supabase Database`
4. Configure with your Supabase details:
   ```
   Host: db.[your-project-id].supabase.co
   Database: postgres
   User: postgres
   Password: [your-supabase-password]
   Port: 5432
   SSL: Allow
   ```

#### Get Supabase Connection Details:
1. In your Supabase project, go to **Settings** → **Database**
2. Find the **Connection info** section:
   ```
   Host: db.hjxoffkoqjxbvkqsqlfy.supabase.co
   Database name: postgres
   Port: 5432
   User: postgres
   Password: [the password you set during project creation]
   ```

#### Connection String Format:
```
postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT].supabase.co:5432/postgres
```

---

### 3. GoHighLevel API Credential

#### In N8N:
1. Go to **Credentials** → **Add Credential**  
2. Type: **"GoHighLevel API"**
3. Name: `GoHighLevel API`
4. Configure:
   ```
   API Key: [your-ghl-api-key]
   ```

#### Get GoHighLevel API Key:
1. Login to [GoHighLevel](https://app.gohighlevel.com)
2. Go to **Settings** → **Integrations** → **API**
3. Create new API Key or copy existing one
4. **Important**: Make sure it has these permissions:
   - `contacts.write` - To update contact tags
   - `contacts.read` - To read contact information

---

## 🧪 Test Credentials

### Test WebinarJam API
In N8N, create a simple HTTP Request node:
```
Method: POST
URL: https://api.webinarjam.com/everwebinar/registrants
Authentication: Use "WebinarJam API" credential
Body: 
{
  "api_key": "{{$credentials.webinarjam.apiKey}}",
  "webinar_id": "13"
}
```

**Expected Response**: JSON with registrants data

### Test Supabase Connection
In N8N, create a Postgres node:
```
Operation: Execute Query
Query: SELECT NOW() as current_time;
Credentials: Use "Supabase Database" credential
```

**Expected Response**: Current timestamp from database

### Test GoHighLevel API
In N8N, create an HTTP Request node:
```
Method: GET
URL: https://services.leadconnectorhq.com/contacts/
Authentication: Use "GoHighLevel API" credential
Headers: 
  Authorization: Bearer {{$credentials.goHighLevel.apiKey}}
```

**Expected Response**: JSON with contacts data

---

## 🔒 Security Best Practices

### API Key Storage
- ✅ **DO**: Store all keys as N8N credentials (encrypted)
- ❌ **DON'T**: Hardcode API keys in workflow nodes
- ❌ **DON'T**: Share credentials in screenshots or documentation

### Access Control
- **WebinarJam**: Use read-only API key if available
- **Supabase**: Use database user with minimal required permissions
- **GoHighLevel**: Limit API key to only required scopes

### Credential Naming
Use consistent, descriptive names:
- `WebinarJam API` (not "wj-api" or "api-key-1")
- `Supabase Database` (not "db" or "postgres-1")  
- `GoHighLevel API` (not "ghl" or "crm-api")

---

## 🔧 Troubleshooting

### Common Issues

#### WebinarJam "Unauthorized" Error
- **Cause**: Wrong API key or using password field
- **Fix**: Ensure API key is in **Username** field, **Password** is blank

#### Supabase Connection Timeout
- **Cause**: Wrong host, port, or password
- **Fix**: Double-check connection details from Supabase dashboard

#### GoHighLevel "Forbidden" Error  
- **Cause**: API key lacks required permissions
- **Fix**: Update API key permissions in GoHighLevel settings

### Testing Queries

#### Verify Supabase Tables Exist
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('webinar_registrants', 'attendance_checks');
```

#### Check Database Performance
```sql
EXPLAIN ANALYZE 
SELECT * FROM webinar_registrants 
WHERE email = 'test@example.com' LIMIT 1;
```

#### Verify Indexes Are Created
```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'webinar_registrants';
```

---

## 📊 Credential Usage in Workflows

### Lightning Attendee Checker Workflow
- **Supabase Database**: For attendance lookups
- **GoHighLevel API**: For adding/removing tags

### Data Sync Workflow  
- **WebinarJam API**: For fetching registrant data
- **Supabase Database**: For storing/updating data

### Workflow Credential Mapping
```json
{
  "postgres": "Supabase Database",
  "goHighLevelApi": "GoHighLevel API", 
  "httpBasicAuth": "WebinarJam API"
}
```

---

## ✅ Setup Checklist

### Before Importing Workflows
- [ ] WebinarJam API credential created and tested
- [ ] Supabase Database credential created and tested  
- [ ] GoHighLevel API credential created and tested
- [ ] All API keys have required permissions
- [ ] Supabase database schema is deployed
- [ ] Test queries return expected results

### After Importing Workflows
- [ ] All workflow nodes use correct credential names
- [ ] No hardcoded API keys in any nodes
- [ ] Test webhook with sample data
- [ ] Verify tags are applied in GoHighLevel
- [ ] Check data sync runs without errors

---

## 🚀 Ready for Production

Once all credentials are configured and tested:

1. **Import Workflows**: Use the credential names exactly as configured
2. **Activate Workflows**: Start with data sync, then attendee checker
3. **Monitor Performance**: Watch execution logs for any credential errors
4. **Test End-to-End**: Send test webhook and verify complete flow

Your lightning-fast WebinarJam system will be ready to handle thousands of webhooks with sub-second response times!