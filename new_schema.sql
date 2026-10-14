-- ============================================================================
-- Smart Renewal Advisor — Schema additions to support rule evaluation
-- for Section 3 (Upsell) and Section 4 (Cross-Sell) of
-- "Smart_Renewal_Advisor_Rules 1.docx", plus the Section 2 gatekeeper rules
-- (BR-01..BR-06) those sections depend on.
--
-- Target DB: cross_selldb (Azure Postgres)
-- This script has NOT been run against your database. Review, then apply
-- with psql or your migration tool of choice.
--
-- See RULE_TO_SCHEMA_MAPPING.md for the rule-by-rule justification of every
-- table/column below.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. ALTER existing tables
-- ----------------------------------------------------------------------------

-- policies: normalize coverage tier + numeric vehicle facts + active/lapsed status
ALTER TABLE policies
    ADD COLUMN IF NOT EXISTS coverage_tier text,
    ADD COLUMN IF NOT EXISTS vehicle_market_value_eur numeric,
    ADD COLUMN IF NOT EXISTS vehicle_age_years integer,
    ADD COLUMN IF NOT EXISTS policy_status text DEFAULT 'Active';

ALTER TABLE policies
    ADD CONSTRAINT chk_policies_policy_status
    CHECK (policy_status IN ('Active', 'Lapsed', 'Cancelled', 'Pending Renewal'));

-- coverage_tier allowed values depend on LOB — documented here, not enforced
-- via CHECK because the valid set differs per lob:
--   Motor:              'Third Party Liability', 'Third Party Property Damage',
--                        'Partial Comprehensive', 'Comprehensive Essentials',
--                        'Full Comprehensive'
--   Home Building:      'Core Windstorm/Hail', 'Standard Building'
--   Home Contents:      'Standard Contents'
--   Pet:                'Accidental Surgery Only', 'Comprehensive'
--   Personal Liability: 'Smart', 'Comfort', 'Premium'
-- Also used for the Smart/Comfort/Premium *package* tier referenced by
-- rule_matrix_2's UP-CAR-03 (not the docx UP-CAR-03 — see mapping doc's
-- discrepancy note). If you need both coverage tier AND package tier on the
-- same motor policy at once, use motor_policy_details.package_tier instead
-- and keep policies.coverage_tier for the Third-Party..Comprehensive ladder.

-- Recommended controlled vocabulary for policies.lob (not altering the
-- column type since existing free-text rows must keep working):
--   'Motor', 'Home Building', 'Home Contents', 'Home & Contents', 'Renter',
--   'Landlord', 'Personal Liability', 'Pet', 'Boat / Pleasure Craft',
--   'Caravan & Trailer'

