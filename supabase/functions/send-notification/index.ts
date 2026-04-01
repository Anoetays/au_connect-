// supabase/functions/send-notification/index.ts
// Triggered by a Supabase Database Webhook on INSERT to:
//   - applications (status change)
//   - documents (verification update)
//
// Required secrets (set via `supabase secrets set`):
//   RESEND_API_KEY      - Resend email API key
//   AT_API_KEY          - Africa's Talking API key
//   AT_USERNAME         - Africa's Talking username
//   SUPABASE_URL        - auto-provided by runtime
//   SUPABASE_SERVICE_ROLE_KEY - auto-provided by runtime

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const AT_API_KEY     = Deno.env.get("AT_API_KEY")     ?? "";
const AT_USERNAME    = Deno.env.get("AT_USERNAME")    ?? "sandbox";
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")   ?? "";
const SUPABASE_KEY   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const db = createClient(SUPABASE_URL, SUPABASE_KEY);

// ── helpers ────────────────────────────────────────────────────────────────────

async function sendEmail(to: string, subject: string, html: string) {
  if (!RESEND_API_KEY) return;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: "AU Connect <noreply@africauniversity.ac.zw>",
      to: [to],
      subject,
      html,
    }),
  });
  if (!res.ok) {
    console.error("Resend error:", await res.text());
  }
}

async function sendSMS(phone: string, message: string) {
  if (!AT_API_KEY || !phone) return;
  const body = new URLSearchParams({
    username: AT_USERNAME,
    to: phone,
    message: message.slice(0, 160), // SMS limit
    from: "AUConnect",
  });
  const res = await fetch(
    "https://api.africastalking.com/version1/messaging",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "apiKey": AT_API_KEY,
        "Accept": "application/json",
      },
      body: body.toString(),
    }
  );
  if (!res.ok) {
    console.error("AT SMS error:", await res.text());
  }
}

// ── email templates ────────────────────────────────────────────────────────────

function statusChangedEmail(applicantName: string, status: string): string {
  const statusColors: Record<string, string> = {
    Approved: "#22C55E",
    Rejected: "#EF4444",
    "Under Review": "#3B82F6",
    Pending: "#F97316",
  };
  const color = statusColors[status] ?? "#B91C1C";
  return `
    <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <div style="background:#7F1D1D;padding:24px;border-radius:12px 12px 0 0">
        <h1 style="color:#fff;margin:0;font-size:22px">AU Connect</h1>
        <p style="color:rgba(255,255,255,.7);margin:4px 0 0;font-size:13px">Africa University Admissions Portal</p>
      </div>
      <div style="border:1px solid #F1F5F9;border-top:none;padding:32px;border-radius:0 0 12px 12px">
        <p style="color:#0F172A;font-size:15px">Dear <strong>${applicantName}</strong>,</p>
        <p style="color:#475569;font-size:14px;line-height:1.6">
          Your application status has been updated.
        </p>
        <div style="background:#F8FAFC;border:1px solid #F1F5F9;border-radius:8px;padding:20px;margin:20px 0;text-align:center">
          <p style="color:#94A3B8;font-size:12px;margin:0 0 8px;text-transform:uppercase;letter-spacing:1px">Current Status</p>
          <span style="background:${color}22;color:${color};border:1px solid ${color}44;padding:8px 20px;border-radius:20px;font-size:15px;font-weight:700">${status}</span>
        </div>
        ${status === "Approved" ? `
        <p style="color:#475569;font-size:14px">
          Congratulations! Please log in to your AU Connect portal to download your offer letter and complete enrolment.
        </p>` : ""}
        ${status === "Rejected" ? `
        <p style="color:#475569;font-size:14px">
          We regret to inform you that your application was unsuccessful at this time. You may contact our admissions office for further guidance.
        </p>` : ""}
        <a href="https://au-connect.web.app" style="display:inline-block;background:#B91C1C;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:700;margin-top:8px">
          View Application
        </a>
        <hr style="border:none;border-top:1px solid #F1F5F9;margin:28px 0">
        <p style="color:#94A3B8;font-size:12px">© 2026 Africa University · Mutare, Zimbabwe</p>
      </div>
    </div>`;
}

