-- ============================================================
-- SRA Test Seed  —  Part 1 of 2
-- Run AFTER: 001_sra_schema.sql + 001_sra_schema_gap_fixes.sql
-- Then run seed_part2.sql
-- ============================================================
-- Customer → Rule → Expected Engine Outcome
--  T001  BR-01  SUPPRESS  (consent REVOKED)
--  T002  BR-01  SUPPRESS  (consent UNSPECIFIED)
--  T003  BR-02  SUPPRESS  (payment ARREARS)
--  T004  BR-02  SUPPRESS  (payment DD_RETURNED)
--  T005  BR-03  SUPPRESS  (open COMPLAINT in 180 days)
--  T006  BR-03  SUPPRESS  (DISPUTED claim in 180 days)
--  T007  BR-04  COOLDOWN_ACTIVE  (CAR_NCD_PROTECTION declined 30 days ago)
--  T008  BR-05  DISQUALIFIED_RISK  (at_fault_24mo = 2)
--  T009  BR-05  DISQUALIFIED_RISK  (demerit_points = 5)
--  T010  BR-05  DISQUALIFIED_RISK  (open LITIGATION claim, property)
--  T011  BR-06  TARGET_MARKET_MISMATCH  (TENANT with HOME_BUILDING)
--  T012  ALL GK PASSED  (baseline clean car customer)
--  T013  UP-CAR-01  ELIGIBLE
--  T014  UP-CAR-01  DISQUALIFIED_RISK  (bonus_tier=6 < 8)
--  T015  UP-CAR-01  DISQUALIFIED_RISK  (at_fault_36mo=1)
--  T016  UP-CAR-01  ALREADY_COVERED  (NCD rider attached)
--  T017  UP-CAR-02  ELIGIBLE
--  T018  UP-CAR-02  DISQUALIFIED_RISK  (market_value=5000 < 8000)
--  T019  UP-CAR-02  DISQUALIFIED_RISK  (build_year=2015, age > 8)
--  T020  UP-CAR-02  DISQUALIFIED_RISK  (at_fault_12mo=1)
--  T021  UP-CAR-03  ELIGIBLE
--  T022  UP-CAR-03  DISQUALIFIED_RISK  (annual_km=8000 < 12000)
--  T023  UP-CAR-03  DISQUALIFIED_RISK  (household_vehicle_count=2)
--  T024  UP-CAR-03  ALREADY_COVERED  (roadside rider attached)
--  T025  UP-HOM-01  ELIGIBLE  (zuers_zone=2)
--  T026  UP-HOM-01  REFERRAL_REQUIRED  (zuers_zone=4)
--  T027  UP-HOM-01  DISQUALIFIED_RISK  (open WATER claim in 24mo)
--  T028  UP-HOM-01  ALREADY_COVERED  (flood cover attached)
--  T029  UP-HOM-02  ELIGIBLE  (floor_area=150sqm)
--  T030  UP-HOM-02  DISQUALIFIED_RISK  (floor_area=100sqm < 120)
--  T031  UP-PET-01  ELIGIBLE  (pet age=7, 0 minor vet claims 24mo)
--  T032  UP-PET-01  DISQUALIFIED_RISK  (pet birth_year=2013, age=13)
--  T033  UP-PET-01  DISQUALIFIED_RISK  (2 minor VET claims in 24mo)
--  T034  CS-CAR-01  ELIGIBLE  (single policy, TENANT, no liability)
--  T035  CS-CAR-01  NOT_APPLICABLE  (active_policy_count=2)
--  T036  CS-CAR-01  NOT_APPLICABLE  (OWNER_OCCUPIER, not TENANT)
--  T037  CS-CAR-01  ALREADY_COVERED  (has LIABILITY policy)
--  T038  CS-CAR-02  ELIGIBLE  (annual_km=16000, primary_earner, no disability cover)
--  T039  CS-CAR-02  DISQUALIFIED_RISK  (annual_km=12000 < 15000)
--  T040  CS-CAR-02  DISQUALIFIED_RISK  (primary_earner=false)
--  T041  CS-CAR-02  ALREADY_COVERED  (PERSONAL_DISABILITY in active_external_covers)
--  T042  CS-HOM-01  ELIGIBLE  (OWNER_OCCUPIER, DETACHED, floor=160sqm, no contents)
--  T043  CS-HOM-01  NOT_APPLICABLE  (TENANT)
--  T044  CS-HOM-01  DISQUALIFIED_RISK  (floor_area=120sqm < 140)
--  T045  CS-HOM-01  ALREADY_COVERED  (has HOME_CONTENTS policy)
--  T046  CS-PET-01  ELIGIBLE  (claim_free=4yr, external_policies_active=[TPL], no car)
--  T047  CS-PET-01  DISQUALIFIED_RISK  (claim within last 3 years)
--  T048  CS-PET-01  NOT_APPLICABLE  (no external motor policy)
--  T049  CS-PET-01  NOT_APPLICABLE  (external_policies_active=[FULL])
--  T050  CS-LIA-01  ELIGIBLE  (LIABILITY, dog_owner, no pet)
--  T051  CS-LIA-01  NOT_APPLICABLE  (no dog/horse declared)
--  T052  CS-LIA-01  ALREADY_COVERED  (has PET_HEALTH policy)
-- ============================================================