-- claims_history: numeric claim-window counts the rules actually compare
-- with >=, ==, etc. (claims_last_3yrs_count stays as-is; it's free text)
ALTER TABLE claims_history
    ADD COLUMN IF NOT EXISTS at_fault_claims_12mo integer,
    ADD COLUMN IF NOT EXISTS at_fault_claims_24mo integer,
    ADD COLUMN IF NOT EXISTS at_fault_claims_36mo integer,
    ADD COLUMN IF NOT EXISTS minor_claims_36mo integer;

-- Note: claims_history.demerit_points (already exists) is reused as the
-- rules' "Penalty_Points" — do not add a duplicate column.


-- ----------------------------------------------------------------------------
-- 2. New table: customer_compliance_flags (Section 2, BR-01..BR-03, BR-05 consent/payment side)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS customer_compliance_flags (
    customer_id              text PRIMARY KEY REFERENCES customers(customer_id),
    advisory_marketing_consent text NOT NULL DEFAULT 'GRANTED'
        CHECK (advisory_marketing_consent IN ('GRANTED', 'REVOKED', 'UNSPECIFIED')),
    policy_payment_status     text NOT NULL DEFAULT 'CURRENT'
        CHECK (policy_payment_status IN ('CURRENT', 'ARREARS', 'DEBT_RECOVERY', 'DISHONORED_DD')),
    open_complaint_flag       boolean NOT NULL DEFAULT false,
    disputed_claim_flag       boolean NOT NULL DEFAULT false,
    complaint_or_dispute_date date,
    created_at                timestamp with time zone DEFAULT now(),
    updated_at                timestamp with time zone DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- 3. New table: customer_profile_facts (cross-sell/upsell targeting facts
--    that live at the customer level, not tied to one policy)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS customer_profile_facts (
    customer_id                   text PRIMARY KEY REFERENCES customers(customer_id),
    occupancy_status              text
        CHECK (occupancy_status IN ('Owner-Occupier', 'Tenant', 'Landlord', 'Investor', 'Other')),
    household_vehicle_count       integer,
    is_primary_wage_earner        boolean,
    has_personal_disability_cover boolean,
    dog_or_horse_ownership        boolean DEFAULT false,
    pet_type_owned                text
        CHECK (pet_type_owned IN ('Dog', 'Horse', 'Dog & Horse', 'Other', 'None') OR pet_type_owned IS NULL),
    external_motor_policy_held    boolean DEFAULT false,
    external_motor_policy_tier    text
        CHECK (external_motor_policy_tier IN ('Basic', 'Comprehensive') OR external_motor_policy_tier IS NULL),
    created_at                    timestamp with time zone DEFAULT now(),
    updated_at                    timestamp with time zone DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- 4. New table: motor_policy_details (1:1 with policies where lob='Motor')
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS motor_policy_details (
    policy_id                 integer PRIMARY KEY REFERENCES policies(policy_id),
    annual_mileage_km         integer,
    bonus_tier                integer CHECK (bonus_tier BETWEEN 0 AND 20),
    ncd_protection_attached   boolean DEFAULT false,
    roadside_assistance_attached boolean DEFAULT false,
    package_tier              text CHECK (package_tier IN ('Smart', 'Comfort', 'Premium') OR package_tier IS NULL),
    created_at                timestamp with time zone DEFAULT now(),
    updated_at                timestamp with time zone DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- 5. New table: home_policy_details (1:1 with policies where lob is a Home variant)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS home_policy_details (
    policy_id                     integer PRIMARY KEY REFERENCES policies(policy_id),
    dwelling_type                 text
        CHECK (dwelling_type IN ('Detached House', 'Apartment', 'Townhouse', 'Duplex', 'Other')),
    floor_area_sqm                numeric,
    environmental_zone            text
        CHECK (environmental_zone IN ('Zone 1', 'Zone 2', 'Zone 3', 'Zone 4')),
    backwater_valve_certified     boolean DEFAULT false,
    ground_level_ingress_protection boolean DEFAULT false,
    flood_cover_attached          boolean DEFAULT false,
    open_water_damage_claim_24mo  boolean DEFAULT false,
    open_litigation_claims        integer DEFAULT 0,
    created_at                    timestamp with time zone DEFAULT now(),
    updated_at                    timestamp with time zone DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- 6. New table: pet_policy_details (1:1 with policies where lob='Pet')
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS pet_policy_details (
    policy_id                     integer PRIMARY KEY REFERENCES policies(policy_id),
    pet_age_years                 integer,
    cover_tier                    text
        CHECK (cover_tier IN ('Accidental Surgery Only', 'Comprehensive')),
    claim_free_years              integer DEFAULT 0,
    minor_outpatient_claims_24mo  integer DEFAULT 0,
    created_at                    timestamp with time zone DEFAULT now(),
    updated_at                    timestamp with time zone DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- 7. New table: rule_evaluation_log (audit trail — Section 1.1 regulatory
--    requirement: "exact audit trail of every rule evaluated")
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS rule_evaluation_log (
    log_id              serial PRIMARY KEY,
    customer_id         text REFERENCES customers(customer_id),
    call_id             text REFERENCES calls(call_id),
    rule_id             text NOT NULL,           -- e.g. 'UP-CAR-01', 'BR-05'
    rule_source         text NOT NULL
        CHECK (rule_source IN ('gatekeeper', 'upsell', 'cross-sell')),
    evaluation_result   text NOT NULL
        CHECK (evaluation_result IN ('FIRED_ELIGIBLE', 'DISQUALIFIED_CRITERIA',
                                      'DISQUALIFIED_COOLDOWN', 'SUPPRESSED')),
    suppression_reason  text,                    -- e.g. 'GRIEVANCE_ACTIVE', 'CONDUCT_HOLD'
    evaluated_at        timestamp with time zone DEFAULT now()
);


-- ============================================================================
-- SAMPLE DATA
-- Backfills the two existing customers, then adds five synthetic customers so
-- every rule in Sections 2-4 has at least one row that qualifies and (where
-- the doc defines a disqualifier) one row that's disqualified.
-- ============================================================================

-- --- Backfill existing customers' compliance/profile rows ------------------

INSERT INTO customer_compliance_flags (customer_id, advisory_marketing_consent, policy_payment_status, open_complaint_flag, disputed_claim_flag)
VALUES
    ('CUS-10842', 'GRANTED', 'CURRENT', false, false),
    ('CUS-10925', 'GRANTED', 'CURRENT', false, false)
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES
    ('CUS-10842', 'Owner-Occupier', 1, true, false),
    ('CUS-10925', 'Owner-Occupier', 1, true, false)
ON CONFLICT (customer_id) DO NOTHING;

-- Backfill existing motor policies with detail rows
-- policy_id 1 = Sarah Williams, Comprehensive Essentials, 2024 RAV4
INSERT INTO motor_policy_details (policy_id, annual_mileage_km, bonus_tier, ncd_protection_attached, roadside_assistance_attached, package_tier)
VALUES (1, 11000, 9, false, false, 'Comfort')
ON CONFLICT (policy_id) DO NOTHING;

-- policy_id 2 = Michael Brown, Third Party Property Damage, 2023 RAV4
INSERT INTO motor_policy_details (policy_id, annual_mileage_km, bonus_tier, ncd_protection_attached, roadside_assistance_attached, package_tier)
VALUES (2, 9500, 6, false, false, 'Smart')
ON CONFLICT (policy_id) DO NOTHING;

UPDATE policies SET coverage_tier = 'Comprehensive Essentials', vehicle_market_value_eur = 29500, vehicle_age_years = 2, policy_status = 'Active' WHERE policy_id = 1;
UPDATE policies SET coverage_tier = 'Third Party Property Damage', vehicle_market_value_eur = 27600, vehicle_age_years = 3, policy_status = 'Active' WHERE policy_id = 2;

INSERT INTO claims_history (claim_id, customer_id, claims_last_3yrs_count, last_claim_coverage_type, driver_history_summary, demerit_points, licence_tenure_years, at_fault_claims_12mo, at_fault_claims_24mo, at_fault_claims_36mo, minor_claims_36mo)
SELECT claim_id, customer_id, claims_last_3yrs_count, last_claim_coverage_type, driver_history_summary, demerit_points, licence_tenure_years, 0, 0, 0, 0
FROM claims_history WHERE customer_id = 'CUS-10842' AND at_fault_claims_36mo IS NULL
ON CONFLICT DO NOTHING;
-- (direct UPDATE is simpler than the INSERT-select above for existing rows)
UPDATE claims_history SET at_fault_claims_12mo = 0, at_fault_claims_24mo = 0, at_fault_claims_36mo = 0, minor_claims_36mo = 0 WHERE customer_id = 'CUS-10842';
UPDATE claims_history SET at_fault_claims_12mo = 0, at_fault_claims_24mo = 0, at_fault_claims_36mo = 0, minor_claims_36mo = 1 WHERE customer_id = 'CUS-10925';


-- --- New synthetic customers, one per rule family --------------------------

-- CUS-10940: Emma Chen — tests UP-CAR-01 (qualifies) and CS-CAR-01 (qualifies)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10940', 'Emma Chen', '05/06/1995', '05 June 1995', 31, '2021', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id, advisory_marketing_consent, policy_payment_status, open_complaint_flag, disputed_claim_flag)
VALUES ('CUS-10940', 'GRANTED', 'CURRENT', false, false);

INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES ('CUS-10940', 'Tenant', 1, false, false);

INSERT INTO policies (customer_id, lob, current_product, vehicle_desc, vehicle_value_aud, vehicle_usage, renewal_days, coverage_tier, vehicle_market_value_eur, vehicle_age_years, policy_status)
VALUES ('CUS-10940', 'Motor', 'Full Comprehensive', '2022 Mazda 3', 'AUD 26,000', 'Personal', '50 days', 'Full Comprehensive', 16000, 4, 'Active')
RETURNING policy_id;
-- (capture the returned policy_id manually if running statement-by-statement;
--  when running the whole file, use the subquery form below instead)

INSERT INTO motor_policy_details (policy_id, annual_mileage_km, bonus_tier, ncd_protection_attached, roadside_assistance_attached, package_tier)
SELECT policy_id, 10000, 10, false, false, 'Comfort'
FROM policies WHERE customer_id = 'CUS-10940' AND lob = 'Motor';

INSERT INTO claims_history (customer_id, claims_last_3yrs_count, last_claim_coverage_type, driver_history_summary, demerit_points, licence_tenure_years, at_fault_claims_12mo, at_fault_claims_24mo, at_fault_claims_36mo, minor_claims_36mo)
VALUES ('CUS-10940', '0 claims', 'N/A', 'Clean record, 10 yrs licenced', 0, 10, 0, 0, 0, 0);
-- Emma: single active policy, Tenant, no liability policy on record -> CS-CAR-01 qualifies
-- Emma: Full Comprehensive, bonus_tier 10 (>=8), 0 at-fault claims in 36mo, no NCD rider -> UP-CAR-01 qualifies


-- CUS-10941: David Novak — tests UP-CAR-01 DISQUALIFIED (recent at-fault claim)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10941', 'David Novak', '12/11/1979', '12 November 1979', 46, '2015', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10941');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES ('CUS-10941', 'Owner-Occupier', 2, true, true);

INSERT INTO policies (customer_id, lob, current_product, vehicle_desc, vehicle_value_aud, vehicle_usage, renewal_days, coverage_tier, vehicle_market_value_eur, vehicle_age_years, policy_status)
VALUES ('CUS-10941', 'Motor', 'Full Comprehensive', '2020 Subaru Outback', 'AUD 32,000', 'Personal', '40 days', 'Full Comprehensive', 19500, 6, 'Active');

INSERT INTO motor_policy_details (policy_id, annual_mileage_km, bonus_tier, ncd_protection_attached, roadside_assistance_attached, package_tier)
SELECT policy_id, 14000, 9, false, true, 'Comfort' FROM policies WHERE customer_id = 'CUS-10941' AND lob = 'Motor';

INSERT INTO claims_history (customer_id, claims_last_3yrs_count, last_claim_coverage_type, driver_history_summary, demerit_points, licence_tenure_years, at_fault_claims_12mo, at_fault_claims_24mo, at_fault_claims_36mo, minor_claims_36mo)
VALUES ('CUS-10941', '1 at-fault claim', 'Comprehensive', 'One at-fault claim 14 months ago', 2, 24, 0, 1, 1, 1);
-- David: 1 at-fault claim within 36mo -> UP-CAR-01 DISQUALIFIED (needs exactly 0)
-- David: already has roadside rider -> UP-CAR-03 DISQUALIFIED (rider already attached)


-- CUS-10942: James Carter — tests UP-HOM-01 (qualifies) and CS-HOM-01 (qualifies)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10942', 'James Carter', '20/02/1985', '20 February 1985', 41, '2017', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10942');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES ('CUS-10942', 'Owner-Occupier', 1, true, false);

INSERT INTO policies (customer_id, lob, current_product, policy_status)
VALUES ('CUS-10942', 'Home Building', 'Standard Building', 'Active');

INSERT INTO home_policy_details (policy_id, dwelling_type, floor_area_sqm, environmental_zone, backwater_valve_certified, ground_level_ingress_protection, flood_cover_attached, open_water_damage_claim_24mo, open_litigation_claims)
SELECT policy_id, 'Detached House', 165, 'Zone 2', true, true, false, false, 0
FROM policies WHERE customer_id = 'CUS-10942' AND lob = 'Home Building';
-- James: Zone 2, backwater valve certified, no flood cover yet -> UP-HOM-01 qualifies
-- James: Owner-Occupier, detached house 165sqm (>=140), zero contents insurance -> CS-HOM-01 qualifies


-- CUS-10943: Priya Nair — tests UP-HOM-01 DISQUALIFIED (Zone 4)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10943', 'Priya Nair', '03/09/1990', '03 September 1990', 36, '2020', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10943');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES ('CUS-10943', 'Owner-Occupier', 1, false, false);

INSERT INTO policies (customer_id, lob, current_product, policy_status)
VALUES ('CUS-10943', 'Home Building', 'Standard Building', 'Active');

INSERT INTO home_policy_details (policy_id, dwelling_type, floor_area_sqm, environmental_zone, backwater_valve_certified, ground_level_ingress_protection, flood_cover_attached, open_water_damage_claim_24mo, open_litigation_claims)
SELECT policy_id, 'Detached House', 130, 'Zone 4', false, false, false, false, 0
FROM policies WHERE customer_id = 'CUS-10943' AND lob = 'Home Building';
-- Priya: Zone 4 -> UP-HOM-01 DISQUALIFIED (requires manual engineering survey per doc)


-- CUS-10944: Olivia Martinez — tests UP-PET-01 and CS-PET-01 (both qualify)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10944', 'Olivia Martinez', '17/04/1992', '17 April 1992', 34, '2019', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10944');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover, external_motor_policy_held, external_motor_policy_tier)
VALUES ('CUS-10944', 'Tenant', 1, false, false, true, 'Basic');

INSERT INTO policies (customer_id, lob, current_product, policy_status)
VALUES ('CUS-10944', 'Pet', 'Accidental Surgery Only', 'Active');

INSERT INTO pet_policy_details (policy_id, pet_age_years, cover_tier, claim_free_years, minor_outpatient_claims_24mo)
SELECT policy_id, 4, 'Accidental Surgery Only', 4, 0
FROM policies WHERE customer_id = 'CUS-10944' AND lob = 'Pet';
-- Olivia: pet age 4 (<=7), 0 outpatient claims in 24mo -> UP-PET-01 qualifies
-- Olivia: 4 claim-free years (>=3), external basic motor cover -> CS-PET-01 qualifies


-- CUS-10945: Liam Walsh — tests CS-LIA-01 (qualifies)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10945', 'Liam Walsh', '09/01/1988', '09 January 1988', 38, '2016', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10945');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover, dog_or_horse_ownership, pet_type_owned)
VALUES ('CUS-10945', 'Tenant', 0, false, false, true, 'Dog');

