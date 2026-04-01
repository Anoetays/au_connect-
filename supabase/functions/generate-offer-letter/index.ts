// supabase/functions/generate-offer-letter/index.ts
// Triggered when applications.status is set to 'Approved'.
// Generates a PDF offer letter using pdf-lib, uploads it to Supabase Storage
// (bucket: offer-letters), writes a row to offer_letters, and returns a signed URL.
//
// Required secrets:
//   SUPABASE_URL                  - auto-provided
//   SUPABASE_SERVICE_ROLE_KEY     - auto-provided

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PDFDocument, rgb, StandardFonts } from "https://esm.sh/pdf-lib@1.17.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const db = createClient(SUPABASE_URL, SUPABASE_KEY);

// ── colour helpers ─────────────────────────────────────────────────────────────
const crimson = rgb(0.725, 0.110, 0.110); // #B91C1C
const dark    = rgb(0.059, 0.090, 0.165); // #0F172A
const muted   = rgb(0.580, 0.580, 0.600);

// ── PDF generation ────────────────────────────────────────────────────────────

async function buildOfferLetterPDF(data: {
  applicantName: string;
  applicantId: string;
  programme: string;
  faculty: string;
  applicantType: string;
  email: string;
  offerDate: string;
  academicYear: string;
}): Promise<Uint8Array> {
  const pdf  = await PDFDocument.create();
  const page = pdf.addPage([595.28, 841.89]); // A4
  const { width, height } = page.getSize();

  const bold    = await pdf.embedFont(StandardFonts.HelveticaBold);
  const regular = await pdf.embedFont(StandardFonts.Helvetica);

  // ── Header bar ──────────────────────────────────────────────────────────────
  page.drawRectangle({ x: 0, y: height - 80, width, height: 80, color: crimson });

  page.drawText("AFRICA UNIVERSITY", {
    x: 48, y: height - 36,
    size: 18, font: bold, color: rgb(1, 1, 1),
  });
  page.drawText("Mutare, Zimbabwe  ·  www.africau.edu", {
    x: 48, y: height - 56,
    size: 9, font: regular, color: rgb(1, 1, 0.9),
  });
  page.drawText("AU Connect Admissions Portal", {
    x: width - 220, y: height - 46,
    size: 9, font: regular, color: rgb(1, 1, 0.85),
  });

  // ── Accent stripe ───────────────────────────────────────────────────────────
  page.drawRectangle({ x: 0, y: height - 84, width, height: 4, color: rgb(0.498, 0.110, 0.110) });

  let y = height - 120;

  // ── Date + ref ──────────────────────────────────────────────────────────────
  page.drawText(data.offerDate, { x: 48, y, size: 10, font: regular, color: muted });
  page.drawText(`Ref: ${data.applicantId}`, {
    x: width - 180, y, size: 10, font: regular, color: muted,
  });

  y -= 36;

  // ── Title ───────────────────────────────────────────────────────────────────
  page.drawText("OFFER OF ADMISSION", {
    x: 48, y, size: 20, font: bold, color: crimson,
  });

  y -= 10;
  page.drawLine({ start: { x: 48, y }, end: { x: width - 48, y }, thickness: 1.5, color: crimson });

  y -= 30;

  // ── Body ────────────────────────────────────────────────────────────────────
  const lines = [
    `Dear ${data.applicantName},`,
    "",
    "On behalf of the Academic Board of Africa University, it is with great pleasure that",
    "we offer you admission to the following programme for the academic year stated below.",
    "",
  ];

  for (const line of lines) {
    page.drawText(line, { x: 48, y, size: 11, font: regular, color: dark });
    y -= line === "" ? 10 : 18;
  }

  // ── Admission details box ────────────────────────────────────────────────────
  const boxH = 130;
  page.drawRectangle({
    x: 48, y: y - boxH, width: width - 96, height: boxH,
    color: rgb(0.988, 0.949, 0.949),
    borderColor: rgb(0.849, 0.749, 0.749),
    borderWidth: 1,
  });

  const fields: [string, string][] = [
    ["Programme",       data.programme],
    ["Faculty",         data.faculty],
    ["Applicant Type",  data.applicantType],
    ["Academic Year",   data.academicYear],
    ["Applicant ID",    data.applicantId],
  ];

  let fy = y - 20;
  for (const [label, value] of fields) {
    page.drawText(`${label}:`, { x: 64, y: fy, size: 10, font: bold, color: dark });
    page.drawText(value,       { x: 200, y: fy, size: 10, font: regular, color: dark });
    fy -= 20;
  }

  y -= boxH + 24;

  // ── Body continued ──────────────────────────────────────────────────────────
  const body2 = [
    "This offer is conditional upon verification of all submitted documents and payment",
    "of the required registration fees. Please log in to your AU Connect portal to",
    "complete the acceptance of this offer and to access further instructions.",
    "",
    "We look forward to welcoming you to Africa University.",
    "",
    "Yours sincerely,",
    "",
  ];

  for (const line of body2) {
    page.drawText(line, { x: 48, y, size: 11, font: regular, color: dark });
    y -= line === "" ? 10 : 18;
  }

  // ── Signature block ─────────────────────────────────────────────────────────
  y -= 20;
  page.drawText("________________________________", { x: 48, y, size: 11, font: regular, color: dark });
  y -= 16;
  page.drawText("Registrar, Africa University",    { x: 48, y, size: 10, font: bold,    color: dark });
  y -= 14;
  page.drawText("admissions@africau.edu",           { x: 48, y, size: 9,  font: regular, color: muted });

  // ── Footer ──────────────────────────────────────────────────────────────────
  page.drawLine({
    start: { x: 48, y: 60 }, end: { x: width - 48, y: 60 },
    thickness: 0.5, color: rgb(0.85, 0.85, 0.85),
  });
  page.drawText(
    "Africa University  ·  P.O. Box 1320, Mutare, Zimbabwe  ·  +263 20 60009  ·  www.africau.edu",
    { x: 48, y: 44, size: 8, font: regular, color: muted }
  );
  page.drawText("This document is computer-generated and does not require a physical signature.", {
    x: 48, y: 30, size: 7.5, font: regular, color: rgb(0.7, 0.7, 0.7),
  });

  return pdf.save();
}

