# 📡 GoHighLevel Webhook Data Specification

## Overview
This document specifies the exact data format and structure required for the GoHighLevel webhook integration with the WebinarJam attendance checker system.

---

## 🎯 Webhook Purpose

The webhook is triggered **3 hours after a webinar ends** to automatically check attendance status and apply appropriate tags to contacts in GoHighLevel.

---

## 📊 Webhook Data Structure

### Required HTTP Headers
```http
Content-Type: application/json
User-Agent: GoHighLevel-Webhook/1.0
X-Webhook-Event: attendance-check
```

### Required JSON Payload Structure
```json
{
  "first_name": "{{contact.first_name}}",
  "email": "{{contact.email}}",
  "phone": "{{contact.phone}}",
  "contact_id": "{{contact.id}}",
  "selected_label": "{{contact.wjschedule}}",
  "webinar_date": "{{contact.webinar_date}}",
  "webinar_id": 13,
  "schedule_id": "{{contact.webinar_schedule_id}}"
}
```

---

## 🔧 Field Specifications

### Core Required Fields

#### `email` (String, Required)
- **Purpose**: Primary identifier for attendance lookup
- **Format**: Valid email address
- **Example**: `"john.doe@example.com"`
- **Validation**: Must be lowercase, trimmed of whitespace
- **Used For**: Database lookup in `webinar_registrants.email`

#### `contact_id` (String, Required)
- **Purpose**: GoHighLevel contact identifier for tagging
- **Format**: Alphanumeric string
- **Example**: `"contact_12345abc"`
- **Used For**: GoHighLevel API calls to add/remove tags

#### `webinar_id` (Integer, Required)
- **Purpose**: WebinarJam webinar identifier
- **Format**: Integer
- **Example**: `13`
- **Used For**: Database lookup to find correct webinar registrants

#### `schedule_id` (String/Integer, Required)
- **Purpose**: WebinarJam schedule identifier
- **Format**: String or Integer
- **Example**: `"46"` or `46`
- **Used For**: Database lookup to find correct schedule

### Additional Contact Fields

#### `first_name` (String, Optional)
- **Purpose**: Contact's first name for personalization
- **Format**: String
- **Example**: `"John"`
- **Used For**: Logging and response data

#### `phone` (String, Optional)
- **Purpose**: Contact's phone number
- **Format**: String with country code
- **Example**: `"+1234567890"`
- **Used For**: Additional contact verification

#### `selected_label` (String, Optional)
- **Purpose**: WebinarJam schedule label/name
- **Format**: String
- **Example**: `"Evening Session"`
- **Used For**: Human-readable schedule identification

#### `webinar_date` (String, Optional)
- **Purpose**: Date/time of the webinar
- **Format**: ISO 8601 timestamp or date string
- **Example**: `"2024-01-15T18:00:00.000Z"`
- **Used For**: Event verification and logging

### Optional Enhancement Fields

#### `timestamp` (String, Optional)
- **Purpose**: When the webhook was triggered
- **Format**: ISO 8601 UTC timestamp
- **Example**: `"2024-01-15T21:30:00.000Z"`
- **Default**: Current timestamp if not provided

#### `event_type` (String, Optional)
- **Purpose**: Identifies the webhook event type
- **Format**: String constant
- **Example**: `"attendance_check"`
- **Default**: `"attendance_check"`

#### `webinar_info` (Object, Optional)
- **Purpose**: Explicit webinar identification
- **Fields**:
  - `webinar_id` (Integer): WebinarJam webinar ID
  - `schedule_id` (Integer): WebinarJam schedule ID  
  - `webinar_name` (String): Human-readable webinar name

---

## 🎯 Webinar Identification Logic

The system uses a **smart fallback approach** to identify which webinar to check attendance for:

### 1. Explicit Webinar Info (Preferred)
```json
{
  "webinar_info": {
    "webinar_id": 13,
    "schedule_id": 46
  }
}
```

### 2. Tag-Based Detection (Fallback)
If webinar_info is not provided, the system scans `body.tags` for patterns:

```javascript
// Tag scanning patterns
const webinarMatch = tag.match(/webinar[_-]?(\d+)/i);
const scheduleMatch = tag.match(/schedule[_-]?(\d+)/i);

// Example matching tags:
"webinar-13"      → webinar_id: 13
"webinar_13"      → webinar_id: 13  
"schedule-46"     → schedule_id: 46
"schedule_46"     → schedule_id: 46
```

