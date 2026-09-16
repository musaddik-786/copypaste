-- ============================================================
-- JARVIS — PREREQUISITE DUMMY DATA FOR TESTING
-- Run this once on Azure PostgreSQL before testing agents.
-- Covers: Motor LOB (20 policies) + Homeowners LOB (local-only)
-- ============================================================


-- ============================================================
-- SECTION 1 — TABLE CREATION (safe: IF NOT EXISTS)
-- ============================================================

-- Motor mandatory fields config (which fields the agent must collect)
CREATE TABLE IF NOT EXISTS motor_fnol_mandatory_fields (
    id              SERIAL PRIMARY KEY,
    field_name      VARCHAR(100) NOT NULL UNIQUE,
    display_name    VARCHAR(200),
    field_type      VARCHAR(50)  DEFAULT 'text',
    is_required     BOOLEAN      DEFAULT TRUE,
    display_order   INTEGER      DEFAULT 0,
    placeholder     TEXT,
    options         TEXT,
    description     TEXT
);

-- Motor policy details (mirrors policy_details for Homeowners)
CREATE TABLE IF NOT EXISTS motor_policy_details (
    policy_number            VARCHAR(100) PRIMARY KEY,
    gw_policy_id             VARCHAR(100),
    status                   VARCHAR(50)   DEFAULT 'Active',
    coverage_type            VARCHAR(100)  DEFAULT 'Motor',
    deductible               NUMERIC(12,2),
    coverage_limit           NUMERIC(12,2),
    remaining_coverage_limit NUMERIC(12,2),
    exclusions               TEXT,
    effective_date           DATE,
    expiration_date          DATE,
    premium_amount           NUMERIC(12,2),
    policyholder_name        VARCHAR(200),
    account_number           VARCHAR(100),
    policy_address           TEXT,
    state                    VARCHAR(50),
    term_type                VARCHAR(50)   DEFAULT 'Annual',
    currency                 VARCHAR(10)   DEFAULT 'USD',
    city                     VARCHAR(100),
    country                  VARCHAR(100)  DEFAULT 'USA',
    postal_code              VARCHAR(20),
    created_at               TIMESTAMPTZ   DEFAULT NOW()
);

