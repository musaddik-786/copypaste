-- =============================================================================
-- Smart Renewal Advisor (SRA) — Gap Fixes
-- Applied on top of: 001_sra_schema.sql (Version 1.0 POC baseline)
-- Fixes: Gap 1, 2, 3, 4 (documentation), 5
-- Gap 6 skipped — zuers_zone integer storage is correct; Zone string handled in application layer.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- GAP 1 — BR-05: Missing demerit / penalty points column
--
-- BR-05 condition: At_Fault_Claims_24Mo >= 2  OR  Penalty_Points >= 4
-- Without this column, BR-05 can only evaluate the at-fault claims half.
-- A driver with 0 at-fault claims but 5 demerit points would pass the gatekeeper
-- and receive a recommendation they should be blocked from (underwriting risk).
--
-- Column goes on src.insured_vehicle because demerit points are per vehicle / driver,
-- not per customer (a household can have multiple drivers with different point counts).
-- DEFAULT 0 = no known points; Fact Builder must populate from DVLA / KBA feed.
-- -----------------------------------------------------------------------------
ALTER TABLE src.insured_vehicle
    ADD COLUMN demerit_points integer NOT NULL DEFAULT 0;

-- Optional: add a comment so the Fact Builder team knows the expected source
COMMENT ON COLUMN src.insured_vehicle.demerit_points IS
    'Traffic authority demerit / penalty points for this vehicle''s primary driver. '
    'Source: KBA (Kraftfahrt-Bundesamt) or DVLA feed. NOT the same as bonus_tier (SF-Klasse). '
    'BR-05 gates on demerit_points >= 4.';

-- -----------------------------------------------------------------------------
-- GAP 2 — CS-CAR-02: Missing external cover types flag
--
-- CS-CAR-02 condition: Commuter >= 15,000 km/year  AND  primary_earner = true
--                      AND  no personal disability / accident cover held externally.
--
-- Manager's approach: array column so we store ALL cover types the customer
-- holds externally (not just a single boolean). This way the rule engine can
-- check any individual cover type without needing separate boolean columns per
-- cover type.
--
-- Allowed values in the array:
--   PERSONAL_DISABILITY   — disability income / Berufsunfähigkeitsversicherung (BU)
--   PERSONAL_ACCIDENT     — personal accident / Unfallversicherung
--   INCOME_PROTECTION     — income protection / Erwerbsminderungsabsicherung
--   LIFE                  — life / Risikolebensversicherung
--   CRITICAL_ILLNESS      — critical illness / Dread-Disease
--
-- CS-CAR-02 rule check:
--   NOT (  'PERSONAL_DISABILITY' = ANY(active_external_covers)
--       OR 'PERSONAL_ACCIDENT'   = ANY(active_external_covers) )
--   → if neither is present, the customer has a gap → recommend Personal Accident Insurance
--
-- CHECK constraint ensures only known values are stored (prevents free-text drift).
-- DEFAULT '{}' = no external covers declared (Fact Builder must populate from declared facts / CSR call).
-- -----------------------------------------------------------------------------
ALTER TABLE src.customer
    ADD COLUMN active_external_covers text[] NOT NULL DEFAULT '{}',
    ADD CONSTRAINT active_external_covers_valid_values CHECK (
        active_external_covers <@ ARRAY[
            'PERSONAL_DISABILITY',
            'PERSONAL_ACCIDENT',
            'INCOME_PROTECTION',
            'LIFE',
            'CRITICAL_ILLNESS'
        ]::text[]
    );

COMMENT ON COLUMN src.customer.active_external_covers IS
    'Array of external / competitor cover types declared by the customer or verified via CSR call. '
    'Allowed: PERSONAL_DISABILITY, PERSONAL_ACCIDENT, INCOME_PROTECTION, LIFE, CRITICAL_ILLNESS. '
    'CS-CAR-02 checks: neither PERSONAL_DISABILITY nor PERSONAL_ACCIDENT is present → recommend PA Insurance. '
    'Empty array = no external covers declared (treat as gap). Source: customer_declared_fact or CSR_CALL.';