INSERT INTO policies (customer_id, lob, current_product, coverage_tier, policy_status)
VALUES ('CUS-10945', 'Personal Liability', 'Comfort Tier', 'Comfort', 'Active');
-- Liam: dog ownership = true, zero Pet policy on record -> CS-LIA-01 qualifies


-- CUS-10946: Noah Thompson — tests CS-CAR-02 (qualifies) and UP-CAR-03 (qualifies)
INSERT INTO customers (customer_id, full_name, dob, dob_display, age, customer_since, location)
VALUES ('CUS-10946', 'Noah Thompson', '25/07/1983', '25 July 1983', 43, '2014', 'Queensland');

INSERT INTO customer_compliance_flags (customer_id) VALUES ('CUS-10946');
INSERT INTO customer_profile_facts (customer_id, occupancy_status, household_vehicle_count, is_primary_wage_earner, has_personal_disability_cover)
VALUES ('CUS-10946', 'Owner-Occupier', 1, true, false);

INSERT INTO policies (customer_id, lob, current_product, vehicle_desc, coverage_tier, vehicle_market_value_eur, vehicle_age_years, policy_status)
VALUES ('CUS-10946', 'Motor', 'Comprehensive Essentials', '2021 Hyundai Tucson', 'Comprehensive Essentials', 21000, 5, 'Active');

