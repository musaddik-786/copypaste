-- ============================================================
-- MOTOR LOB COVERAGE VERIFICATION ENHANCEMENTS
-- Run on Azure PostgreSQL before testing enhanced Motor LOB
-- ============================================================

-- ── 1. Add Motor-specific columns to motor_policy_details ──────────────────
ALTER TABLE motor_policy_details
    ADD COLUMN IF NOT EXISTS od_coverage_limit        NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS tp_coverage_limit        NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS zero_dep_enabled         INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS engine_protection_enabled INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS addons                   TEXT;

-- ── 2. Add driver license expiry to motor_vehicle_details ─────────────────
ALTER TABLE motor_vehicle_details
    ADD COLUMN IF NOT EXISTS driver_license_expiry DATE;

-- ── 3. Add Motor-specific result columns to motor_coverage_verification_results
ALTER TABLE motor_coverage_verification_results
    ADD COLUMN IF NOT EXISTS claim_type              TEXT,
    ADD COLUMN IF NOT EXISTS license_valid           INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS license_expiry_note     TEXT,
    ADD COLUMN IF NOT EXISTS zero_dep_applied        INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS engine_protection_note  TEXT;

-- ── 4. Populate od/tp limits, zero dep, engine protection for POL-1001 to POL-1020
UPDATE motor_policy_details SET
    od_coverage_limit         = 135000.00,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 1,
    engine_protection_enabled = 1,
    addons                    = 'Zero Depreciation, Engine Protection'
WHERE policy_number = 'POL-1001';

UPDATE motor_policy_details SET
    od_coverage_limit         = 100000.00,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 0,
    engine_protection_enabled = 0,
    addons                    = 'None'
WHERE policy_number = 'POL-1002';

UPDATE motor_policy_details SET
    od_coverage_limit         = 180000.00,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 1,
    engine_protection_enabled = 0,
    addons                    = 'Zero Depreciation'
WHERE policy_number = 'POL-1003';

UPDATE motor_policy_details SET
    od_coverage_limit         = 90000.00,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 0,
    engine_protection_enabled = 1,
    addons                    = 'Engine Protection'
WHERE policy_number = 'POL-1004';

UPDATE motor_policy_details SET
    od_coverage_limit         = 85000.00,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 0,
    engine_protection_enabled = 0,
    addons                    = 'None'
WHERE policy_number = 'POL-1005';

UPDATE motor_policy_details SET
    od_coverage_limit         = coverage_limit * 0.85,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 0,
    engine_protection_enabled = 0,
    addons                    = 'None'
WHERE policy_number IN ('POL-1006','POL-1007','POL-1008','POL-1009','POL-1010');

UPDATE motor_policy_details SET
    od_coverage_limit         = coverage_limit * 0.85,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 1,
    engine_protection_enabled = 1,
    addons                    = 'Zero Depreciation, Engine Protection'
WHERE policy_number IN ('POL-1011','POL-1012','POL-1013','POL-1014','POL-1015');

UPDATE motor_policy_details SET
    od_coverage_limit         = coverage_limit * 0.85,
    tp_coverage_limit         = 100000.00,
    zero_dep_enabled          = 1,
    engine_protection_enabled = 0,
    addons                    = 'Zero Depreciation'
WHERE policy_number IN ('POL-1016','POL-1017','POL-1018','POL-1019','POL-1020');

-- ── 5. Set driver license expiry for existing vehicle records ─────────────
-- POL-1001: valid license (future)
UPDATE motor_vehicle_details SET driver_license_expiry = '2028-06-30' WHERE policy_number = 'POL-1001';
-- POL-1002: EXPIRED license (before 2026-09-17 test date) — triggers rejection
UPDATE motor_vehicle_details SET driver_license_expiry = '2025-12-31' WHERE policy_number = 'POL-1002';
-- POL-1003: valid license (future)
UPDATE motor_vehicle_details SET driver_license_expiry = '2027-09-15' WHERE policy_number = 'POL-1003';

-- ── 6. Verify ──────────────────────────────────────────────────────────────
SELECT policy_number, od_coverage_limit, tp_coverage_limit,
       zero_dep_enabled, engine_protection_enabled, addons
FROM motor_policy_details
WHERE policy_number IN ('POL-1001','POL-1002','POL-1003','POL-1004','POL-1005')
ORDER BY policy_number;

SELECT policy_number, driver_license, driver_license_expiry
FROM motor_vehicle_details
ORDER BY policy_number;
