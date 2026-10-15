-- ============================================================
-- SRA Test Seed  —  Part 2 of 2
-- Run AFTER: seed_part1.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECTION 7: Claims
-- Date reference: today = 2026-10-15
--   within 12mo  → loss_date >= 2025-10-15
--   within 24mo  → loss_date >= 2024-10-15
--   within 36mo  → loss_date >= 2023-10-15
--   within 180d  → loss_date >= 2026-04-18  (for BR-03 disputed)
--   within 3yr   → reported_date >= 2023-10-15 (for CS-PET-01)
-- ============================================================

INSERT INTO src.claim
  (claim_id, policy_id, customer_id, loss_date, reported_date, peril,
   at_fault, severity, status, status_changed_at)
VALUES
  -- T006: BR-03 → DISPUTED claim within 180 days
  ('CLM-T006-01','POL-CAR-T006','CUST-T006','2026-05-10','2026-05-12','COLLISION',
   true,'MAJOR','DISPUTED','2026-05-12 10:00:00+00'),

  -- T008: BR-05 → 2 at-fault claims in 24mo
  ('CLM-T008-01','POL-CAR-T008','CUST-T008','2025-03-01','2025-03-03','COLLISION',
   true,'MAJOR','CLOSED','2025-06-01 10:00:00+00'),
  ('CLM-T008-02','POL-CAR-T008','CUST-T008','2026-01-15','2026-01-17','COLLISION',
   true,'MAJOR','CLOSED','2026-04-01 10:00:00+00'),

  -- T010: BR-05 (property) → open LITIGATION claim
  ('CLM-T010-01','POL-HBL-T010','CUST-T010','2025-08-01','2025-08-05','WATER',
   false,'MAJOR','LITIGATION','2026-01-15 10:00:00+00'),

  -- T015: UP-CAR-01 → 1 at-fault claim in 36mo (disqualifies NCD rider)
  ('CLM-T015-01','POL-CAR-T015','CUST-T015','2024-06-10','2024-06-12','COLLISION',
   true,'MAJOR','CLOSED','2024-09-01 10:00:00+00'),

  -- T020: UP-CAR-02 → 1 at-fault claim in 12mo (disqualifies upgrade)
  ('CLM-T020-01','POL-CAR-T020','CUST-T020','2026-03-20','2026-03-22','COLLISION',
   true,'MINOR','CLOSED','2026-05-01 10:00:00+00'),

  -- T027: UP-HOM-01 → open WATER damage claim in 24mo
  ('CLM-T027-01','POL-HBL-T027','CUST-T027','2025-07-15','2025-07-18','WATER',
   false,'MAJOR','OPEN','2025-07-18 10:00:00+00'),

  -- T033: UP-PET-01 → 2 minor VET claims in 24mo (> 1 allowed)
  ('CLM-T033-01','POL-PET-T033','CUST-T033','2025-04-01','2025-04-03','VET',
   false,'MINOR','CLOSED','2025-06-01 10:00:00+00'),
  ('CLM-T033-02','POL-PET-T033','CUST-T033','2026-02-10','2026-02-12','VET',
   false,'MINOR','CLOSED','2026-04-01 10:00:00+00'),

  -- T047: CS-PET-01 → 1 claim within last 3 years (disqualifies claim-free loyalty)
  ('CLM-T047-01','POL-PET-T047','CUST-T047','2024-11-20','2024-11-22','VET',
   false,'MINOR','CLOSED','2025-01-15 10:00:00+00')

ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 8: Complaints
-- T005: BR-03 → open complaint within 180 days
-- ============================================================

INSERT INTO src.complaint (complaint_id, customer_id, opened_at, status, closed_at) VALUES
  ('COMP-T005-01','CUST-T005','2026-06-01 09:00:00+00','OPEN',NULL)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 9: Renewal Quotes
-- One per customer — linked to their primary policy
-- renewal_date=2026-12-01, letter_due_date=2026-11-10
-- ============================================================

INSERT INTO src.renewal_quote
  (quote_id, policy_id, created_at, status, renewal_date, letter_due_date,
   expiring_premium_gross, renewal_premium_gross, renewal_insurance_tax)