### 3. Default Values (Last Resort)
```javascript
const defaults = {
  webinar_id: 13,    // Default webinar
  schedule_id: null  // No schedule restriction
};
```

---

## ✅ Valid Webhook Examples

### Minimal Required Data
```json
{
  "email": "sarah.johnson@company.com",
  "contact_id": "contact_abc123",
  "webinar_id": 13,
  "schedule_id": "46"
}
```

### Complete Data with All Fields
```json
{
  "first_name": "Mike",
  "email": "mike.smith@startup.io",
  "phone": "+1234567890",
  "contact_id": "contact_xyz789",
  "selected_label": "Evening Session",
  "webinar_date": "2024-02-20T19:00:00.000Z",
  "webinar_id": 13,
  "schedule_id": "46"
}
```

### Production Example
```json
{
  "first_name": "Lisa",
  "email": "lisa.wong@agency.com",
  "phone": "+31612345678",
  "contact_id": "contact_def456",
  "selected_label": "Advanced Marketing Masterclass",
  "webinar_date": "2024-02-20T20:00:00.000Z",
  "webinar_id": 13,
  "schedule_id": "46"
}
```

---

## ❌ Common Data Issues & Solutions

### Issue: Missing Required Fields
```json
// ❌ INVALID - Missing contact_id
{
  "body": {
    "email": "test@example.com"
  }
}

// ✅ FIXED
{
  "body": {
    "email": "test@example.com",
    "contact_id": "contact_12345"
  }
}
```

### Issue: Incorrect Email Format
```json
// ❌ INVALID - Malformed email
{
  "body": {
    "email": "not-an-email",
    "contact_id": "contact_12345"
  }
}

// ✅ FIXED  
{
  "body": {
    "email": "valid@example.com",
    "contact_id": "contact_12345"
  }
}
```

### Issue: Wrong Data Types
```json
// ❌ INVALID - contact_id should be string
{
  "body": {
    "email": "test@example.com",
    "contact_id": 12345
  }
}

// ✅ FIXED
{
  "body": {
    "email": "test@example.com", 
    "contact_id": "12345"
  }
}
```

---

## 🔍 Response Specification

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "✅ Contact successfully tagged as 'attended'",
  "contact": {
    "email": "test@example.com",
    "ghl_contact_id": "contact_12345",
    "first_name": "John",
    "last_name": "Doe"
  },
  "webinar": {
    "name": "Sales Masterclass 2024",
    "webinar_id": 13,
    "schedule_id": 46,
    "event_date": "2024-01-15T18:00:00.000Z"
  },
  "attendance": {
    "status": "attended",
    "attended_live": true,
    "date_live": "2024-01-15T18:15:00.000Z",
    "time_live": "01:45:30",
    "purchased": true,
    "revenue": 297.00
  },
  "tagging": {
    "tag_added": "Attended Webinar",
    "tag_removed": "No Show Webinar", 
    "action_completed": true
  },
  "performance": {
    "total_time_ms": 245,
    "database_query_ms": 12,
    "api_calls_completed": 2,
    "status": "🚀 Lightning Fast"
  },
  "tracking": {
    "check_id": 1847,
    "processed_at": "2024-01-15T21:30:15.123Z",
    "registrant_id": 9284
  }
}
```

### Contact Not Found Response (200 OK)
```json
{
  "success": false,
  "message": "❌ Contact 'test@example.com' not found in webinar registrants",
  "contact": {
    "email": "test@example.com",
    "ghl_contact_id": "contact_12345"
  },
  "search_criteria": {
    "webinar_id": 13,
    "schedule_id": 46
  },
  "tagging": {
    "tag_added": "Not Found - Manual Review",
    "reason": "Contact not found in WebinarJam registrants database",
    "action_completed": true
  },
  "performance": {
    "total_time_ms": 89,
    "status": "⚡ Fast (No Match)"
  },
  "tracking": {
    "check_id": 1848,
    "processed_at": "2024-01-15T21:30:15.456Z"
  },
  "recommendations": [
    "Check if contact registered with different email address",
    "Verify webinar_id and schedule_id are correct", 
    "Ensure WebinarJam sync is up to date",
    "Review contact manually in WebinarJam dashboard"
  ]
}
```

### Error Response (400 Bad Request)
```json
{
  "error": {
    "code": "MISSING_REQUIRED_FIELD",
    "message": "❌ No email found in webhook data",
    "field": "body.email",
    "received_data": {
      "body": {
        "contact_id": "contact_12345"
      }
    }
  }
}
```

---

## 🧪 Testing Webhooks

### Test with cURL
```bash
# Basic attendance check test
curl -X POST "https://your-n8n-url/webhook/ghl-webhook-attendance" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "email": "test@example.com",
      "contact_id": "test_contact_123"
    }
  }'