-- -----------------------------------------------------------------------------
-- GAP 3 — CS-PET-01: External motor policy tier untyped JSONB
--
-- CS-PET-01 condition: Operates a family car insured externally under basic cover.
-- Old approach: customer_declared_fact with fact_key = 'external_vehicle' and a
-- free-form JSONB value — CSRs entered {"tier":"basic"}, {"tier":"Basic"}, {"coverage":"TPL"}
-- etc., making the rule unreliable.
--
-- Manager's approach (consistent with Gap 2): typed array column on src.customer.
-- Allowed values match the motor coverage_level CHECK already on src.policy:
--   TPL     — Third-Party Liability only (basic cover — this is what CS-PET-01 targets)
--   PARTIAL — Partial Comprehensive / Teilkasko
--   FULL    — Full Comprehensive / Vollkasko
--
-- CS-PET-01 rule check:
--   'TPL' = ANY(external_policies_active)
--   → customer has a basic external motor policy → recommend our Full Comprehensive
--
-- Empty array = no external motor policy declared.
-- NOT NULL DEFAULT '{}' — same pattern as active_external_covers above.
-- -----------------------------------------------------------------------------
ALTER TABLE src.customer
    ADD COLUMN external_policies_active text[] NOT NULL DEFAULT '{}',
    ADD CONSTRAINT external_policies_active_valid_values CHECK (
        external_policies_active <@ ARRAY['TPL', 'PARTIAL', 'FULL']::text[]
    );

COMMENT ON COLUMN src.customer.external_policies_active IS
    'Array of external motor policy coverage tiers held by this customer with another insurer. '
    'Allowed: TPL (Third-Party Liability / basic), PARTIAL (Teilkasko), FULL (Vollkasko). '
    'CS-PET-01 checks: TPL = ANY(external_policies_active) → customer has basic external motor → recommend Full Comprehensive. '
    'Replaces the untyped customer_declared_fact fact_key=external_vehicle approach. Source: CSR_CALL or PORTAL.';

-- -----------------------------------------------------------------------------
-- GAP 4 — CS-PET-01: Claim-free years — interpretation documented
--
-- Rule says: "Loyal policyholder — 3 or more claim-free years."
-- Confirmed interpretation: 3 calendar years with ZERO claims on ANY active policy
--                           held by this customer (not just the pet policy).
--
-- No schema change needed. The Fact Builder derives this at runtime:
--
--   SELECT CASE
--     WHEN COUNT(*) = 0 THEN EXTRACT(YEAR FROM AGE(now(), MIN(p.inception_date)))::int
--     ELSE EXTRACT(YEAR FROM AGE(now(), MAX(c.reported_date)))::int
--   END AS claim_free_years_all_policies
--   FROM src.policy p
--   LEFT JOIN src.claim c
--       ON c.customer_id = p.customer_id
--      AND c.reported_date >= CURRENT_DATE - INTERVAL '3 years'
--   WHERE p.customer_id = <customer_id>
--     AND p.status = 'ACTIVE'
--
-- The rules.rule.required_facts for CS-PET-01 must include:
--   'customer.claim_free_years_all_policies'
--
-- reported_date (not loss_date) is used because the insurer knows about the claim
-- from reported_date — using loss_date could miss a claim that occurred long ago
-- but was only just reported. The comparison window is now() vs reported_date.
-- -----------------------------------------------------------------------------

-- No DDL required. Reminder comment for the Fact Builder developer:
COMMENT ON TABLE src.claim IS
    'Motor, home and pet claims. '
    'reported_date is the authoritative date for CS-PET-01 claim-free years calculation '
    '(use reported_date >= CURRENT_DATE - INTERVAL ''3 years'' scoped to all customer policies). '
    'loss_date is used for time-window rules like UP-CAR-02 (claims in last 36 months).';

-- -----------------------------------------------------------------------------
-- GAP 5 — BR-05 (property): Open litigation count not in Fact Builder spec
--
-- BR-05 condition (property side): Open_Litigation_Claims > 0 → Underwriting disqualification.
-- src.claim.status can be 'LITIGATION' — the data exists. However, the join path is:
--   src.claim → src.policy → src.customer (no direct claim.customer_id → customer link for property)
--
-- Fix: Add a helper function the Fact Builder calls to derive open_litigation_claims_count
-- into decision_context. The rules.rule.required_facts for BR-05 must include this fact key.
--
-- The function is STABLE (same inputs → same output within a transaction), never VOLATILE,
-- so the query planner can inline it safely inside the Fact Builder's snapshot build query.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION src.fn_open_litigation_claims_count(p_customer_id text)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::integer
    FROM src.claim c
    JOIN src.policy p ON p.policy_id = c.policy_id
    WHERE p.customer_id = p_customer_id
      AND c.status = 'LITIGATION';
$$;

COMMENT ON FUNCTION src.fn_open_litigation_claims_count(text) IS
    'Returns the count of claims in LITIGATION status across all policies held by the given customer. '
    'Used by the Fact Builder to populate decision_context key: claims.open_litigation_count. '
    'BR-05 (property side) gates on this value > 0. '
    'The Fact Builder must register this fact in rules.rule.required_facts for BR-05.';