VALUES
  ('QUO-T001','POL-CAR-T001', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T002','POL-CAR-T002', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T003','POL-CAR-T003', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T004','POL-CAR-T004', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T005','POL-CAR-T005', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T006','POL-CAR-T006', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T007','POL-CAR-T007', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T008','POL-CAR-T008', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T009','POL-CAR-T009', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T010','POL-HBL-T010', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T011','POL-HBL-T011', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T012','POL-CAR-T012', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T013','POL-CAR-T013', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T014','POL-CAR-T014', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T015','POL-CAR-T015', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T016','POL-CAR-T016', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T017','POL-CAR-T017', now(),'QUOTED','2026-12-01','2026-11-10', 280.00, 294.00,  46.90),
  ('QUO-T018','POL-CAR-T018', now(),'QUOTED','2026-12-01','2026-11-10', 280.00, 294.00,  46.90),
  ('QUO-T019','POL-CAR-T019', now(),'QUOTED','2026-12-01','2026-11-10', 280.00, 294.00,  46.90),
  ('QUO-T020','POL-CAR-T020', now(),'QUOTED','2026-12-01','2026-11-10', 280.00, 294.00,  46.90),
  ('QUO-T021','POL-CAR-T021', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T022','POL-CAR-T022', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T023','POL-CAR-T023', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T024','POL-CAR-T024', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T025','POL-HBL-T025', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T026','POL-HBL-T026', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T027','POL-HBL-T027', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T028','POL-HBL-T028', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T029','POL-HCN-T029', now(),'QUOTED','2026-12-01','2026-11-10', 220.00, 231.00,  36.90),
  ('QUO-T030','POL-HCN-T030', now(),'QUOTED','2026-12-01','2026-11-10', 220.00, 231.00,  36.90),
  ('QUO-T031','POL-PET-T031', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T032','POL-PET-T032', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T033','POL-PET-T033', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T034','POL-CAR-T034', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T035','POL-CAR-T035', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T036','POL-CAR-T036', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T037','POL-CAR-T037', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T038','POL-CAR-T038', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T039','POL-CAR-T039', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T040','POL-CAR-T040', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T041','POL-CAR-T041', now(),'QUOTED','2026-12-01','2026-11-10', 620.00, 651.00, 103.90),
  ('QUO-T042','POL-HBL-T042', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T043','POL-HBL-T043', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T044','POL-HBL-T044', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T045','POL-HBL-T045', now(),'QUOTED','2026-12-01','2026-11-10', 410.00, 430.50,  68.70),
  ('QUO-T046','POL-PET-T046', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T047','POL-PET-T047', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T048','POL-PET-T048', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T049','POL-PET-T049', now(),'QUOTED','2026-12-01','2026-11-10', 185.00, 194.25,  31.00),
  ('QUO-T050','POL-LIA-T050', now(),'QUOTED','2026-12-01','2026-11-10', 155.00, 162.75,  25.90),
  ('QUO-T051','POL-LIA-T051', now(),'QUOTED','2026-12-01','2026-11-10', 155.00, 162.75,  25.90),
  ('QUO-T052','POL-LIA-T052', now(),'QUOTED','2026-12-01','2026-11-10', 155.00, 162.75,  25.90)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 10: SRA Renewal Cases
-- case_id uses predictable UUIDs: c0000000-0000-0000-0000-{N padded to 12 hex}
-- All start as RECEIVED (engine runs against these)
-- ============================================================

INSERT INTO sra.renewal_case
  (case_id, quote_id, quote_version, policy_id, customer_id, lob_code,
   customer_display_name, renewal_date, letter_due_date,
   expiring_premium, renewal_premium, state, retention_class)
VALUES
  ('c0000000-0000-0000-0000-000000000001','QUO-T001',1,'POL-CAR-T001','CUST-T001','CAR','A. Müller','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000002','QUO-T002',1,'POL-CAR-T002','CUST-T002','CAR','B. Fischer','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000003','QUO-T003',1,'POL-CAR-T003','CUST-T003','CAR','C. Schmidt','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000004','QUO-T004',1,'POL-CAR-T004','CUST-T004','CAR','D. Klein','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000005','QUO-T005',1,'POL-CAR-T005','CUST-T005','CAR','E. Braun','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000006','QUO-T006',1,'POL-CAR-T006','CUST-T006','CAR','F. Bauer','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000007','QUO-T007',1,'POL-CAR-T007','CUST-T007','CAR','G. Wolf','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000008','QUO-T008',1,'POL-CAR-T008','CUST-T008','CAR','H. Weber','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000009','QUO-T009',1,'POL-CAR-T009','CUST-T009','CAR','I. Richter','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000010','QUO-T010',1,'POL-HBL-T010','CUST-T010','HOME_BUILDING','J. Krause','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000011','QUO-T011',1,'POL-HBL-T011','CUST-T011','HOME_BUILDING','K. Lange','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000012','QUO-T012',1,'POL-CAR-T012','CUST-T012','CAR','L. Fuchs','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000013','QUO-T013',1,'POL-CAR-T013','CUST-T013','CAR','M. Hartmann','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000014','QUO-T014',1,'POL-CAR-T014','CUST-T014','CAR','N. Schulz','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000015','QUO-T015',1,'POL-CAR-T015','CUST-T015','CAR','O. Vogel','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000016','QUO-T016',1,'POL-CAR-T016','CUST-T016','CAR','P. König','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000017','QUO-T017',1,'POL-CAR-T017','CUST-T017','CAR','Q. Zimmer','2026-12-01','2026-11-10',280.00,294.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000018','QUO-T018',1,'POL-CAR-T018','CUST-T018','CAR','R. Hoffmann','2026-12-01','2026-11-10',280.00,294.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000019','QUO-T019',1,'POL-CAR-T019','CUST-T019','CAR','S. Keller','2026-12-01','2026-11-10',280.00,294.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000020','QUO-T020',1,'POL-CAR-T020','CUST-T020','CAR','T. Berg','2026-12-01','2026-11-10',280.00,294.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000021','QUO-T021',1,'POL-CAR-T021','CUST-T021','CAR','U. Herrmann','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000022','QUO-T022',1,'POL-CAR-T022','CUST-T022','CAR','V. Brandt','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000023','QUO-T023',1,'POL-CAR-T023','CUST-T023','CAR','W. Frank','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000024','QUO-T024',1,'POL-CAR-T024','CUST-T024','CAR','X. Gruber','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000025','QUO-T025',1,'POL-HBL-T025','CUST-T025','HOME_BUILDING','Y. Huber','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000026','QUO-T026',1,'POL-HBL-T026','CUST-T026','HOME_BUILDING','Z. Maier','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000027','QUO-T027',1,'POL-HBL-T027','CUST-T027','HOME_BUILDING','A. Becker','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000028','QUO-T028',1,'POL-HBL-T028','CUST-T028','HOME_BUILDING','B. Lorenz','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000029','QUO-T029',1,'POL-HCN-T029','CUST-T029','HOME_CONTENTS','C. Schmitt','2026-12-01','2026-11-10',220.00,231.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000030','QUO-T030',1,'POL-HCN-T030','CUST-T030','HOME_CONTENTS','D. Kraus','2026-12-01','2026-11-10',220.00,231.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000031','QUO-T031',1,'POL-PET-T031','CUST-T031','PET_HEALTH','E. Braun','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000032','QUO-T032',1,'POL-PET-T032','CUST-T032','PET_HEALTH','F. Neumann','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000033','QUO-T033',1,'POL-PET-T033','CUST-T033','PET_HEALTH','G. Peters','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000034','QUO-T034',1,'POL-CAR-T034','CUST-T034','CAR','H. Otto','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000035','QUO-T035',1,'POL-CAR-T035','CUST-T035','CAR','I. Lange','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000036','QUO-T036',1,'POL-CAR-T036','CUST-T036','CAR','J. Roth','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000037','QUO-T037',1,'POL-CAR-T037','CUST-T037','CAR','K. Weis','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000038','QUO-T038',1,'POL-CAR-T038','CUST-T038','CAR','L. Sauer','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000039','QUO-T039',1,'POL-CAR-T039','CUST-T039','CAR','M. Böhm','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000040','QUO-T040',1,'POL-CAR-T040','CUST-T040','CAR','N. Koch','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000041','QUO-T041',1,'POL-CAR-T041','CUST-T041','CAR','O. Stern','2026-12-01','2026-11-10',620.00,651.00,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000042','QUO-T042',1,'POL-HBL-T042','CUST-T042','HOME_BUILDING','P. Hoffmann','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000043','QUO-T043',1,'POL-HBL-T043','CUST-T043','HOME_BUILDING','R. Winter','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000044','QUO-T044',1,'POL-HBL-T044','CUST-T044','HOME_BUILDING','S. Kunze','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000045','QUO-T045',1,'POL-HBL-T045','CUST-T045','HOME_BUILDING','T. Haas','2026-12-01','2026-11-10',410.00,430.50,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000046','QUO-T046',1,'POL-PET-T046','CUST-T046','PET_HEALTH','U. Schreiber','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000047','QUO-T047',1,'POL-PET-T047','CUST-T047','PET_HEALTH','V. Walther','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000048','QUO-T048',1,'POL-PET-T048','CUST-T048','PET_HEALTH','W. Meyer','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000049','QUO-T049',1,'POL-PET-T049','CUST-T049','PET_HEALTH','X. Lehmann','2026-12-01','2026-11-10',185.00,194.25,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000050','QUO-T050',1,'POL-LIA-T050','CUST-T050','LIABILITY','Y. Bauer','2026-12-01','2026-11-10',155.00,162.75,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000051','QUO-T051',1,'POL-LIA-T051','CUST-T051','LIABILITY','Z. Berg','2026-12-01','2026-11-10',155.00,162.75,'RECEIVED','ADVICE_RECORD'),
  ('c0000000-0000-0000-0000-000000000052','QUO-T052',1,'POL-LIA-T052','CUST-T052','LIABILITY','A. Vogt','2026-12-01','2026-11-10',155.00,162.75,'RECEIVED','ADVICE_RECORD')
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 11: Policy Snapshots
-- decision_context is what the rule engine reads at evaluation time.
-- context_sha256 is computed from the decision_context text.
-- Each JSON contains ONLY the fields that matter for that customer's rules.
-- The Fact Builder populates this in production; here we set it directly.
-- ============================================================

INSERT INTO sra.policy_snapshot
  (snapshot_id, case_id, source_event_id, raw_payload, decision_context, context_sha256, fact_builder_version)
SELECT snapshot_id::uuid, case_id::uuid, source_event_id,
       raw_payload::jsonb, dc::jsonb,
       encode(digest(dc, 'sha256'), 'hex'),
       '1.0.0-seed'
FROM (VALUES

  -- T001: BR-01 → consent REVOKED
  ('a0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','SEED-T001',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"REVOKED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T002: BR-01 → consent UNSPECIFIED
  ('a0000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000002','SEED-T002',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"UNSPECIFIED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T003: BR-02 → payment ARREARS
  ('a0000000-0000-0000-0000-000000000003','c0000000-0000-0000-0000-000000000003','SEED-T003',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"ARREARS","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T004: BR-02 → payment DD_RETURNED
  ('a0000000-0000-0000-0000-000000000004','c0000000-0000-0000-0000-000000000004','SEED-T004',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"DD_RETURNED","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T005: BR-03 → open complaint (open_complaint_count=1)
  ('a0000000-0000-0000-0000-000000000005','c0000000-0000-0000-0000-000000000005','SEED-T005',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":1,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T006: BR-03 → disputed claim (disputed_claim_count=1)
  ('a0000000-0000-0000-0000-000000000006','c0000000-0000-0000-0000-000000000006','SEED-T006',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":1},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T007: BR-04 → CAR_NCD_PROTECTION in cooldown
  ('a0000000-0000-0000-0000-000000000007','c0000000-0000-0000-0000-000000000007','SEED-T007',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":["CAR_NCD_PROTECTION"]}}'),

  -- T008: BR-05 → at_fault_24mo=2
  ('a0000000-0000-0000-0000-000000000008','c0000000-0000-0000-0000-000000000008','SEED-T008',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":2,"at_fault_36mo":2,"minor_36mo":0,"at_fault_12mo":1,"open_litigation_count":0,"claim_free_years_all_policies":0},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T009: BR-05 → demerit_points=5
  ('a0000000-0000-0000-0000-000000000009','c0000000-0000-0000-0000-000000000009','SEED-T009',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":14500,"build_year":2021,"demerit_points":5},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T010: BR-05 → open_litigation_count=1 (property)
  ('a0000000-0000-0000-0000-000000000010','c0000000-0000-0000-0000-000000000010','SEED-T010',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":2,"floor_area_sqm":160,"backwater_valve_certified":true,"basement_or_ground_floor_storage":true},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":1,"claim_free_years_all_policies":0},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T011: BR-06 → TENANT + HOME_BUILDING (target market mismatch)
  ('a0000000-0000-0000-0000-000000000011','c0000000-0000-0000-0000-000000000011','SEED-T011',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"TENANT","household_vehicle_count":0,"primary_earner":false,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":75,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T012: All GK PASS (baseline clean car customer)
  ('a0000000-0000-0000-0000-000000000012','c0000000-0000-0000-0000-000000000012','SEED-T012',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":12,"annual_km":15000,"annual_km_verified":true,"market_value":22000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T013: UP-CAR-01 ELIGIBLE
  ('a0000000-0000-0000-0000-000000000013','c0000000-0000-0000-0000-000000000013','SEED-T013',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":16000,"build_year":2020,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T014: UP-CAR-01 DISQ bonus_tier=6
  ('a0000000-0000-0000-0000-000000000014','c0000000-0000-0000-0000-000000000014','SEED-T014',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":6,"annual_km":15000,"annual_km_verified":true,"market_value":16000,"build_year":2020,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":3},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T015: UP-CAR-01 DISQ at_fault_36mo=1
  ('a0000000-0000-0000-0000-000000000015','c0000000-0000-0000-0000-000000000015','SEED-T015',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":16000,"build_year":2020,"demerit_points":0},"claims":{"at_fault_24mo":1,"at_fault_36mo":1,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":0},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T016: UP-CAR-01 ALREADY_COVERED (ncd_protection=true)
  ('a0000000-0000-0000-0000-000000000016','c0000000-0000-0000-0000-000000000016','SEED-T016',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":16000,"build_year":2020,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"ncd_protection":true,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T017: UP-CAR-02 ELIGIBLE (TPL, value=12000, build_year=2021, 0 claims 12mo)
  ('a0000000-0000-0000-0000-000000000017','c0000000-0000-0000-0000-000000000017','SEED-T017',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"TPL","bonus_tier":8,"annual_km":12000,"annual_km_verified":true,"market_value":12000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":1,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":3},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T018: UP-CAR-02 DISQ market_value=5000
  ('a0000000-0000-0000-0000-000000000018','c0000000-0000-0000-0000-000000000018','SEED-T018',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"TPL","bonus_tier":8,"annual_km":12000,"annual_km_verified":true,"market_value":5000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":3},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T019: UP-CAR-02 DISQ build_year=2015 (age=11 > 8)
  ('a0000000-0000-0000-0000-000000000019','c0000000-0000-0000-0000-000000000019','SEED-T019',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"TPL","bonus_tier":8,"annual_km":12000,"annual_km_verified":true,"market_value":9000,"build_year":2015,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":3},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T020: UP-CAR-02 DISQ at_fault_12mo=1
  ('a0000000-0000-0000-0000-000000000020','c0000000-0000-0000-0000-000000000020','SEED-T020',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"TPL","bonus_tier":8,"annual_km":12000,"annual_km_verified":true,"market_value":12000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":1,"at_fault_36mo":1,"minor_36mo":0,"at_fault_12mo":1,"open_litigation_count":0,"claim_free_years_all_policies":0},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T021: UP-CAR-03 ELIGIBLE (km=15000, hh_vehicle=1, no roadside rider)
  ('a0000000-0000-0000-0000-000000000021','c0000000-0000-0000-0000-000000000021','SEED-T021',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":18000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T022: UP-CAR-03 DISQ km=8000
  ('a0000000-0000-0000-0000-000000000022','c0000000-0000-0000-0000-000000000022','SEED-T022',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":8000,"annual_km_verified":true,"market_value":18000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T023: UP-CAR-03 DISQ household_vehicle_count=2
  ('a0000000-0000-0000-0000-000000000023','c0000000-0000-0000-0000-000000000023','SEED-T023',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":2,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":18000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T024: UP-CAR-03 ALREADY_COVERED (roadside_assistance=true)
  ('a0000000-0000-0000-0000-000000000024','c0000000-0000-0000-0000-000000000024','SEED-T024',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":10,"annual_km":15000,"annual_km_verified":true,"market_value":18000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":true},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T025: UP-HOM-01 ELIGIBLE (zuers_zone=2, backwater=true, no flood cover)
  ('a0000000-0000-0000-0000-000000000025','c0000000-0000-0000-0000-000000000025','SEED-T025',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":2,"floor_area_sqm":150,"backwater_valve_certified":true,"basement_or_ground_floor_storage":true},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"open_water_claims_24mo":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T026: UP-HOM-01 REFERRAL_REQUIRED (zuers_zone=4)
  ('a0000000-0000-0000-0000-000000000026','c0000000-0000-0000-0000-000000000026','SEED-T026',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":4,"floor_area_sqm":150,"backwater_valve_certified":false,"basement_or_ground_floor_storage":true},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"open_water_claims_24mo":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T027: UP-HOM-01 DISQ open WATER claim in 24mo
  ('a0000000-0000-0000-0000-000000000027','c0000000-0000-0000-0000-000000000027','SEED-T027',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":2,"floor_area_sqm":150,"backwater_valve_certified":true,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"open_water_claims_24mo":1,"claim_free_years_all_policies":0},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T028: UP-HOM-01 ALREADY_COVERED (flood_cover=true)
  ('a0000000-0000-0000-0000-000000000028','c0000000-0000-0000-0000-000000000028','SEED-T028',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":2,"floor_area_sqm":150,"backwater_valve_certified":true,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"open_water_claims_24mo":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":true},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T029: UP-HOM-02 ELIGIBLE (floor=150)
  ('a0000000-0000-0000-0000-000000000029','c0000000-0000-0000-0000-000000000029','SEED-T029',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":150,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"valuables_extension":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":true,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T030: UP-HOM-02 DISQ floor=100
  ('a0000000-0000-0000-0000-000000000030','c0000000-0000-0000-0000-000000000030','SEED-T030',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":100,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"valuables_extension":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":true,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T031: UP-PET-01 ELIGIBLE (pet birth_year=2019 age=7, 0 minor vet claims 24mo)
  ('a0000000-0000-0000-0000-000000000031','c0000000-0000-0000-0000-000000000031','SEED-T031',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2019,"species":"DOG","age_years":7},"claims":{"vet_minor_24mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T032: UP-PET-01 DISQ pet age=13
  ('a0000000-0000-0000-0000-000000000032','c0000000-0000-0000-0000-000000000032','SEED-T032',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2013,"species":"CAT","age_years":13},"claims":{"vet_minor_24mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T033: UP-PET-01 DISQ vet_minor_24mo=2
  ('a0000000-0000-0000-0000-000000000033','c0000000-0000-0000-0000-000000000033','SEED-T033',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2019,"species":"DOG","age_years":7},"claims":{"vet_minor_24mo":2,"open_litigation_count":0,"claim_free_years_all_policies":0},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T034: CS-CAR-01 ELIGIBLE (single policy, TENANT, no liability)
  ('a0000000-0000-0000-0000-000000000034','c0000000-0000-0000-0000-000000000034','SEED-T034',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"TENANT","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":9,"annual_km":12000,"annual_km_verified":true,"market_value":13000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T035: CS-CAR-01 NOT_APPLICABLE (active_policy_count=2)
  ('a0000000-0000-0000-0000-000000000035','c0000000-0000-0000-0000-000000000035','SEED-T035',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"TENANT","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":9,"annual_km":12000,"annual_km_verified":true,"market_value":13000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":2},"cooldown":{"active_products":[]}}'),

  -- T036: CS-CAR-01 NOT_APPLICABLE (OWNER_OCCUPIER)
  ('a0000000-0000-0000-0000-000000000036','c0000000-0000-0000-0000-000000000036','SEED-T036',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":9,"annual_km":12000,"annual_km_verified":true,"market_value":13000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T037: CS-CAR-01 ALREADY_COVERED (has_active_liability=true)
  ('a0000000-0000-0000-0000-000000000037','c0000000-0000-0000-0000-000000000037','SEED-T037',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"TENANT","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":9,"annual_km":12000,"annual_km_verified":true,"market_value":13000,"build_year":2021,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":true,"has_active_pet":false,"active_policy_count":2},"cooldown":{"active_products":[]}}'),

  -- T038: CS-CAR-02 ELIGIBLE (km=16000, primary_earner=true, no disability cover)
  ('a0000000-0000-0000-0000-000000000038','c0000000-0000-0000-0000-000000000038','SEED-T038',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":11,"annual_km":16000,"annual_km_verified":true,"market_value":25000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T039: CS-CAR-02 DISQ km=12000 < 15000
  ('a0000000-0000-0000-0000-000000000039','c0000000-0000-0000-0000-000000000039','SEED-T039',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":11,"annual_km":12000,"annual_km_verified":true,"market_value":25000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T040: CS-CAR-02 DISQ primary_earner=false
  ('a0000000-0000-0000-0000-000000000040','c0000000-0000-0000-0000-000000000040','SEED-T040',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":false,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":11,"annual_km":16000,"annual_km_verified":true,"market_value":25000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T041: CS-CAR-02 ALREADY_COVERED (PERSONAL_DISABILITY in active_external_covers)
  ('a0000000-0000-0000-0000-000000000041','c0000000-0000-0000-0000-000000000041','SEED-T041',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":["PERSONAL_DISABILITY"],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"vehicle":{"coverage_level":"FULL","bonus_tier":11,"annual_km":16000,"annual_km_verified":true,"market_value":25000,"build_year":2022,"demerit_points":0},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"ncd_protection":false,"roadside_assistance":false},"policies":{"has_active_car":true,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T042: CS-HOM-01 ELIGIBLE (OWNER_OCCUPIER, DETACHED, floor=160, no contents)
  ('a0000000-0000-0000-0000-000000000042','c0000000-0000-0000-0000-000000000042','SEED-T042',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","dwelling_type":"DETACHED","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":160,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T043: CS-HOM-01 NOT_APPLICABLE (TENANT)
  ('a0000000-0000-0000-0000-000000000043','c0000000-0000-0000-0000-000000000043','SEED-T043',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"TENANT","dwelling_type":"APARTMENT","household_vehicle_count":0,"primary_earner":false,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":80,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T044: CS-HOM-01 DISQ floor=120 < 140
  ('a0000000-0000-0000-0000-000000000044','c0000000-0000-0000-0000-000000000044','SEED-T044',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","dwelling_type":"SEMI_DETACHED","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":120,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T045: CS-HOM-01 ALREADY_COVERED (has_active_home_contents=true)
  ('a0000000-0000-0000-0000-000000000045','c0000000-0000-0000-0000-000000000045','SEED-T045',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","dwelling_type":"DETACHED","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"property":{"zuers_zone":1,"floor_area_sqm":155,"backwater_valve_certified":false,"basement_or_ground_floor_storage":false},"claims":{"at_fault_24mo":0,"at_fault_36mo":0,"minor_36mo":0,"at_fault_12mo":0,"open_litigation_count":0,"claim_free_years_all_policies":5},"riders":{"flood_cover":false},"policies":{"has_active_car":false,"has_active_home_building":true,"has_active_home_contents":true,"has_active_liability":false,"has_active_pet":false,"active_policy_count":2},"cooldown":{"active_products":[]}}'),

  -- T046: CS-PET-01 ELIGIBLE (claim_free_years=4, external=[TPL], no car policy)
  ('a0000000-0000-0000-0000-000000000046','c0000000-0000-0000-0000-000000000046','SEED-T046',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":["TPL"]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2020,"species":"DOG","age_years":6},"claims":{"vet_minor_24mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T047: CS-PET-01 DISQ claim within last 3 years
  ('a0000000-0000-0000-0000-000000000047','c0000000-0000-0000-0000-000000000047','SEED-T047',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":["TPL"]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2020,"species":"DOG","age_years":6},"claims":{"vet_minor_24mo":1,"open_litigation_count":0,"claim_free_years_all_policies":2},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T048: CS-PET-01 NOT_APPLICABLE (no external motor policy)
  ('a0000000-0000-0000-0000-000000000048','c0000000-0000-0000-0000-000000000048','SEED-T048',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2020,"species":"CAT","age_years":6},"claims":{"vet_minor_24mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T049: CS-PET-01 NOT_APPLICABLE (external motor is FULL, already comprehensive)
  ('a0000000-0000-0000-0000-000000000049','c0000000-0000-0000-0000-000000000049','SEED-T049',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":1,"primary_earner":true,"active_external_covers":[],"external_policies_active":["FULL"]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"animal":{"birth_year":2020,"species":"DOG","age_years":6},"claims":{"vet_minor_24mo":0,"open_litigation_count":0,"claim_free_years_all_policies":4},"riders":{"comprehensive_vet":false},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":false,"has_active_pet":true,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T050: CS-LIA-01 ELIGIBLE (LIABILITY, dog_owner=true, no pet policy)
  ('a0000000-0000-0000-0000-000000000050','c0000000-0000-0000-0000-000000000050','SEED-T050',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"declared_facts":{"dog_owner":true,"horse_owner":false},"claims":{"open_litigation_count":0,"claim_free_years_all_policies":5},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":true,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T051: CS-LIA-01 NOT_APPLICABLE (no dog/horse declared)
  ('a0000000-0000-0000-0000-000000000051','c0000000-0000-0000-0000-000000000051','SEED-T051',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"declared_facts":{"dog_owner":false,"horse_owner":false},"claims":{"open_litigation_count":0,"claim_free_years_all_policies":5},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":true,"has_active_pet":false,"active_policy_count":1},"cooldown":{"active_products":[]}}'),

  -- T052: CS-LIA-01 ALREADY_COVERED (has_active_pet=true)
  ('a0000000-0000-0000-0000-000000000052','c0000000-0000-0000-0000-000000000052','SEED-T052',
   '{"src":"SEED"}',
   '{"consent":{"advisory_renewal":"GRANTED"},"customer":{"payment_status":"CURRENT","occupancy":"OWNER_OCCUPIER","household_vehicle_count":0,"primary_earner":true,"active_external_covers":[],"external_policies_active":[]},"compliance":{"open_complaint_count":0,"disputed_claim_count":0},"declared_facts":{"dog_owner":true,"horse_owner":false},"claims":{"open_litigation_count":0,"claim_free_years_all_policies":4},"policies":{"has_active_car":false,"has_active_home_building":false,"has_active_home_contents":false,"has_active_liability":true,"has_active_pet":true,"active_policy_count":2},"cooldown":{"active_products":[]}}')

) AS v(snapshot_id, case_id, source_event_id, raw_payload, dc)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SECTION 12: Recommendation Decline (BR-04 Cooldown)
-- T007: declined CAR_NCD_PROTECTION 30 days ago, cooldown 180 days
-- ============================================================

INSERT INTO sra.recommendation_decline
  (customer_id, product_code, declined_at, source, cooldown_until)
VALUES
  ('CUST-T007','CAR_NCD_PROTECTION',
   CURRENT_DATE - 30,
   'OFFICER_SKIP',
   CURRENT_DATE - 30 + 180)
ON CONFLICT DO NOTHING;

COMMIT;