// ── main handler ───────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    const payload = await req.json();
    const { type, table, record, old_record } = payload;

    // Only proceed for applications that just became Approved
    if (
      table !== "applications" ||
      type  !== "UPDATE"        ||
      record?.status !== "Approved" ||
      old_record?.status === "Approved"
    ) {
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

    const applicationId = record.id as string;
    const userId        = record.user_id as string | undefined;
    const applicantId   = record.applicant_id as string ?? applicationId;
    const programme     = record.programme    as string ?? "Not specified";
    const faculty       = record.faculty      as string ?? "Not specified";
    const appType       = record.type         as string ?? "Undergraduate";

    // Fetch profile for applicant name + email
    let applicantName = record.applicant_name as string ?? "Applicant";
    if (userId) {
      const { data: profile } = await db
        .from("profiles")
        .select("full_name")
        .eq("user_id", userId)
        .maybeSingle();
      if (profile?.full_name) applicantName = profile.full_name;
    }

    const now = new Date();
    const months = ["January","February","March","April","May","June",
                    "July","August","September","October","November","December"];
    const offerDate   = `${now.getDate()} ${months[now.getMonth()]} ${now.getFullYear()}`;
    const academicYear = `${now.getFullYear()}/${now.getFullYear() + 1}`;

    // Generate PDF
    const pdfBytes = await buildOfferLetterPDF({
      applicantName,
      applicantId,
      programme,
      faculty,
      applicantType: appType,
      email: record.email ?? "",
      offerDate,
      academicYear,
    });

    // Upload to Storage
    const filePath = `${userId ?? applicantId}/${applicationId}/offer_letter.pdf`;
    const { error: uploadError } = await db.storage
      .from("offer-letters")
      .upload(filePath, pdfBytes, {
        contentType: "application/pdf",
        upsert: true,
      });

    if (uploadError) {
      console.error("Storage upload error:", uploadError);
      return new Response(JSON.stringify({ error: uploadError.message }), { status: 500 });
    }

    // Create signed URL (7 days)
    const { data: signedData } = await db.storage
      .from("offer-letters")
      .createSignedUrl(filePath, 60 * 60 * 24 * 7);

    const signedUrl = signedData?.signedUrl ?? null;

    // Write offer_letters row
    await db.from("offer_letters").upsert({
      application_id: applicationId,
      applicant_id:   userId ?? applicantId,
      file_path:      filePath,
      signed_url:     signedUrl,
      created_at:     now.toISOString(),
    }, { onConflict: "application_id" });

    return new Response(
      JSON.stringify({ ok: true, signedUrl }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("generate-offer-letter error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
