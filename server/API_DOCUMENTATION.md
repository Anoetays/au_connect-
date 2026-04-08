# AU Connect Backend API Documentation

## Overview

AU Connect backend is a **Node.js + Express server** that provides comprehensive API endpoints for payments, messaging, notifications, file uploads, and application management. The backend integrates with **Supabase** for database and storage, and **Paynow Zimbabwe** for payment processing.

## Table of Contents
- [Setup & Installation](#setup--installation)
- [Environment Configuration](#environment-configuration)
- [API Endpoints](#api-endpoints)
- [Database Schema](#database-schema)
- [Running the Server](#running-the-server)
- [Deployment](#deployment)

---

## Setup & Installation

### Prerequisites
- Node.js 16+ installed
- Supabase project set up (with URL and service key)
- Paynow Zimbabwe merchant account

### Installation Steps

1. **Install dependencies:**
   ```bash
   cd server
   npm install
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your credentials (see [Environment Configuration](#environment-configuration) below)

3. **Ensure Supabase schema is up to date:**
   - Run the SQL from `supabase_setup.sql` in your Supabase SQL Editor
   - This creates tables for conversations, messages, notifications, applications, etc.

---

## Environment Configuration

Create a `.env` file in the `server/` directory with the following variables:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Paynow Zimbabwe
PAYNOW_INTEGRATION_ID=your_integration_id
PAYNOW_INTEGRATION_KEY=your_integration_key
PAYNOW_MERCHANT_EMAIL=your_merchant_email
PAYNOW_RESULT_URL=https://yourdomain.com/paynow/result
PAYNOW_RETURN_URL=https://yourdomain.com/paynow/return

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
```

**Important:** Use the **Service Role Key** (not the anon key) for backend authentication.

---

## API Endpoints

### 1. Payments

#### POST `/api/pay` — Initiate EcoCash Payment
Initiates an EcoCash mobile payment via Paynow.

**Request:**
```json
{
  "phone": "+263771234567",
  "amount": 50.00,
  "email": "user@example.com",
  "reference": "PAYMENT_REF_12345"
}
```

**Response:**
```json
{
  "success": true,
  "pollUrl": "https://www.paynow.co.zw/..."
}
```

#### GET `/api/poll?url=<pollUrl>` — Check Payment Status
Polls Paynow for transaction status.

**Response:**
```json
{
  "success": true,
  "paid": true,
  "status": "Paid"
}
```

---

### 2. Messaging

#### GET `/api/conversations?participant_id=<userId>`
Get all conversations for a user.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "participant1_id": "uuid",
      "participant2_id": "uuid",
      "updated_at": "2024-04-05T10:00:00Z"
    }
  ]
}
```

#### POST `/api/conversations`
Create a new conversation.

**Request:**
```json
{
  "participant1_id": "uuid",
  "participant2_id": "uuid"
}
```

#### POST `/api/messages/send`
Send a message.

**Request:**
```json
{
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "recipient_id": "uuid",
  "content": "Hello!",
  "type": "text"
}
```

**Optional fields:** `file_url`, `file_name` (for file messages)

#### GET `/api/messages/:messageId/read`
Mark a specific message as read.

#### POST `/api/conversations/:conversationId/mark-read`
Mark all messages in a conversation as read.

---

### 3. File Upload

#### POST `/api/files/upload`
Upload a file to Supabase Storage.

**Parameters:**
- `folder` (query): Storage folder name (default: `documents`)

**Form Data:**
```
Content-Type: multipart/form-data
file: <binary file>
```

**Response:**
```json
{
  "success": true,
  "file": {
    "name": "document.pdf",
    "path": "documents/1712311200000-document.pdf",
    "url": "https://..../documents/1712311200000-document.pdf",
    "size": 102400
  }
}
```

---

### 4. Notifications

#### GET `/api/notifications?user_id=<userId>`
Get notifications for a user or all admin notifications if `user_id=all_admins`.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "recipient_id": "uuid",
      "type": "status_update",
      "title": "Application Status Updated",
      "body": "Your application has been reviewed.",
      "is_read": false,
      "created_at": "2024-04-05T10:00:00Z"
    }
  ]
}
```

#### POST `/api/notifications/send`
Send a notification.

**Request:**
```json
{
  "recipient_id": "uuid",
  "recipient_role": "applicant",
  "type": "status_update",
  "title": "Application Status Updated",
  "body": "Your application has been reviewed.",
  "metadata": { "application_id": "..." }
}
```

#### POST `/api/notifications/:id/read`
Mark a notification as read.

#### DELETE `/api/notifications/:id`
Delete a notification.

---

### 5. Applications (Admin)

#### GET `/api/applications/:userId`
Get applications for a specific user.

#### POST `/api/applications/update-status`
Update application status and send notification to applicant.

**Headers:**
```
x-admin-id: <admin_user_id>
```

**Request:**
```json
{
  "application_id": "uuid",
  "status": "Approved",
  "notes": "Application has been approved."
}
```

**Response:**
```json
{
  "success": true,
  "data": { ... }
}
```

---

### 6. Health Check

#### GET `/api/health`
Check if the backend is running.

**Response:**
```json
{
  "success": true,
  "status": "Backend is running",
  "timestamp": "2024-04-05T10:00:00.000Z"
}
```

---

## Database Schema

The backend uses the following Supabase tables:

| Table | Purpose |
|-------|---------|
| `conversations` | Stores conversation metadata between two users |
| `messages` | Stores individual messages with timestamps and read status |
| `notifications` | Stores notifications for users and admins |
| `applications` | Stores user applications (with RLS policies) |
| `documents` | Stores uploaded documents |
| `payments` | Stores payment records |
| `profiles` | User profiles with roles |

All tables have **Row Level Security (RLS)** enabled with appropriate policies.

---

## Running the Server

### Development Mode
```bash
cd server
npm run dev
```

This starts the server with `nodemon`, which auto-reloads on file changes.

### Production Mode
```bash
cd server
npm start
```

The server will run on the port specified in `.env` (default: `3000`).

### Verify the Server is Running
```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{
  "success": true,
  "status": "Backend is running",
  "timestamp": "2024-04-05T10:00:00.000Z"
}
```

---

## Deployment

### Option 1: Deploy to Heroku

1. **Create a Heroku app:**
   ```bash
   heroku create au-connect-backend
   ```

2. **Set environment variables:**
   ```bash
   heroku config:set PAYNOW_INTEGRATION_ID=xxx
   heroku config:set PAYNOW_INTEGRATION_KEY=xxx
   # ... set all other variables
   ```

3. **Deploy:**
   ```bash
   git push heroku main
   ```

### Option 2: Deploy to Vercel

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Deploy:**
   ```bash
   vercel
   ```

3. **Configure environment variables in Vercel dashboard**

### Option 3: Docker

Create `Dockerfile` in `server/`:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t au-connect-backend .
docker run -p 3000:3000 --env-file .env au-connect-backend
```

---

## Development Notes

### CORS Configuration
The server allows requests from any origin (CORS enabled). For production, restrict to your frontend domain:

```javascript
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
```

### File Upload Storage
Files are uploaded to Supabase Storage under the `uploads` bucket. Ensure the bucket exists and has public access configured.

### Error Handling
All endpoints return consistent JSON responses:
- **Success:** `{ success: true, data: {...} }`
- **Error:** `{ success: false, error: "error message" }`

---

## Troubleshooting

### 42501: Permission Denied on Supabase
If you see "permission denied for table profiles", add RLS grants:
```sql
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
```

### File Upload Fails
- Ensure Supabase `uploads` bucket exists
- Check bucket is set to public
- Verify SUPABASE_SERVICE_KEY has write permissions

### Environment Variables Not Loading
- Verify `.env` file is in `server/` directory
- Ensure `dotenv` is required at the top of `server.js`
- Restart the server after changing `.env`

---

## Support & Contribution

For issues or improvements, contact the development team or submit a pull request.