function documentStatusEmail(applicantName: string, docType: string, status: string, note?: string): string {
  return `
    <div style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <div style="background:#7F1D1D;padding:24px;border-radius:12px 12px 0 0">
        <h1 style="color:#fff;margin:0;font-size:22px">AU Connect</h1>
      </div>
      <div style="border:1px solid #F1F5F9;border-top:none;padding:32px;border-radius:0 0 12px 12px">
        <p style="color:#0F172A;font-size:15px">Dear <strong>${applicantName}</strong>,</p>
        <p style="color:#475569;font-size:14px;line-height:1.6">
          Your document <strong>${docType}</strong> has been <strong>${status.toLowerCase()}</strong>.
        </p>
        ${note ? `
        <div style="background:#FEF2F2;border:1px solid #FECACA;border-radius:8px;padding:16px;margin:16px 0">
          <p style="color:#B91C1C;font-size:13px;margin:0"><strong>Reason:</strong> ${note}</p>
        </div>
        <p style="color:#475569;font-size:14px">Please log in to re-upload a corrected version.</p>
        ` : ""}
        <a href="https://au-connect.web.app" style="display:inline-block;background:#B91C1C;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:700;margin-top:8px">
          View Documents
        </a>
        <hr style="border:none;border-top:1px solid #F1F5F9;margin:28px 0">
        <p style="color:#94A3B8;font-size:12px">© 2026 Africa University · Mutare, Zimbabwe</p>
      </div>
    </div>`;
}

// ── main handler ───────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    const payload = await req.json();
    const { type, table, record, old_record } = payload;

    if (table === "applications" && type === "UPDATE") {
      const newStatus = record?.status as string | undefined;
      const oldStatus = old_record?.status as string | undefined;
      if (!newStatus || newStatus === oldStatus) {
        return new Response(JSON.stringify({ skipped: "no status change" }), { status: 200 });
      }

      // Fetch applicant profile for email + phone
      const userId = record.user_id as string | undefined;
      if (!userId) return new Response(JSON.stringify({ ok: true }), { status: 200 });

      const { data: profile } = await db
        .from("profiles")
        .select("full_name, email, phone")
        .eq("user_id", userId)
        .maybeSingle();

      const name  = profile?.full_name  ?? "Applicant";
      const email = profile?.email      ?? record.email ?? "";
      const phone = profile?.phone      ?? "";

      if (email) {
        await sendEmail(
          email,
          `Your application status has changed — ${newStatus}`,
          statusChangedEmail(name, newStatus)
        );
      }

      const smsMsg = `AU Connect: Your application status is now "${newStatus}". Log in at au-connect.web.app`;
      if (phone) await sendSMS(phone, smsMsg);
    }

    if (table === "documents" && type === "UPDATE") {
      const newVStatus = record?.verification_status as string | undefined;
      const oldVStatus = old_record?.verification_status as string | undefined;
      if (!newVStatus || newVStatus === oldVStatus) {
        return new Response(JSON.stringify({ skipped: "no verification change" }), { status: 200 });
      }

      const userId = record.user_id as string | undefined;
      if (!userId) return new Response(JSON.stringify({ ok: true }), { status: 200 });

      const { data: profile } = await db
        .from("profiles")
        .select("full_name, email, phone")
        .eq("user_id", userId)
        .maybeSingle();

      const name    = profile?.full_name  ?? "Applicant";
      const email   = profile?.email      ?? "";
      const phone   = profile?.phone      ?? "";
      const docType = record.document_type as string ?? record.file_name ?? "Document";
      const note    = record.verification_note as string | undefined;

      if (email) {
        await sendEmail(
          email,
          `Document ${newVStatus}: ${docType}`,
          documentStatusEmail(name, docType, newVStatus, note)
        );
      }

      const smsMsg = newVStatus === "Rejected"
        ? `AU Connect: Your document "${docType}" was rejected. Reason: ${note ?? "See portal"}. Please re-upload.`
        : `AU Connect: Your document "${docType}" has been verified. Log in at au-connect.web.app`;
      if (phone) await sendSMS(phone, smsMsg);
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("send-notification error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
