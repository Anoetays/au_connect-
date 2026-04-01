# Supabase Feature Deployment Guide

## 1. Run the SQL migration

In the Supabase Dashboard → SQL Editor, paste and run:
```
supabase/migrations/20260329_features.sql
```

Or via CLI:
```bash
supabase db push
```

---

## 2. Set Edge Function secrets

```bash
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxx
supabase secrets set AT_API_KEY=your_africastalking_api_key
supabase secrets set AT_USERNAME=your_africastalking_username
```

Get a free Resend API key at https://resend.com
Get Africa's Talking credentials at https://africastalking.com

---

## 3. Deploy Edge Functions

```bash
supabase functions deploy send-notification
supabase functions deploy generate-offer-letter
```

---

## 4. Create Database Webhooks

In Supabase Dashboard → Database → Webhooks → Create new webhook:

### Webhook A — Status Changed / Offer Letter
- **Name:** `on_application_update`
- **Table:** `applications`
- **Events:** `UPDATE`
- **URL:** `https://<your-project-ref>.supabase.co/functions/v1/send-notification`
- **Headers:** `Authorization: Bearer <SUPABASE_ANON_KEY>`

Create a second webhook pointing to `generate-offer-letter`:
- **Name:** `on_application_approved`
- **Table:** `applications`
- **Events:** `UPDATE`
- **URL:** `https://<your-project-ref>.supabase.co/functions/v1/generate-offer-letter`
- **Headers:** `Authorization: Bearer <SUPABASE_ANON_KEY>`

### Webhook B — Document Verified/Rejected
- **Name:** `on_document_update`
- **Table:** `documents`
- **Events:** `UPDATE`
- **URL:** `https://<your-project-ref>.supabase.co/functions/v1/send-notification`
- **Headers:** `Authorization: Bearer <SUPABASE_ANON_KEY>`

---

## 5. Verify

- Change an application status in the admin dashboard → applicant should receive email + SMS
- Verify/reject a document → applicant badge updates in real time + email sent
- Approve an application → offer letter PDF auto-generated, download button appears on applicant dashboard
