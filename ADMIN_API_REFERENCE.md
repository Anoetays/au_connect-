# Admin API Reference

## Base URL
```
http://localhost:3000/api/admin
```

## Authentication
All endpoints use Supabase service role (backend server). No additional auth needed from Flutter app - backend handles authentication.

---

## Endpoints

### 1. GET `/admin/dashboard`

Get aggregated statistics for the admin dashboard.

**Query Parameters**: None

**Response**:
```json
{
  "success": true,
  "data": {
    "totalApplications": 156,
    "statusBreakdown": {
      "pending": 45,
      "review": 28,
      "approved": 79,
      "rejected": 4
    },
    "byProgramme": {
      "Engineering": 52,
      "Medicine": 38,
      "Business": 35,
      "Law": 18,
      "Science": 13
    },
    "byNationality": {
      "Zimbabwe": 120,
      "South Africa": 18,
      "Nigeria": 8,
      "Kenya": 5,
      "Botswana": 3,
      "other": 2
    },
    "recentApplications": [
      {
        "id": 1,
        "applicant_name": "John Doe",
        "programme": "Engineering",
        "status": "pending",
        "submitted_at": "2026-04-05T10:30:00Z"
      }
    ]
  }
}
```

**Error Responses**:
```json
{ "success": false, "error": "permission denied for table applications" }
```

**Example**:
```bash
curl http://localhost:3000/api/admin/dashboard
```

---

### 2. GET `/admin/applications`

Get paginated list of all applications with optional filtering.

**Query Parameters**:
- `offset` (number, default: 0) - Pagination offset
- `limit` (number, default: 20) - Items per page
- `status` (string, optional) - Filter by status (pending, review, approved, rejected)
- `programme` (string, optional) - Filter by programme name

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "applicant_name": "John Doe",
      "programme": "Engineering",
      "status": "pending",
      "type": "Local",
      "nationality": "Zimbabwe",
      "submitted_at": "2026-04-05T10:30:00Z",
      "created_at": "2026-04-05T09:15:00Z"
    }
  ],
  "pagination": {
    "offset": 0,
    "limit": 20,
    "total": 156
  }
}
```

**Example**:
```bash
# Get first 20
curl http://localhost:3000/api/admin/applications?offset=0&limit=20

# Get pending only, second page
curl http://localhost:3000/api/admin/applications?offset=20&limit=20&status=pending

# Get Engineering programme applications
curl http://localhost:3000/api/admin/applications?programme=Engineering
```

---

### 3. GET `/admin/applications/:appId`

Get detailed view of a single application with all documents.

**URL Parameters**:
- `appId` (number, required) - Application ID

**Response**:
```json
{
  "success": true,
  "data": {
    "application": {
      "id": 1,
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "applicant_name": "John Doe",
      "programme": "Engineering",
      "type": "Local",
      "status": "pending",
      "nationality": "Zimbabwe",
      "submitted_at": "2026-04-05T10:30:00Z",
      "created_at": "2026-04-05T09:15:00Z"
    },
    "documents": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "file_name": "passport.pdf",
        "document_type": "Passport",
        "verification_status": "Pending",
        "reviewed_by": null,
        "uploaded_at": "2026-04-05T10:35:00Z"
      }
    ]
  }
}
```

**Example**:
```bash
curl http://localhost:3000/api/admin/applications/1
```

---

### 4. POST `/admin/applications/:appId/review`

Update application status and create admin action log.

**URL Parameters**:
- `appId` (number, required) - Application ID

**Request Body**:
```json
{
  "status": "approved",
  "reviewNotes": "All documents verified successfully",
  "reviewedBy": "admin@university.edu"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "applicant_name": "John Doe",
    "status": "approved",
    "updated_at": "2026-04-06T14:20:00Z"
  }
}
```

**Notes**:
- Automatically sends notification to applicant
- Creates entry in `admin_actions` table
- Status options: `pending`, `review`, `approved`, `rejected`

**Example**:
```bash
curl -X POST http://localhost:3000/api/admin/applications/1/review \
  -H "Content-Type: application/json" \
  -d '{
    "status": "approved",
    "reviewNotes": "Ready to proceed",
    "reviewedBy": "admin@university.edu"
  }'
```

---

### 5. POST `/admin/documents/:docId/verify`

Verify or reject document.

**URL Parameters**:
- `docId` (string, required) - Document UUID

**Request Body**:
```json
{
  "status": "verified",
  "verificationNotes": "Document authentic and valid",
  "verifiedBy": "admin@university.edu"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "660e8400-...",
    "file_name": "passport.pdf",
    "verification_status": "verified",
    "reviewed_by": "admin@university.edu"
  }
}
```

**Status Options**: `verified`, `rejected`, `pending`, `needs_resubmission`

**Example**:
```bash
curl -X POST http://localhost:3000/api/admin/documents/660e8400-e29b-41d4-a716-446655440001/verify \
  -H "Content-Type: application/json" \
  -d '{
    "status": "verified",
    "verificationNotes": "Passport is valid",
    "verifiedBy": "john.admin@uni.edu"
  }'
