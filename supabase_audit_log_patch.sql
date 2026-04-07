-- Patch: add missing columns to audit_log so the Flutter service can insert correctly.
-- Run this in your Supabase SQL Editor.

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS action_type  text;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS admin_role   text;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS target_type  text;

-- Back-fill action_type from the old action column (if any rows exist)
UPDATE audit_log SET action_type = action WHERE action_type IS NULL AND action IS NOT NULL;
