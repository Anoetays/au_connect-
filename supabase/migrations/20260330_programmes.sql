-- ─────────────────────────────────────────────────────────────────────────────
-- Africa University — Real Programmes
-- Run this in Supabase Dashboard → SQL Editor
-- ─────────────────────────────────────────────────────────────────────────────

-- Add unique constraint on name (run once, safe to re-run)
ALTER TABLE programmes
  ADD CONSTRAINT programmes_name_unique UNIQUE (name);

-- Clear any seed/placeholder data first (optional — comment out to keep existing rows)
-- DELETE FROM programmes;

INSERT INTO programmes (name, faculty, level, duration_years, status) VALUES

-- ── Faculty of Commerce ───────────────────────────────────────────────────────
('Bachelor of Accounting Honours',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

('Bachelor of Business Studies Honours in Management',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

('Bachelor of Business Studies Honours in Marketing',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Economics',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Human Resources Management',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Public Administration',
 'Faculty of Commerce', 'Undergraduate', 4, 'Active'),

-- ── Faculty of Science and Technology ────────────────────────────────────────
('Bachelor of Science Honours in Artificial Intelligence',
 'Faculty of Science and Technology', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Computer Information Systems',
 'Faculty of Science and Technology', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Computer Science',
 'Faculty of Science and Technology', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Information Technology',
 'Faculty of Science and Technology', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Software Engineering',
 'Faculty of Science and Technology', 'Undergraduate', 4, 'Active'),

-- ── Faculty of Health Sciences ────────────────────────────────────────────────
('Bachelor of Health Services Management Honours',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Medical Laboratory Sciences Honours',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Agribusiness Management',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Agriculture and Community Development',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Environmental Studies and Natural Resources Management',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Natural Resources Management',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

('Post-Basic Bachelor of Science Honours in Nursing',
 'Faculty of Health Sciences', 'Undergraduate', 4, 'Active'),

-- ── Faculty of Theology, Humanities and Social Sciences ──────────────────────
('Bachelor in Early Childhood Education Honours',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours in English and Communication Studies',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours in Gender and Cultural Studies',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours in Media and Journalism',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours in Religion and Community Health',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours in Translation and Interpretation in Languages',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Arts Honours with Education',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Divinity Honours',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Education Honours in Mathematics',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Agriculture with Education',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Counselling',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in Industrial Sociology and Labour Studies',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science Honours in International Relations',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science in Social Work',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Science with Education in Business and Commerce Honours',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Bachelor of Social Sciences Honours in Psychology',
 'Faculty of Theology, Humanities and Social Sciences', 'Undergraduate', 4, 'Active'),

('Post Graduate Diploma in Education',
 'Faculty of Theology, Humanities and Social Sciences', 'Postgraduate', 1, 'Active'),

-- ── Faculty of Law ────────────────────────────────────────────────────────────
('Bachelor of Laws Honours (LLB)',
 'Faculty of Law', 'Undergraduate', 4, 'Active')

ON CONFLICT (name) DO UPDATE
  SET faculty       = EXCLUDED.faculty,
      level         = EXCLUDED.level,
      duration_years = EXCLUDED.duration_years,
      status        = EXCLUDED.status;