```

### Test with Complete Data
```bash
curl -X POST "https://your-n8n-url/webhook/ghl-webhook-attendance" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "email": "sarah.johnson@company.com",
      "contact_id": "contact_abc123",
      "tags": ["webinar-registered", "high-value-lead"]
    },
    "timestamp": "2024-01-15T21:30:00.000Z",
    "webinar_info": {
      "webinar_id": 13,
      "schedule_id": 46,
      "webinar_name": "Sales Masterclass 2024"
    }
  }'
```

### Expected Performance
- **Response Time**: < 1000ms (typically 200-500ms)
- **Success Rate**: > 99%
- **Database Query**: < 50ms
- **Memory Usage**: < 100MB per request

---

## 🔧 GoHighLevel Workflow Setup

### Webhook Configuration Steps

1. **Create Workflow in GoHighLevel**
   - Trigger: "3 hours after webinar ends"
   - Action: Send webhook

2. **Configure Webhook URL**
   ```
   POST https://your-n8n-domain.com/webhook/ghl-webhook-attendance
   ```

3. **Set Request Headers**
   ```
   Content-Type: application/json
   ```

4. **Configure Request Body**
   ```json
   {
     "first_name": "{{contact.first_name}}",
     "email": "{{contact.email}}",
     "phone": "{{contact.phone}}",
     "contact_id": "{{contact.id}}",
     "selected_label": "{{contact.wjschedule}}",
     "webinar_date": "{{contact.webinar_date}}",
     "webinar_id": 13,
     "schedule_id": "{{contact.webinar_schedule_id}}"
   }
   ```

### GoHighLevel Variable Mapping
| GHL Variable | Webhook Field | Purpose |
|--------------|---------------|---------|
| `{{contact.first_name}}` | `first_name` | Contact personalization |
| `{{contact.email}}` | `email` | Attendance lookup |
| `{{contact.phone}}` | `phone` | Contact verification |
| `{{contact.id}}` | `contact_id` | Tagging operations |
| `{{contact.wjschedule}}` | `selected_label` | Schedule identification |
| `{{contact.webinar_date}}` | `webinar_date` | Event verification |
| `{{contact.webinar_schedule_id}}` | `schedule_id` | Database lookup |
| `13` (hardcoded) | `webinar_id` | Webinar identification |

---

## 📋 Validation Checklist

### Pre-Production Testing
- [ ] Test with minimal required data
- [ ] Test with complete data payload
- [ ] Test with malformed email addresses
- [ ] Test with missing contact_id
- [ ] Test with various tag patterns
- [ ] Test with explicit webinar_info
- [ ] Verify response format matches specification
- [ ] Confirm performance meets < 1000ms requirement
- [ ] Test error handling for invalid data

### Production Monitoring
- [ ] Monitor webhook success rate (target: >99%)
- [ ] Track response times (target: <1000ms)
- [ ] Alert on validation failures
- [ ] Log all webhook attempts for debugging
- [ ] Monitor tag application success in GoHighLevel

---

## 🎯 Performance Optimization

### Webhook Optimization Tips
- **Batch Processing**: Send webhooks in small batches vs individual
- **Retry Logic**: Implement exponential backoff for failures
- **Timeout Handling**: Set reasonable timeout limits (10-30 seconds)
- **Data Validation**: Validate data before sending webhook
- **Error Logging**: Log failed webhooks for manual review

### Expected Performance Metrics
```
🚀 WEBHOOK PERFORMANCE TARGETS
⚡ Response Time: < 1000ms average
🎯 Success Rate: > 99%  
📊 Throughput: 1000+ webhooks/hour
💾 Memory Usage: < 100MB per request
🔄 Database Query: < 50ms
```

---

This specification ensures reliable, fast, and accurate attendance checking through properly formatted webhook data and comprehensive error handling.