BEGIN;

-- ============================================================
-- SECTION 1: Reference Data
-- ============================================================

INSERT INTO ref.line_of_business (lob_code, name_en, name_de, in_brd_scope) VALUES
  ('CAR',           'Car Insurance',           'Kfz-Versicherung',        true),
  ('HOME_BUILDING', 'Home Building Insurance', 'Wohngebäudeversicherung', true),
  ('HOME_CONTENTS', 'Home Contents Insurance', 'Hausratsversicherung',    true),
  ('LIABILITY',     'Personal Liability',       'Privathaftpflicht',       true),
  ('PET_HEALTH',    'Pet Health Insurance',     'Tierkrankenversicherung', true),
  ('ACCIDENT',      'Personal Accident',        'Unfallversicherung',      true)
ON CONFLICT DO NOTHING;

INSERT INTO ref.product
  (product_code, lob_code, product_kind, name_en, name_de, cooldown_class, status, effective_from)
VALUES
  ('CAR_TPL_BASE',             'CAR',           'BASE',  'Car TPL Base',              'Kfz Haftpflicht Basis',    'COMPANION','ACTIVE','2020-01-01'),
  ('CAR_FULL_BASE',            'CAR',           'BASE',  'Car Full Comp Base',        'Kfz Vollkasko Basis',      'COMPANION','ACTIVE','2020-01-01'),
  ('HOME_BUILDING_BASE',       'HOME_BUILDING', 'BASE',  'Home Building Base',        'Wohngebäude Basis',        'COMPANION','ACTIVE','2020-01-01'),
  ('HOME_CONTENTS_BASE',       'HOME_CONTENTS', 'BASE',  'Home Contents Base',        'Hausrat Basis',            'COMPANION','ACTIVE','2020-01-01'),
  ('PET_HEALTH_SURGICAL',      'PET_HEALTH',    'BASE',  'Pet Surgical Cover',        'Tier OP-Versicherung',     'COMPANION','ACTIVE','2020-01-01'),
  ('LIABILITY_BASE',           'LIABILITY',     'BASE',  'Personal Liability Base',   'Privathaftpflicht Basis',  'COMPANION','ACTIVE','2020-01-01'),
  ('ACCIDENT_BASE',            'ACCIDENT',      'BASE',  'Personal Accident Base',    'Unfallversicherung Basis', 'COMPANION','ACTIVE','2020-01-01'),
  ('CAR_NCD_PROTECTION',       'CAR',           'RIDER', 'NCD Protection Rider',      'SF-Schutz Baustein',       'RIDER',    'ACTIVE','2020-01-01'),
  ('CAR_ROADSIDE_ASSISTANCE',  'CAR',           'RIDER', 'Roadside Assistance Rider', 'Pannenhilfe Baustein',     'RIDER',    'ACTIVE','2020-01-01'),
  ('HOME_FLOOD_COVER',         'HOME_BUILDING', 'RIDER', 'Flood Cover Rider',         'Überschwemmungsschutz',    'RIDER',    'ACTIVE','2020-01-01'),
  ('HOME_VALUABLES_EXTENSION', 'HOME_CONTENTS', 'RIDER', 'High-Value Valuables Rider','Wertsachen-Erweiterung',   'RIDER',    'ACTIVE','2020-01-01'),
  ('PET_COMPREHENSIVE_HEALTH', 'PET_HEALTH',    'RIDER', 'Comprehensive Vet Rider',   'Vollschutz Tiergesundheit','RIDER',    'ACTIVE','2020-01-01')
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 2: Customers
-- ============================================================

