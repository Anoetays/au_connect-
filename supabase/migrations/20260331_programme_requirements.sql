-- ─────────────────────────────────────────────────────────────────────────────
-- Africa University — Programme Requirements
-- Run this in Supabase Dashboard → SQL Editor
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create table
CREATE TABLE IF NOT EXISTS programme_requirements (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  programme_name  TEXT    NOT NULL,
  subject         TEXT    NOT NULL,
  minimum_grade   TEXT    NOT NULL DEFAULT 'C',
  is_compulsory   BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast lookup by programme name
CREATE INDEX IF NOT EXISTS idx_prog_req_programme_name
  ON programme_requirements (programme_name);

-- 2. Enable Row Level Security
ALTER TABLE programme_requirements ENABLE ROW LEVEL SECURITY;

-- Anyone can read requirements (needed by applicants + admins)
CREATE POLICY "requirements_select_all"
  ON programme_requirements FOR SELECT
  USING (true);

-- Only service-role / admin can insert/update/delete
CREATE POLICY "requirements_modify_admin"
  ON programme_requirements FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Seed requirements
--    Grades: A=Excellent(5), B=Very Good(4), C=Good(3), D=Pass(2), E=Marginal(1), U=Fail(0)
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO programme_requirements (programme_name, subject, minimum_grade, is_compulsory) VALUES

-- ── Faculty of Science and Technology ────────────────────────────────────────

-- BSc Computer Science
('Bachelor of Science Honours in Computer Science', 'Mathematics',         'B', true),
('Bachelor of Science Honours in Computer Science', 'English Language',    'C', true),
('Bachelor of Science Honours in Computer Science', 'Physics',             'C', false),

-- BSc Software Engineering
('Bachelor of Science Honours in Software Engineering', 'Mathematics',     'B', true),
('Bachelor of Science Honours in Software Engineering', 'English Language','C', true),
('Bachelor of Science Honours in Software Engineering', 'Physics',         'C', false),

-- BSc Artificial Intelligence
('Bachelor of Science Honours in Artificial Intelligence', 'Mathematics',  'A', true),
('Bachelor of Science Honours in Artificial Intelligence', 'English Language','C', true),
('Bachelor of Science Honours in Artificial Intelligence', 'Physics',      'B', false),

-- BSc Information Technology
('Bachelor of Science Honours in Information Technology', 'Mathematics',   'C', true),
('Bachelor of Science Honours in Information Technology', 'English Language','C', true),

-- BSc Computer Information Systems
('Bachelor of Science Honours in Computer Information Systems', 'Mathematics',    'C', true),
('Bachelor of Science Honours in Computer Information Systems', 'English Language','C', true),
('Bachelor of Science Honours in Computer Information Systems', 'Accounts',       'C', false),

-- ── Faculty of Commerce ───────────────────────────────────────────────────────

-- Bachelor of Accounting Honours
('Bachelor of Accounting Honours', 'Mathematics',      'C', true),
('Bachelor of Accounting Honours', 'English Language', 'C', true),
('Bachelor of Accounting Honours', 'Accounts',         'C', true),

-- Bachelor of Business Studies – Management
('Bachelor of Business Studies Honours in Management', 'English Language', 'C', true),
('Bachelor of Business Studies Honours in Management', 'Mathematics',      'C', true),
('Bachelor of Business Studies Honours in Management', 'Business Studies', 'C', false),

-- Bachelor of Business Studies – Marketing
('Bachelor of Business Studies Honours in Marketing', 'English Language',  'C', true),
('Bachelor of Business Studies Honours in Marketing', 'Mathematics',       'C', true),
('Bachelor of Business Studies Honours in Marketing', 'Business Studies',  'C', false),

-- BSc Economics
('Bachelor of Science Honours in Economics', 'Mathematics',      'B', true),
('Bachelor of Science Honours in Economics', 'English Language', 'C', true),
('Bachelor of Science Honours in Economics', 'Accounts',         'C', false),

-- BSc Human Resources Management
('Bachelor of Science Honours in Human Resources Management', 'English Language', 'C', true),
('Bachelor of Science Honours in Human Resources Management', 'Mathematics',      'C', true),

-- BSc Public Administration
('Bachelor of Science Honours in Public Administration', 'English Language', 'C', true),
('Bachelor of Science Honours in Public Administration', 'History',          'C', false),

-- ── Faculty of Health Sciences ────────────────────────────────────────────────

-- Bachelor of Health Services Management
('Bachelor of Health Services Management Honours', 'English Language', 'C', true),
('Bachelor of Health Services Management Honours', 'Biology',         'C', true),
('Bachelor of Health Services Management Honours', 'Mathematics',     'C', false),

-- Bachelor of Medical Laboratory Sciences
('Bachelor of Medical Laboratory Sciences Honours', 'Biology',          'B', true),
('Bachelor of Medical Laboratory Sciences Honours', 'Chemistry',        'B', true),
('Bachelor of Medical Laboratory Sciences Honours', 'Mathematics',      'C', true),
('Bachelor of Medical Laboratory Sciences Honours', 'English Language', 'C', true),
('Bachelor of Medical Laboratory Sciences Honours', 'Physics',          'C', false),

-- BSc Agribusiness Management
('Bachelor of Science Honours in Agribusiness Management', 'English Language', 'C', true),
('Bachelor of Science Honours in Agribusiness Management', 'Mathematics',      'C', true),
('Bachelor of Science Honours in Agribusiness Management', 'Agriculture',      'C', false),

-- BSc Agriculture and Community Development
('Bachelor of Science Honours in Agriculture and Community Development', 'Biology',         'C', true),
('Bachelor of Science Honours in Agriculture and Community Development', 'English Language','C', true),
('Bachelor of Science Honours in Agriculture and Community Development', 'Agriculture',     'C', false),

-- BSc Environmental Studies and Natural Resources Management
('Bachelor of Science Honours in Environmental Studies and Natural Resources Management', 'Biology',         'C', true),
('Bachelor of Science Honours in Environmental Studies and Natural Resources Management', 'Geography',       'C', true),
('Bachelor of Science Honours in Environmental Studies and Natural Resources Management', 'English Language','C', true),

-- BSc Natural Resources Management
('Bachelor of Science Honours in Natural Resources Management', 'Biology',          'C', true),
('Bachelor of Science Honours in Natural Resources Management', 'Geography',        'C', false),
('Bachelor of Science Honours in Natural Resources Management', 'English Language', 'C', true),

-- Post-Basic Nursing
('Post-Basic Bachelor of Science Honours in Nursing', 'Biology',          'B', true),
('Post-Basic Bachelor of Science Honours in Nursing', 'Chemistry',        'C', true),
('Post-Basic Bachelor of Science Honours in Nursing', 'English Language', 'C', true),
('Post-Basic Bachelor of Science Honours in Nursing', 'Mathematics',      'C', false),

-- ── Faculty of Theology, Humanities and Social Sciences ──────────────────────

-- Early Childhood Education
('Bachelor in Early Childhood Education Honours', 'English Language', 'C', true),
('Bachelor in Early Childhood Education Honours', 'Biology',          'C', false),

-- BA English and Communication Studies
('Bachelor of Arts Honours in English and Communication Studies', 'English Language', 'B', true),
('Bachelor of Arts Honours in English and Communication Studies', 'Literature',       'C', false),

-- BA Gender and Cultural Studies
('Bachelor of Arts Honours in Gender and Cultural Studies', 'English Language', 'C', true),
('Bachelor of Arts Honours in Gender and Cultural Studies', 'History',          'C', false),

-- BA Media and Journalism
('Bachelor of Arts Honours in Media and Journalism', 'English Language', 'B', true),
('Bachelor of Arts Honours in Media and Journalism', 'Literature',       'C', false),

-- BA Religion and Community Health
('Bachelor of Arts Honours in Religion and Community Health', 'English Language', 'C', true),
('Bachelor of Arts Honours in Religion and Community Health', 'Religious Studies', 'C', false),

-- BA Translation and Interpretation
('Bachelor of Arts Honours in Translation and Interpretation in Languages', 'English Language', 'B', true),
('Bachelor of Arts Honours in Translation and Interpretation in Languages', 'French',          'C', false),

-- BA with Education
('Bachelor of Arts Honours with Education', 'English Language', 'C', true),

-- Bachelor of Divinity
('Bachelor of Divinity Honours', 'English Language',   'C', true),
('Bachelor of Divinity Honours', 'Religious Studies',  'C', false),

-- BEd Mathematics
('Bachelor of Education Honours in Mathematics', 'Mathematics',      'B', true),
('Bachelor of Education Honours in Mathematics', 'English Language', 'C', true),

-- BSc Agriculture with Education
('Bachelor of Science Honours in Agriculture with Education', 'Biology',         'C', true),
('Bachelor of Science Honours in Agriculture with Education', 'Agriculture',     'C', false),
('Bachelor of Science Honours in Agriculture with Education', 'English Language','C', true),

-- BSc Counselling
('Bachelor of Science Honours in Counselling', 'English Language', 'C', true),
('Bachelor of Science Honours in Counselling', 'Biology',          'C', false),

-- BSc Industrial Sociology and Labour Studies
('Bachelor of Science Honours in Industrial Sociology and Labour Studies', 'English Language', 'C', true),
('Bachelor of Science Honours in Industrial Sociology and Labour Studies', 'History',          'C', false),

-- BSc International Relations
('Bachelor of Science Honours in International Relations', 'English Language', 'C', true),
('Bachelor of Science Honours in International Relations', 'History',          'C', false),

-- BSc Social Work
('Bachelor of Science in Social Work', 'English Language', 'C', true),
('Bachelor of Science in Social Work', 'Biology',          'C', false),

-- BSc with Education – Business and Commerce
('Bachelor of Science with Education in Business and Commerce Honours', 'English Language', 'C', true),
('Bachelor of Science with Education in Business and Commerce Honours', 'Mathematics',      'C', true),
('Bachelor of Science with Education in Business and Commerce Honours', 'Business Studies', 'C', false),

-- BSocSci Psychology
('Bachelor of Social Sciences Honours in Psychology', 'English Language', 'C', true),
('Bachelor of Social Sciences Honours in Psychology', 'Biology',          'C', false),

-- Post Graduate Diploma in Education (flexible entry — English only compulsory)
('Post Graduate Diploma in Education', 'English Language', 'C', true),

-- ── Faculty of Law ────────────────────────────────────────────────────────────

('Bachelor of Laws Honours (LLB)', 'English Language', 'B', true),
('Bachelor of Laws Honours (LLB)', 'History',          'C', false),
('Bachelor of Laws Honours (LLB)', 'Literature',       'C', false)

ON CONFLICT DO NOTHING;