INSERT INTO motor_policy_details (policy_id, annual_mileage_km, bonus_tier, ncd_protection_attached, roadside_assistance_attached, package_tier)
SELECT policy_id, 18000, 7, false, false, 'Smart' FROM policies WHERE customer_id = 'CUS-10946' AND lob = 'Motor';
-- Noah: 18,000 km/yr (>=15,000), primary wage earner, no disability cover -> CS-CAR-02 qualifies
-- Noah: 18,000 km/yr (>=12,000), 1 household vehicle, no roadside rider -> UP-CAR-03 qualifies


-- ============================================================================
-- Quick sanity-check queries (run after loading the data above)
-- ============================================================================

-- UP-CAR-01 candidates (NCD Protection Rider)
-- SELECT p.customer_id, p.policy_id FROM policies p
-- JOIN motor_policy_details m ON m.policy_id = p.policy_id
-- JOIN claims_history c ON c.customer_id = p.customer_id
-- WHERE p.lob = 'Motor' AND p.coverage_tier = 'Full Comprehensive'
--   AND m.bonus_tier >= 8 AND m.ncd_protection_attached = false
--   AND c.at_fault_claims_36mo = 0;

-- CS-CAR-01 candidates (Car -> Personal Liability)
-- SELECT cp.customer_id FROM customer_profile_facts cp
-- WHERE cp.occupancy_status = 'Tenant'
--   AND (SELECT COUNT(*) FROM policies WHERE customer_id = cp.customer_id AND policy_status='Active') = 1
--   AND NOT EXISTS (SELECT 1 FROM policies WHERE customer_id = cp.customer_id AND lob = 'Personal Liability' AND policy_status = 'Active');