-- Motor vehicle details (auto-populated into FNOL after creation)
CREATE TABLE IF NOT EXISTS motor_vehicle_details (
    id                  SERIAL PRIMARY KEY,
    policy_number       VARCHAR(100) NOT NULL UNIQUE,
    make                VARCHAR(100),
    model               VARCHAR(100),
    year                INTEGER,
    registration_number VARCHAR(100),
    color               VARCHAR(50),
    vin                 VARCHAR(50),
    vehicle_type        VARCHAR(50),
    insured_value       NUMERIC(12,2),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- Motor coverage verification results (written by Policy Coverage agent)
CREATE TABLE IF NOT EXISTS motor_coverage_verification_results (
    id                  SERIAL PRIMARY KEY,
    claim_number        VARCHAR(100) UNIQUE NOT NULL,
    policy_number       VARCHAR(100),
    coverage_verdict    VARCHAR(100),
    exclusion_triggered BOOLEAN      DEFAULT FALSE,
    exclusion_details   TEXT,
    net_payable         NUMERIC(12,2),
    coverage_notes      TEXT,
    verified_at         TIMESTAMPTZ  DEFAULT NOW()
);

-- Motor FNOL submissions table (created by voice text intake agent)
CREATE TABLE IF NOT EXISTS motor_fnol_submissions (
    id                        SERIAL PRIMARY KEY,
    policy_number             VARCHAR(100),
    policyholder_name         VARCHAR(200),
    lob                       VARCHAR(50)  DEFAULT 'Motor',
    status                    VARCHAR(50)  DEFAULT 'draft',
    claim_number              VARCHAR(100),
    loss_type                 VARCHAR(100),
    cause_of_loss             TEXT,
    date_of_loss              DATE,
    time_of_loss              TIME,
    accident_location         TEXT,
    severity                  VARCHAR(50),
    urgency_indicator         VARCHAR(50),
    emotional_context         TEXT,
    overall_confidence        NUMERIC(5,2),
    vehicle_make              VARCHAR(100),
    vehicle_model             VARCHAR(100),
    vehicle_year              INTEGER,
    registration_number       VARCHAR(100),
    estimated_loss_amount     NUMERIC(12,2),
    injuries_involved         BOOLEAN      DEFAULT FALSE,
    police_report_number      VARCHAR(100),
    loss_type_source          VARCHAR(50),
    cause_of_loss_source      VARCHAR(50),
    date_of_loss_source       VARCHAR(50),
    accident_location_source  VARCHAR(50),
    severity_source           VARCHAR(50),
    created_at                TIMESTAMPTZ  DEFAULT NOW(),
    updated_at                TIMESTAMPTZ  DEFAULT NOW()
);

-- Motor mandatory question log
CREATE TABLE IF NOT EXISTS motor_fnol_mandatory_question_log (
    id             SERIAL PRIMARY KEY,
    fnol_id        INTEGER,
    question_order INTEGER,
    field_name     VARCHAR(100),
    question_asked TEXT,
    answer_given   TEXT,
    source         VARCHAR(50)  DEFAULT 'conversation',
    created_at     TIMESTAMPTZ  DEFAULT NOW()
);

-- Motor AI inferences
CREATE TABLE IF NOT EXISTS motor_fnol_ai_inferences (
    id          SERIAL PRIMARY KEY,
    fnol_id     INTEGER,
    field_name  VARCHAR(100),
    inferred_value TEXT,
    confidence  NUMERIC(5,2),
    model_used  VARCHAR(100),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Motor voice/text extraction
CREATE TABLE IF NOT EXISTS motor_fnol_voice_text_extraction (
    id              SERIAL PRIMARY KEY,
    fnol_id         INTEGER,
    raw_text        TEXT,
    extracted_json  TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Motor field attribution
CREATE TABLE IF NOT EXISTS motor_fnol_field_attribution (
    id          SERIAL PRIMARY KEY,
    fnol_id     INTEGER,
    field_name  VARCHAR(100),
    source      VARCHAR(50),
    value       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Shared claim_payments table (used by both LOBs)
CREATE TABLE IF NOT EXISTS claim_payments (
    id              SERIAL PRIMARY KEY,
    payment_id      VARCHAR(100) UNIQUE,
    claim_number    VARCHAR(100),
    policy_number   VARCHAR(100),
    amount_paid     NUMERIC(12,2),
    payment_date    TIMESTAMPTZ,
    approved_by     VARCHAR(200),
    payment_status  VARCHAR(50)  DEFAULT 'Released',
    coverage_before NUMERIC(12,2),
    coverage_after  NUMERIC(12,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ  DEFAULT NOW()
);


-- ============================================================
-- SECTION 2 — MOTOR MANDATORY FIELDS CONFIG
-- Used by: Voice Text Intake Agent (Motor LOB)
-- What it does: tells the agent which fields are required
-- ============================================================

TRUNCATE motor_fnol_mandatory_fields RESTART IDENTITY CASCADE;

INSERT INTO motor_fnol_mandatory_fields
    (field_name, display_name, field_type, is_required, display_order, placeholder, description)
VALUES
('loss_type',         'Type of Loss',        'select', TRUE,  1, NULL,
    'Motor loss category — Collision, Theft, Vandalism, Fire, Natural Disaster, Third-Party Liability, Windshield Damage'),

('cause_of_loss',     'Cause of Loss',       'text',   TRUE,  2, 'e.g. Rear-ended at traffic signal',
    'Detailed cause or description of what happened'),

('date_of_loss',      'Date of Loss',        'date',   TRUE,  3, 'YYYY-MM-DD',
    'Date when the motor incident occurred'),

('time_of_loss',      'Time of Loss',        'time',   FALSE, 4, 'HH:MM (24-hr)',
    'Approximate time of the incident'),

('accident_location', 'Accident Location',   'text',   TRUE,  5, 'e.g. MG Road near traffic signal, Bangalore',
    'Exact or approximate location of the accident'),

('severity',          'Damage Severity',     'select', TRUE,  6, NULL,
    'Low / Medium / High — based on visible damage assessment'),

('urgency_indicator', 'Urgency Level',       'select', FALSE, 7, NULL,
    'Immediate / Standard / Low — how quickly the claim needs action'),

('emotional_context', 'Policyholder State',  'text',   FALSE, 8, 'e.g. Worried, Calm, Distressed',
    'Emotional state of the policyholder during intake');


-- ============================================================
-- SECTION 3 — MOTOR POLICY DETAILS (20 records)
-- Used by: Policy Coverage Verification Agent (Motor LOB)
-- What it does: provides policy data that mimics Guidewire PC
-- ============================================================

INSERT INTO motor_policy_details (
    policy_number, status, coverage_type,
    deductible, coverage_limit, remaining_coverage_limit,
    effective_date, expiration_date, premium_amount,
    policyholder_name, account_number, policy_address,
    city, state, postal_code, exclusions, term_type
) VALUES
('POL-1001','Active','Motor', 500.00,150000.00,150000.00,'2025-01-01','2026-01-01', 4500.00,
 'John Smith',      'ACC-M-1001','12 Oak Street, Austin TX 78701',    'Austin',      'TX','78701','Racing, DUI','Annual'),

('POL-1002','Active','Motor', 500.00,120000.00,120000.00,'2025-03-01','2026-03-01', 3600.00,
 'Jane Doe',        'ACC-M-1002','34 Elm Ave, Houston TX 77001',      'Houston',     'TX','77001', NULL,'Annual'),

('POL-1003','Active','Motor', 750.00,200000.00,200000.00,'2025-06-01','2026-06-01', 6000.00,
 'Robert Jones',    'ACC-M-1003','56 Pine Rd, Dallas TX 75201',       'Dallas',      'TX','75201','Racing','Annual'),

('POL-1004','Active','Motor', 500.00,100000.00,100000.00,'2025-01-15','2026-01-15', 3000.00,
 'Mary Brown',      'ACC-M-1004','78 Maple Dr, San Antonio TX 78201', 'San Antonio', 'TX','78201', NULL,'Annual'),

('POL-1005','Active','Motor', 250.00, 80000.00, 80000.00,'2025-02-01','2026-02-01', 2400.00,
 'David Wilson',    'ACC-M-1005','90 Cedar Ln, Phoenix AZ 85001',     'Phoenix',     'AZ','85001', NULL,'Annual'),

('POL-1006','Active','Motor', 500.00,175000.00,175000.00,'2025-04-01','2026-04-01', 5250.00,
 'Sarah Johnson',   'ACC-M-1006','23 Birch Blvd, Los Angeles CA 90001','Los Angeles','CA','90001','Racing, Off-road','Annual'),

('POL-1007','Active','Motor', 750.00,250000.00,250000.00,'2025-05-01','2026-05-01', 7500.00,
 'Michael Davis',   'ACC-M-1007','45 Spruce St, San Diego CA 92101',  'San Diego',   'CA','92101', NULL,'Annual'),

('POL-1008','Active','Motor', 500.00,130000.00,130000.00,'2025-07-01','2026-07-01', 3900.00,
 'Emily Martinez',  'ACC-M-1008','67 Willow Way, Denver CO 80201',    'Denver',      'CO','80201','DUI','Annual'),

('POL-1009','Active','Motor', 250.00, 90000.00, 90000.00,'2025-08-01','2026-08-01', 2700.00,
 'James Taylor',    'ACC-M-1009','89 Aspen Ave, Seattle WA 98101',    'Seattle',     'WA','98101', NULL,'Annual'),

('POL-1010','Active','Motor', 500.00,160000.00,160000.00,'2025-09-01','2026-09-01', 4800.00,
 'Lisa Anderson',   'ACC-M-1010','11 Hickory Ct, Portland OR 97201',  'Portland',    'OR','97201', NULL,'Annual'),

('POL-1011','Active','Motor', 750.00,220000.00,220000.00,'2025-01-01','2026-01-01', 6600.00,
 'Christopher Lee', 'ACC-M-1011','33 Sycamore St, Chicago IL 60601',  'Chicago',     'IL','60601','Racing','Annual'),

('POL-1012','Active','Motor', 500.00,110000.00,110000.00,'2025-02-15','2026-02-15', 3300.00,
 'Amanda White',    'ACC-M-1012','55 Poplar Pl, Nashville TN 37201',  'Nashville',   'TN','37201', NULL,'Annual'),

('POL-1013','Active','Motor', 250.00, 75000.00, 75000.00,'2025-03-15','2026-03-15', 2250.00,
 'Daniel Harris',   'ACC-M-1013','77 Magnolia Dr, Atlanta GA 30301',  'Atlanta',     'GA','30301', NULL,'Annual'),

('POL-1014','Active','Motor', 500.00,140000.00,140000.00,'2025-04-15','2026-04-15', 4200.00,
 'Jessica Clark',   'ACC-M-1014','99 Dogwood Ln, Miami FL 33101',     'Miami',       'FL','33101','Off-road','Annual'),

('POL-1015','Active','Motor', 750.00,300000.00,300000.00,'2025-05-15','2026-05-15', 9000.00,
 'Matthew Robinson','ACC-M-1015','21 Redwood Rd, Las Vegas NV 89101', 'Las Vegas',   'NV','89101','Racing, DUI','Annual'),

('POL-1016','Active','Motor', 500.00,125000.00,125000.00,'2025-06-15','2026-06-15', 3750.00,
 'Ashley Lewis',    'ACC-M-1016','43 Juniper St, Boston MA 02101',    'Boston',      'MA','02101', NULL,'Annual'),

('POL-1017','Active','Motor', 250.00, 85000.00, 85000.00,'2025-07-15','2026-07-15', 2550.00,
 'Ryan Walker',     'ACC-M-1017','65 Fir Ave, Minneapolis MN 55401',  'Minneapolis', 'MN','55401', NULL,'Annual'),

('POL-1018','Active','Motor', 500.00,190000.00,190000.00,'2025-08-15','2026-08-15', 5700.00,
 'Megan Hall',      'ACC-M-1018','87 Cypress Ct, Detroit MI 48201',   'Detroit',     'MI','48201','DUI','Annual'),

('POL-1019','Active','Motor', 750.00,240000.00,240000.00,'2025-09-15','2026-09-15', 7200.00,
 'Kevin Young',     'ACC-M-1019','9 Walnut Blvd, Philadelphia PA 19101','Philadelphia','PA','19101', NULL,'Annual'),

('POL-1020','Active','Motor', 500.00,145000.00,145000.00,'2025-10-01','2026-10-01', 4350.00,
 'Stephanie King',  'ACC-M-1020','31 Chestnut Rd, Columbus OH 43201', 'Columbus',    'OH','43201', NULL,'Annual')

ON CONFLICT (policy_number) DO UPDATE SET
    remaining_coverage_limit = EXCLUDED.coverage_limit,
    policyholder_name        = EXCLUDED.policyholder_name,
    status                   = EXCLUDED.status;


-- ============================================================
-- SECTION 4 — MOTOR VEHICLE DETAILS (20 records)
-- Used by: Voice Text Intake Agent (Motor LOB)
-- What it does: auto-populates vehicle fields into the FNOL
--               after create_fnol_submission is called
-- ============================================================

INSERT INTO motor_vehicle_details
    (policy_number, make, model, year, registration_number, color, vin, vehicle_type, insured_value)
VALUES
('POL-1001','Honda',      'Accord',      2022,'TX-AB-1234','Silver',        '1HGCV1F30NA000001','Sedan',        150000.00),
('POL-1002','Toyota',     'Camry',       2021,'TX-CD-5678','Pearl White',   '4T1B11HK8JU000002','Sedan',        120000.00),
('POL-1003','Ford',       'Mustang GT',  2023,'TX-EF-9012','Race Red',      '1FA6P8CF3N5000003','Sports Car',   200000.00),
('POL-1004','Hyundai',    'Creta',       2022,'TX-GH-3456','Phantom Black', 'MALA851BLNM000004','SUV',          100000.00),
('POL-1005','Kia',        'Seltos',      2021,'AZ-IJ-7890','Glacier White', 'KNDJN2A26J7000005','SUV',           80000.00),
('POL-1006','BMW',        '3 Series',    2023,'CA-KL-2345','Mineral White', 'WBA8E9G55JNU00006','Sedan',        175000.00),
('POL-1007','Mercedes',   'C-Class',     2023,'CA-MN-6789','Obsidian Black','WDDWF4JB8FR000007','Sedan',        250000.00),
('POL-1008','Jeep',       'Wrangler',    2022,'CO-OP-0123','Gecko Green',   '1C4HJWDG8JL000008','SUV',          130000.00),
('POL-1009','Subaru',     'Outback',     2021,'WA-QR-4567','Ice Silver',    '4S4BSANC2J3000009','Wagon',         90000.00),
('POL-1010','Mazda',      'CX-5',        2022,'OR-ST-8901','Soul Red',      'JM3KFBDM1J0000010','SUV',          160000.00),
('POL-1011','Audi',       'A4',          2023,'IL-UV-2345','Glacier White', 'WAUFFAFL8JA000011','Sedan',        220000.00),
('POL-1012','Chevrolet',  'Silverado',   2022,'TN-WX-6789','Northsky Blue', '3GCUKREC1JG000012','Pickup Truck', 110000.00),
('POL-1013','Maruti',     'Swift',       2021,'GA-YZ-0123','Sizzling Orange','MA3EYDMS1J000013','Hatchback',     75000.00),
('POL-1014','Tata',       'Nexon',       2022,'FL-AB-4567','Pristine White','TATAF01FXLA000014','SUV',          140000.00),
('POL-1015','Porsche',    'Cayenne',     2023,'NV-CD-8901','Jet Black',     'WP1AF2A23JLA00015','SUV',          300000.00),
('POL-1016','Volkswagen', 'Tiguan',      2022,'MA-EF-2345','Reflex Silver', '1V2MR2CA5JC000016','SUV',          125000.00),
('POL-1017','Nissan',     'Rogue',       2021,'MN-GH-6789','Brilliant Silver','JN8AT2MT4JW000017','SUV',         85000.00),
('POL-1018','Dodge',      'Ram 1500',    2022,'MI-IJ-0123','Flame Red',     '1C6RR7LT4JS000018','Pickup Truck', 190000.00),
('POL-1019','Lexus',      'RX 350',      2023,'PA-KL-4567','Nightfall Mica','2T2BZMCA0JC000019','SUV',          240000.00),
('POL-1020','Volvo',      'XC60',        2022,'OH-MN-8901','Crystal White', 'YV4A22RL4J1000020','SUV',          145000.00)

ON CONFLICT (policy_number) DO NOTHING;


-- ============================================================
-- SECTION 5 — HOMEOWNERS LOCAL-ONLY POLICIES (3 records)
-- Used by: Policy Coverage Verification Agent (Homeowners LOB)
-- What it does: lets you test HO coverage without Guidewire PC
--               These match LOCAL_ONLY_POLICY_NUMBERS in handler.py
-- ============================================================

-- Make sure the HO policy_details table exists
CREATE TABLE IF NOT EXISTS policy_details (
    policy_number            VARCHAR(100) PRIMARY KEY,
    gw_policy_id             VARCHAR(100),
    status                   VARCHAR(50)   DEFAULT 'Active',
    coverage_type            VARCHAR(100)  DEFAULT 'Homeowners',
    deductible               NUMERIC(12,2),
    coverage_limit           NUMERIC(12,2),
    remaining_coverage_limit NUMERIC(12,2),
    exclusions               TEXT,
    effective_date           DATE,
    expiration_date          DATE,
    premium_amount           NUMERIC(12,2),
    policyholder_name        VARCHAR(200),
    account_number           VARCHAR(100),
    policy_address           TEXT,
    state                    VARCHAR(50),
    term_type                VARCHAR(50)   DEFAULT 'Annual',
    currency                 VARCHAR(10)   DEFAULT 'USD',
    city                     VARCHAR(100),
    country                  VARCHAR(100)  DEFAULT 'USA',
    postal_code              VARCHAR(20),
    created_at               TIMESTAMPTZ   DEFAULT NOW()
);

INSERT INTO policy_details (
    policy_number, gw_policy_id, status, coverage_type,
    deductible, coverage_limit, remaining_coverage_limit,
    effective_date, expiration_date, premium_amount,
    policyholder_name, account_number, policy_address,
    city, state, postal_code, exclusions
) VALUES
('73-300676','GW-HO-300676','Active','Homeowners',
  1000.00, 500000.00, 500000.00,
  '2025-01-01','2026-01-01', 3500.00,
  'Alice Thompson', 'ACC-HO-300676', '10 Lakewood Drive, Boston MA 02101',
  'Boston', 'MA', '02101', 'Flood, Earthquake'),

('73-400676','GW-HO-400676','Active','Homeowners',
  1500.00, 650000.00, 650000.00,
  '2025-03-01','2026-03-01', 4550.00,
  'Brian Foster',   'ACC-HO-400676', '22 Riverside Ave, Chicago IL 60601',
  'Chicago', 'IL', '60601', 'Flood'),

('73-123676','GW-HO-123676','Active','Homeowners',
  2000.00, 800000.00, 800000.00,
  '2025-06-01','2026-06-01', 5600.00,
  'Catherine Park',  'ACC-HO-123676', '44 Hillcrest Blvd, Denver CO 80201',
  'Denver', 'CO', '80201', NULL)

ON CONFLICT (policy_number) DO UPDATE SET
    remaining_coverage_limit = EXCLUDED.coverage_limit,
    policyholder_name        = EXCLUDED.policyholder_name;


-- ============================================================
-- SECTION 6 — HOMEOWNERS FNOL MANDATORY FIELDS CONFIG
-- Used by: Voice Text Intake Agent (Homeowners LOB)
-- ============================================================

CREATE TABLE IF NOT EXISTS fnol_mandatory_fields (
    id              SERIAL PRIMARY KEY,
    field_name      VARCHAR(100) NOT NULL UNIQUE,
    display_name    VARCHAR(200),
    field_type      VARCHAR(50)  DEFAULT 'text',
    is_required     BOOLEAN      DEFAULT TRUE,
    display_order   INTEGER      DEFAULT 0,
    placeholder     TEXT,
    description     TEXT
);

INSERT INTO fnol_mandatory_fields
    (field_name, display_name, field_type, is_required, display_order, placeholder, description)
VALUES
('loss_type',           'Type of Loss',       'select', TRUE,  1, NULL,
    'HO loss category — Water Damage, Fire, Theft, Storm, Vandalism, etc.'),
('cause_of_loss',       'Cause of Loss',      'text',   TRUE,  2, 'e.g. Burst pipe in bathroom',
    'Detailed cause of the property damage'),
('date_of_loss',        'Date of Loss',       'date',   TRUE,  3, 'YYYY-MM-DD',
    'Date when the damage occurred'),
('time_of_loss',        'Time of Loss',       'time',   FALSE, 4, 'HH:MM',
    'Approximate time of the incident'),
('area_affected',       'Area Affected',      'text',   TRUE,  5, 'e.g. Kitchen ceiling',
    'Which part of the property was damaged'),
('occupancy_at_loss',   'Occupancy at Time',  'select', FALSE, 6, NULL,
    'Was the property occupied when loss occurred?'),
('sudden_vs_gradual',   'Sudden or Gradual',  'select', FALSE, 7, NULL,
    'Did the damage happen suddenly or develop over time?'),
('severity',            'Damage Severity',    'select', TRUE,  8, NULL,
    'Low / Medium / High — overall damage assessment'),
('urgency_indicator',   'Urgency Level',      'select', FALSE, 9, NULL,
    'Immediate / Standard / Low — how urgently the claim needs attention')
ON CONFLICT (field_name) DO NOTHING;


-- ============================================================
-- VERIFY — Quick check queries (run after inserting)
-- ============================================================

SELECT 'motor_fnol_mandatory_fields' AS table_name, COUNT(*) AS rows FROM motor_fnol_mandatory_fields
UNION ALL
SELECT 'motor_policy_details',         COUNT(*) FROM motor_policy_details
UNION ALL
SELECT 'motor_vehicle_details',        COUNT(*) FROM motor_vehicle_details
UNION ALL
SELECT 'policy_details (HO local)',    COUNT(*) FROM policy_details WHERE policy_number IN ('73-300676','73-400676','73-123676')
UNION ALL
SELECT 'fnol_mandatory_fields (HO)',   COUNT(*) FROM fnol_mandatory_fields;