INSERT INTO src.customer
  (customer_id, full_name, region_code, occupancy, dwelling_type, household_type,
   primary_earner, has_dependants, household_vehicle_count, payment_status,
   active_external_covers, external_policies_active)
VALUES
  -- Gatekeeper tests
  ('CUST-T001','Anna Müller',      'DE-BY','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T002','Ben Fischer',      'DE-BY','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T003','Cara Schmidt',     'DE-NW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'ARREARS',        '{}',                        '{}'),
  ('CUST-T004','David Klein',      'DE-NW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'DD_RETURNED',    '{}',                        '{}'),
  ('CUST-T005','Eva Braun',        'DE-HH','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T006','Felix Bauer',      'DE-HH','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T007','Greta Wolf',       'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T008','Hans Weber',       'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T009','Ida Richter',      'DE-BW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T010','Jan Krause',       'DE-BW','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T011','Kira Lange',       'DE-SN','TENANT',        'APARTMENT',   'SINGLE',       false,false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T012','Leo Fuchs',        'DE-SN','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 1,'CURRENT',        '{}',                        '{}'),
  -- UP-CAR-01
  ('CUST-T013','Mia Hartmann',     'DE-BY','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T014','Noah Schulz',      'DE-BY','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T015','Ola Vogel',        'DE-NW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T016','Paul König',       'DE-NW','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  -- UP-CAR-02
  ('CUST-T017','Quin Zimmer',      'DE-HH','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T018','Rosa Hoffmann',    'DE-HH','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T019','Sam Keller',       'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T020','Tina Berg',        'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  -- UP-CAR-03
  ('CUST-T021','Uma Herrmann',     'DE-BW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T022','Viktor Brandt',    'DE-BW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T023','Wendy Frank',      'DE-BY','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,2,'CURRENT',        '{}',                        '{}'),
  ('CUST-T024','Xeno Gruber',      'DE-BY','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  -- UP-HOM-01
  ('CUST-T025','Yara Huber',       'DE-BY','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T026','Zoe Maier',        'DE-BY','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T027','Ali Becker',       'DE-NW','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T028','Bea Lorenz',       'DE-NW','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  -- UP-HOM-02
  ('CUST-T029','Carl Schmitt',     'DE-HH','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T030','Dana Kraus',       'DE-HH','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  -- UP-PET-01
  ('CUST-T031','Emil Braun',       'DE-BE','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T032','Fara Neumann',     'DE-BE','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T033','Gil Peters',       'DE-BW','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  -- CS-CAR-01
  ('CUST-T034','Hana Otto',        'DE-BW','TENANT',        'APARTMENT',   'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T035','Igor Lange',       'DE-BY','TENANT',        'APARTMENT',   'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T036','Jana Roth',        'DE-BY','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T037','Karl Weis',        'DE-NW','TENANT',        'APARTMENT',   'SINGLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  -- CS-CAR-02
  ('CUST-T038','Lena Sauer',       'DE-NW','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T039','Marc Böhm',        'DE-HH','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T040','Nina Koch',        'DE-HH','OWNER_OCCUPIER','DETACHED',    'COUPLE',       false,false,1,'CURRENT',        '{}',                        '{}'),
  ('CUST-T041','Olaf Stern',       'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,1,'CURRENT',        ARRAY['PERSONAL_DISABILITY'],       '{}'),
  -- CS-HOM-01
  ('CUST-T042','Pia Hoffmann',     'DE-BE','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T043','Rex Winter',       'DE-BW','TENANT',        'APARTMENT',   'SINGLE',       false,false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T044','Sara Kunze',       'DE-BW','OWNER_OCCUPIER','SEMI_DETACHED','COUPLE',      true, false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T045','Tom Haas',         'DE-BY','OWNER_OCCUPIER','DETACHED',    'FAMILY',       true, true, 0,'CURRENT',        '{}',                        '{}'),
  -- CS-PET-01
  ('CUST-T046','Una Schreiber',    'DE-BY','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        ARRAY['TPL']),
  ('CUST-T047','Vera Walther',     'DE-NW','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        ARRAY['TPL']),
  ('CUST-T048','Wulf Meyer',       'DE-NW','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T049','Xara Lehmann',     'DE-HH','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,1,'CURRENT',        '{}',                        ARRAY['FULL']),
  -- CS-LIA-01
  ('CUST-T050','Yuri Bauer',       'DE-HH','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T051','Zita Berg',        'DE-BE','OWNER_OCCUPIER','DETACHED',    'SINGLE',       true, false,0,'CURRENT',        '{}',                        '{}'),
  ('CUST-T052','Axel Vogt',        'DE-BE','OWNER_OCCUPIER','DETACHED',    'COUPLE',       true, false,0,'CURRENT',        '{}',                        '{}')
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 3: Consent Records
-- All GRANTED except T001 (REVOKED) and T002 (UNSPECIFIED)
-- ============================================================

INSERT INTO src.consent (customer_id, purpose, status, channel, captured_at, evidence_ref)
SELECT c.customer_id, 'ADVISORY_RENEWAL',
  CASE c.customer_id
    WHEN 'CUST-T001' THEN 'REVOKED'
    WHEN 'CUST-T002' THEN 'UNSPECIFIED'
    ELSE 'GRANTED'
  END,
  CASE c.customer_id WHEN 'CUST-T002' THEN NULL ELSE 'PORTAL' END,
  CASE c.customer_id WHEN 'CUST-T001' THEN '2026-09-01 10:00:00+00'::timestamptz
                     WHEN 'CUST-T002' THEN '2020-01-01 00:00:00+00'::timestamptz
                     ELSE '2024-01-01 08:00:00+00'::timestamptz END,
  CASE c.customer_id WHEN 'CUST-T001' THEN 'REVOC-2026-T001'
                     WHEN 'CUST-T002' THEN NULL
                     ELSE 'CONS-' || c.customer_id END
FROM src.customer c
WHERE c.customer_id LIKE 'CUST-T%'
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 4: Policies
-- Primary policy per customer + secondary where needed
-- ============================================================

INSERT INTO src.policy
  (policy_id, customer_id, lob_code, base_product_code, coverage_level,
   package_tier, status, inception_date, expiry_date,
   annual_premium_gross, payment_frequency)
VALUES
  -- === CAR policies (T001-T012, T013-T024, T034-T041) ===
  -- Gatekeepers T001-T012: Full Comp, inception 2022
  ('POL-CAR-T001','CUST-T001','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T002','CUST-T002','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T003','CUST-T003','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T004','CUST-T004','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T005','CUST-T005','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T006','CUST-T006','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T007','CUST-T007','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T008','CUST-T008','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T009','CUST-T009','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  -- T010 home (BR-05 litigation), T011 home (BR-06 mismatch) — see home block below
  ('POL-CAR-T012','CUST-T012','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  -- UP-CAR-01 (T013-T016): Full Comp (prerequisite for NCD rider)
  ('POL-CAR-T013','CUST-T013','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T014','CUST-T014','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T015','CUST-T015','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T016','CUST-T016','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  -- UP-CAR-02 (T017-T020): TPL (upgrade target)
  ('POL-CAR-T017','CUST-T017','CAR','CAR_TPL_BASE','TPL', NULL,'ACTIVE','2022-01-01','2026-12-31',280.00,'ANNUAL'),
  ('POL-CAR-T018','CUST-T018','CAR','CAR_TPL_BASE','TPL', NULL,'ACTIVE','2022-01-01','2026-12-31',280.00,'ANNUAL'),
  ('POL-CAR-T019','CUST-T019','CAR','CAR_TPL_BASE','TPL', NULL,'ACTIVE','2022-01-01','2026-12-31',280.00,'ANNUAL'),
  ('POL-CAR-T020','CUST-T020','CAR','CAR_TPL_BASE','TPL', NULL,'ACTIVE','2022-01-01','2026-12-31',280.00,'ANNUAL'),
  -- UP-CAR-03 (T021-T024): Full Comp
  ('POL-CAR-T021','CUST-T021','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T022','CUST-T022','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T023','CUST-T023','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T024','CUST-T024','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  -- CS-CAR-01 (T034-T037): Car policies
  ('POL-CAR-T034','CUST-T034','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T035','CUST-T035','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T036','CUST-T036','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T037','CUST-T037','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  -- CS-CAR-02 (T038-T041): Car policies
  ('POL-CAR-T038','CUST-T038','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T039','CUST-T039','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T040','CUST-T040','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),
  ('POL-CAR-T041','CUST-T041','CAR','CAR_FULL_BASE','FULL',NULL,'ACTIVE','2022-01-01','2026-12-31',620.00,'ANNUAL'),

  -- === HOME BUILDING policies ===
  -- T010 BR-05 (litigation claim)
  ('POL-HBL-T010','CUST-T010','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  -- T011 BR-06 (tenant mismatch)
  ('POL-HBL-T011','CUST-T011','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  -- UP-HOM-01 (T025-T028)
  ('POL-HBL-T025','CUST-T025','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T026','CUST-T026','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T027','CUST-T027','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T028','CUST-T028','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  -- CS-HOM-01 (T042-T045): Home Building
  ('POL-HBL-T042','CUST-T042','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T043','CUST-T043','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T044','CUST-T044','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  ('POL-HBL-T045','CUST-T045','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),
  -- T035 second policy (makes active_policy_count=2 → CS-CAR-01 fails)
  ('POL-HBL-T035','CUST-T035','HOME_BUILDING','HOME_BUILDING_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',410.00,'ANNUAL'),

  -- === HOME CONTENTS policies ===
  -- UP-HOM-02 (T029-T030)
  ('POL-HCN-T029','CUST-T029','HOME_CONTENTS','HOME_CONTENTS_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',220.00,'ANNUAL'),
  ('POL-HCN-T030','CUST-T030','HOME_CONTENTS','HOME_CONTENTS_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',220.00,'ANNUAL'),
  -- T045 second policy (CS-HOM-01 ALREADY_COVERED)
  ('POL-HCN-T045','CUST-T045','HOME_CONTENTS','HOME_CONTENTS_BASE',NULL,NULL,'ACTIVE','2021-01-01','2026-12-31',220.00,'ANNUAL'),

  -- === PET_HEALTH policies ===
  -- UP-PET-01 (T031-T033)
  ('POL-PET-T031','CUST-T031','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-06-01','2026-12-31',185.00,'ANNUAL'),
  ('POL-PET-T032','CUST-T032','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-06-01','2026-12-31',185.00,'ANNUAL'),
  ('POL-PET-T033','CUST-T033','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-06-01','2026-12-31',185.00,'ANNUAL'),
  -- CS-PET-01 (T046-T049)
  ('POL-PET-T046','CUST-T046','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',185.00,'ANNUAL'),
  ('POL-PET-T047','CUST-T047','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',185.00,'ANNUAL'),
  ('POL-PET-T048','CUST-T048','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',185.00,'ANNUAL'),
  ('POL-PET-T049','CUST-T049','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',185.00,'ANNUAL'),
  -- T052 second policy (CS-LIA-01 ALREADY_COVERED)
  ('POL-PET-T052','CUST-T052','PET_HEALTH','PET_HEALTH_SURGICAL',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',185.00,'ANNUAL'),

  -- === LIABILITY policies ===
  -- CS-LIA-01 (T050-T052): primary renewal policy
  ('POL-LIA-T050','CUST-T050','LIABILITY','LIABILITY_BASE',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',155.00,'ANNUAL'),
  ('POL-LIA-T051','CUST-T051','LIABILITY','LIABILITY_BASE',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',155.00,'ANNUAL'),
  ('POL-LIA-T052','CUST-T052','LIABILITY','LIABILITY_BASE',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',155.00,'ANNUAL'),
  -- T037 second policy (CS-CAR-01 ALREADY_COVERED: has liability)
  ('POL-LIA-T037','CUST-T037','LIABILITY','LIABILITY_BASE',NULL,NULL,'ACTIVE','2022-01-01','2026-12-31',155.00,'ANNUAL')

ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 5: Policy Modules (riders already attached = ALREADY_COVERED)
-- ============================================================

INSERT INTO src.policy_module (policy_id, product_code, attached_at) VALUES
  ('POL-CAR-T016','CAR_NCD_PROTECTION',      '2024-06-01'), -- T016 UP-CAR-01 ALREADY_COVERED
  ('POL-CAR-T024','CAR_ROADSIDE_ASSISTANCE',  '2024-06-01'), -- T024 UP-CAR-03 ALREADY_COVERED
  ('POL-HBL-T028','HOME_FLOOD_COVER',         '2024-06-01'), -- T028 UP-HOM-01 ALREADY_COVERED
  ('POL-HCN-T029','HOME_VALUABLES_EXTENSION', '2024-06-01')  -- T029? No, T029 is ELIGIBLE; no module
ON CONFLICT DO NOTHING;

-- Fix: T029 is ELIGIBLE (no module). Remove that last row and add correct ones:
-- T028 flood cover already handled above.
-- UP-HOM-02: no ALREADY_COVERED test customer (T029=ELIGIBLE, T030=DISQ). Keep as is.
-- (The T029 home_valuables_extension insert above is intentionally absent for T029 ELIGIBLE.)
-- Re-insert correctly (the INSERT above has it — just ignore T029 line if it errors; using ON CONFLICT):

-- Actually: let's clean up — T029 should NOT have the valuables extension (it's ELIGIBLE).
-- The INSERT above already uses ON CONFLICT DO NOTHING. Just note: ('POL-HCN-T029','HOME_VALUABLES_EXTENSION')
-- should NOT be there. Corrected version below overrides with a DELETE if needed:
DELETE FROM src.policy_module WHERE policy_id='POL-HCN-T029' AND product_code='HOME_VALUABLES_EXTENSION';

-- ============================================================
-- SECTION 6: Insured Assets
-- ============================================================

-- src.insured_vehicle
INSERT INTO src.insured_vehicle
  (policy_id, make_model, build_year, first_registration, market_value, market_value_as_of,
   annual_km, annual_km_verified, bonus_tier, demerit_points)
VALUES
  -- Gatekeepers (T001-T009, T012): standard full-comp car, clean profile
  ('POL-CAR-T001','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T002','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T003','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T004','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T005','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T006','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T007','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T008','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 0),
  ('POL-CAR-T009','VW Golf 8',      2021,'2021-03-01',14500.00,'2026-01-01',14000,true, 10, 5), -- demerit_points=5
  ('POL-CAR-T012','BMW 3 Series',   2022,'2022-04-01',22000.00,'2026-01-01',15000,true, 12, 0),
  -- UP-CAR-01 (T013-T016)
  ('POL-CAR-T013','Audi A4',        2020,'2020-06-01',16000.00,'2026-01-01',15000,true, 10, 0), -- ELIGIBLE
  ('POL-CAR-T014','Audi A4',        2020,'2020-06-01',16000.00,'2026-01-01',15000,true,  6, 0), -- bonus_tier=6 < 8 → DISQ
  ('POL-CAR-T015','Audi A4',        2020,'2020-06-01',16000.00,'2026-01-01',15000,true, 10, 0), -- at-fault claim via src.claim
  ('POL-CAR-T016','Audi A4',        2020,'2020-06-01',16000.00,'2026-01-01',15000,true, 10, 0), -- NCD rider in policy_module
  -- UP-CAR-02 (T017-T020): TPL vehicles
  ('POL-CAR-T017','Ford Focus',     2021,'2021-05-01',12000.00,'2026-01-01',12000,true,  8, 0), -- ELIGIBLE: value>=8k, age<=8
  ('POL-CAR-T018','Ford Focus',     2021,'2021-05-01', 5000.00,'2026-01-01',12000,true,  8, 0), -- DISQ: value=5000 < 8000
  ('POL-CAR-T019','Ford Focus',     2015,'2015-03-01', 9000.00,'2026-01-01',12000,true,  8, 0), -- DISQ: build_year=2015 → age=11
  ('POL-CAR-T020','Ford Focus',     2021,'2021-05-01',12000.00,'2026-01-01',12000,true,  8, 0), -- DISQ: at-fault claim in 12mo
  -- UP-CAR-03 (T021-T024)
  ('POL-CAR-T021','Toyota Corolla', 2022,'2022-01-01',18000.00,'2026-01-01',15000,true, 10, 0), -- ELIGIBLE: km=15000, hh=1
  ('POL-CAR-T022','Toyota Corolla', 2022,'2022-01-01',18000.00,'2026-01-01', 8000,true, 10, 0), -- DISQ: km=8000 < 12000
  ('POL-CAR-T023','Toyota Corolla', 2022,'2022-01-01',18000.00,'2026-01-01',15000,true, 10, 0), -- DISQ: household_vehicle_count=2
  ('POL-CAR-T024','Toyota Corolla', 2022,'2022-01-01',18000.00,'2026-01-01',15000,true, 10, 0), -- roadside rider in policy_module
  -- CS-CAR-01 (T034-T037)
  ('POL-CAR-T034','Seat Leon',      2021,'2021-09-01',13000.00,'2026-01-01',12000,true,  9, 0),
  ('POL-CAR-T035','Seat Leon',      2021,'2021-09-01',13000.00,'2026-01-01',12000,true,  9, 0),
  ('POL-CAR-T036','Seat Leon',      2021,'2021-09-01',13000.00,'2026-01-01',12000,true,  9, 0),
  ('POL-CAR-T037','Seat Leon',      2021,'2021-09-01',13000.00,'2026-01-01',12000,true,  9, 0),
  -- CS-CAR-02 (T038-T041)
  ('POL-CAR-T038','Mercedes C200',  2022,'2022-03-01',25000.00,'2026-01-01',16000,true, 11, 0), -- ELIGIBLE: km=16000
  ('POL-CAR-T039','Mercedes C200',  2022,'2022-03-01',25000.00,'2026-01-01',12000,true, 11, 0), -- DISQ: km=12000 < 15000
  ('POL-CAR-T040','Mercedes C200',  2022,'2022-03-01',25000.00,'2026-01-01',16000,true, 11, 0), -- DISQ: primary_earner=false
  ('POL-CAR-T041','Mercedes C200',  2022,'2022-03-01',25000.00,'2026-01-01',16000,true, 11, 0)  -- DISQ: has PERSONAL_DISABILITY
ON CONFLICT DO NOTHING;

-- src.insured_property
INSERT INTO src.insured_property
  (policy_id, dwelling_type, build_year, floor_area_sqm,
   zuers_zone, heavy_rain_class, backwater_valve_certified,
   has_solar_or_heatpump, basement_or_ground_floor_storage)
VALUES
  -- BR-05 T010 litigation (home)
  ('POL-HBL-T010','DETACHED',1985,160,  2,2,true, false,true),
  -- BR-06 T011 mismatch (tenant, home)
  ('POL-HBL-T011','APARTMENT',2005,75,  1,1,false,false,false),
  -- UP-HOM-01
  ('POL-HBL-T025','DETACHED',1990,150,  2,2,true, false,true),  -- ELIGIBLE: zone=2
  ('POL-HBL-T026','DETACHED',1990,150,  4,3,false,false,true),  -- REFERRAL: zone=4
  ('POL-HBL-T027','DETACHED',1990,150,  2,2,true, false,false), -- DISQ: WATER claim in 24mo
  ('POL-HBL-T028','DETACHED',1990,150,  2,2,true, false,false), -- ALREADY_COVERED: flood module attached
  -- CS-HOM-01
  ('POL-HBL-T042','DETACHED',2000,160,  1,1,false,false,false), -- ELIGIBLE: floor=160
  ('POL-HBL-T043','APARTMENT',2005,80,  1,1,false,false,false), -- NOT_APPLICABLE: TENANT
  ('POL-HBL-T044','SEMI_DETACHED',1995,120,1,1,false,false,false),-- DISQ: floor=120 < 140
  ('POL-HBL-T045','DETACHED',2001,155,  1,1,false,false,false), -- ALREADY_COVERED: has HCN
  ('POL-HBL-T035','DETACHED',2003,140,  1,1,false,false,false), -- T035 second policy (home)
  -- UP-HOM-02 (Home Contents — floor_area matters)
  ('POL-HCN-T029','DETACHED',2001,150,  1,1,false,false,false), -- ELIGIBLE: floor=150
  ('POL-HCN-T030','DETACHED',2001,100,  1,1,false,false,false), -- DISQ: floor=100 < 120
  ('POL-HCN-T045','DETACHED',2001,155,  1,1,false,false,false)  -- T045 second (contents)
ON CONFLICT DO NOTHING;

-- src.insured_animal
INSERT INTO src.insured_animal (policy_id, animal_ref, species, breed, birth_year) VALUES
  ('POL-PET-T031','A001','DOG','Labrador',  2019), -- UP-PET-01 ELIGIBLE: age=7
  ('POL-PET-T032','A001','CAT','Siamese',   2013), -- UP-PET-01 DISQ: age=13 > 7
  ('POL-PET-T033','A001','DOG','Beagle',    2019), -- UP-PET-01 DISQ: 2 minor VET claims
  ('POL-PET-T046','A001','DOG','Golden R.', 2020), -- CS-PET-01 ELIGIBLE: age=6, claim-free
  ('POL-PET-T047','A001','DOG','Dachshund', 2020), -- CS-PET-01 DISQ: has claim
  ('POL-PET-T048','A001','CAT','British S.', 2020),-- CS-PET-01 NOT_APPLICABLE: no ext motor
  ('POL-PET-T049','A001','DOG','Poodle',    2020), -- CS-PET-01 NOT_APPLICABLE: ext motor=FULL
  ('POL-PET-T052','A001','DOG','Boxer',     2021)  -- CS-LIA-01 ALREADY_COVERED
ON CONFLICT DO NOTHING;

-- src.customer_declared_fact (dog/horse ownership for CS-LIA-01)
INSERT INTO src.customer_declared_fact
  (customer_id, fact_key, value, source, verified, declared_at)
VALUES
  ('CUST-T050','dog_owner','{"owned":true}', 'CSR_CALL',true, '2025-03-01'), -- ELIGIBLE
  ('CUST-T052','dog_owner','{"owned":true}', 'CSR_CALL',true, '2025-03-01')  -- ALREADY_COVERED
ON CONFLICT DO NOTHING;

COMMIT;