```

---

### 6. POST `/admin/notifications/bulk`

Send bulk notifications to admins or filtered applicants.

**Request Body** (for admin recipients):
```json
{
  "recipient_role": "admin",
  "type": "announcement",
  "title": "New Applications Received",
  "body": "5 new applications submitted today"
}
```

**Request Body** (for filtered applicants):
```json
{
  "recipient_role": "applicant",
  "type": "status_update",
  "title": "Application Status Update",
  "body": "Your application has been approved!",
  "filters": {
    "status": "approved",
    "programme": "Engineering"
  }
}
```

**Response**:
```json
{
  "success": true,
  "sent": 23
}
```

**Notes**:
- `recipient_role`: `admin` or `applicant`
- `type`: `announcement`, `status_update`, `deadline`, `reminder`, etc
- `filters` (optional): Applied only when `recipient_role` is `applicant`
  - `status`: pending, review, approved, rejected
  - `programme`: programme name

**Example**:
```bash
curl -X POST http://localhost:3000/api/admin/notifications/bulk \
  -H "Content-Type: application/json" \
  -d '{
    "recipient_role": "applicant",
    "type": "announcement",
    "title": "Important Update",
    "body": "Portal maintenance scheduled",
    "filters": {
      "status": "approved"
    }
  }'
```

---

### 7. GET `/admin/reports/export`

Export applications data as JSON or CSV.

**Query Parameters**:
- `format` (string, required) - `json` or `csv`
- `status` (string, optional) - Filter by status
- `programme` (string, optional) - Filter by programme

**Response (JSON format)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "applicant_name": "John Doe",
      "programme": "Engineering",
      "status": "approved",
      "nationality": "Zimbabwe",
      "submitted_at": "2026-04-05T10:30:00Z"
    }
  ],
  "count": 1
}
```

**Response (CSV format)**: Plain text CSV file
```
id,applicant_name,programme,status,nationality,submitted_at,type,created_at
1,John Doe,Engineering,approved,Zimbabwe,2026-04-05T10:30:00Z,Local,2026-04-05T09:15:00Z
2,Jane Smith,Medicine,pending,South Africa,2026-04-06T11:20:00Z,International,2026-04-06T10:05:00Z
```

**Headers (CSV)**:
- `Content-Type: text/csv`
- `Content-Disposition: attachment; filename="applications_export.csv"`

**Example**:
```bash
# Export as JSON
curl 'http://localhost:3000/api/admin/reports/export?format=json&status=approved'

# Export as CSV
curl 'http://localhost:3000/api/admin/reports/export?format=csv' > applications.csv

# Export specific programme
curl 'http://localhost:3000/api/admin/reports/export?format=csv&programme=Engineering' > engineering_apps.csv
```

---

## Error Responses

All endpoints follow this error format:

```json
{
  "success": false,
  "error": "Description of what went wrong"
}
```

**Common Errors**:

| Status | Message | Cause |
|--------|---------|-------|
| 400 | Missing required fields | Invalid request body |
| 400 | Invalid UUID format | Wrong parameter type |
| 404 | Application not found | appId doesn't exist |
| 500 | permission denied for table | RLS not disabled in Supabase |
| 500 | Unknown error | Backend server error (check logs) |

---

## Rate Limiting

No built-in rate limiting. Consider adding in production:
- 100 requests per minute per IP
- 50 bulk notifications per day per admin
- 10 exports per day per user

---

## Best Practices

1. **Pagination**: Always use `offset` and `limit` for large datasets
   ```
   Page 1: offset=0&limit=20
   Page 2: offset=20&limit=20
   Page 3: offset=40&limit=20
   ```

2. **Exports**: For large exports (100k+ records), consider streaming or chunking

3. **Bulk Notifications**: Batch similar notifications, don't send 1000 individual requests

4. **Polling Dashboard**: Cache stats client-side, refresh every 30+ seconds

5. **Admin Logs**: Check `admin_actions` table to audit all admin activities
   ```sql
   SELECT * FROM admin_actions 
   WHERE admin_id = 'admin@email.com' 
   ORDER BY created_at DESC;
   ```

---

## Testing

**Health Check**:
```bash
curl http://localhost:3000/api/health
```

**Full Dashboard Test**:
```powershell
$response = Invoke-WebRequest -Uri 'http://localhost:3000/api/admin/dashboard' -UseBasicParsing
$response.Content | ConvertFrom-Json
```

**Timestamp Format**: All timestamps are ISO 8601 UTC
```
2026-04-06T14:30:45.123Z
```
