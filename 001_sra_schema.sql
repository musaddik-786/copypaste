-- =============================================================================
-- Smart Renewal Advisor (SRA) - PostgreSQL 16 schema  (Azure Database for PostgreSQL Flexible Server)
-- Version 1.0 (POC baseline)                                   Region: Germany West Central
--
-- Schemas
--   ref    reference & product catalogue (owned by Product Mgmt / POG)
--   src    MOCK systems of record for the POC (PAS / CRM / Claims). In production this
--          schema is REPLACED by integration adapters; nothing in sra/rules reads src directly
--          except the Fact Builder.
--   rules  rule registry, parameters, maker-checker, golden tests
--   sra    advisor-owned operational data: cases, immutable snapshots, decisions,
--          recommendations, pricing, narratives, officer actions, letters, copilot
--   audit  append-only, hash-chained audit ledger
--
-- Conventions
--   * uuid PKs (gen_random_uuid), business keys as unique text (e.g. 'REC-2026-0041').
--   * Money: numeric(12,2), always EUR, gross incl. Versicherungsteuer unless column says *_net.
--   * Enumerations as text + CHECK (easier to evolve than PG enums under migrations).
--   * Immutable tables (snapshot, decision_run, rule_evaluation, audit_event) are INSERT-only;
--     enforced by trigger sra.forbid_mutation().
--   * Personal data columns are tagged in comments with [PII] / [PII-SENSITIVE] for Purview.
--   * retention_class drives the purge job (values agreed with the client DPO, see architecture doc §3.7).
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS src;
CREATE SCHEMA IF NOT EXISTS rules;
CREATE SCHEMA IF NOT EXISTS sra;
CREATE SCHEMA IF NOT EXISTS audit;

-- -----------------------------------------------------------------------------
-- Shared: immutability guard
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sra.forbid_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Table %.% is append-only (% not allowed)', TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP;
END $$;

-- =============================================================================
-- REF : reference data & product catalogue
-- =============================================================================
CREATE TABLE ref.line_of_business (
  lob_code        text PRIMARY KEY,                 -- CAR, HOME_BUILDING, HOME_CONTENTS, LIABILITY, PET_LIAB, PET_HEALTH, ACCIDENT
  name_en         text NOT NULL,
  name_de         text NOT NULL,
  in_brd_scope    boolean NOT NULL DEFAULT true
);

CREATE TABLE ref.product (
  product_code    text PRIMARY KEY,                 -- e.g. CAR_NCD_PROTECTION
  lob_code        text NOT NULL REFERENCES ref.line_of_business,
  product_kind    text NOT NULL CHECK (product_kind IN ('BASE','COVERAGE','TIER','RIDER')),
  name_en         text NOT NULL,
  name_de         text NOT NULL,
  cooldown_class  text NOT NULL CHECK (cooldown_class IN ('RIDER','COMPANION')),
  target_market   jsonb,                            -- JsonLogic expression (IDD POG target market)
  target_market_note text,
  scope_flag      text,                             -- e.g. EXTENSION_PRODUCT_NOT_IN_BRD_SCOPE
  ipid_document_id uuid,                            -- -> ref.product_document (IDD Art. 20(5) IPID)
  avb_document_id  uuid,                            -- -> ref.product_document (policy wording / AVB)
  status          text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DRAFT','RETIRED')),
  effective_from  date NOT NULL,
  effective_to    date
);

-- Coverage embedding: e.g. CAR_COV_FULL embeds CAR_COV_PARTIAL; HOME_CONTENTS PREMIUM tier embeds HOME_CNT_BICYCLE
CREATE TABLE ref.product_embedding (
  parent_product_code   text NOT NULL REFERENCES ref.product,
  parent_tier           text,                       -- NULL = any tier
  embedded_product_code text NOT NULL REFERENCES ref.product,
  PRIMARY KEY (parent_product_code, embedded_product_code)
);

CREATE TABLE ref.product_document (
  document_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_code    text NOT NULL REFERENCES ref.product,
  doc_type        text NOT NULL CHECK (doc_type IN ('IPID','AVB','PRODUCT_SHEET')),
  language        text NOT NULL CHECK (language IN ('de','en')),
  version         text NOT NULL,
  blob_uri        text NOT NULL,
  search_index_id text,                             -- AI Search document key (copilot RAG)
  valid_from      date NOT NULL,
  valid_to        date,
  UNIQUE (product_code, doc_type, language, version)
);

-- Compliance-approved benefit statements. The LLM may ONLY assert benefits that appear here.
CREATE TABLE ref.product_benefit_statement (
  statement_id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_code    text NOT NULL REFERENCES ref.product,
  language        text NOT NULL CHECK (language IN ('de','en')),
  statement_key   text NOT NULL,                    -- e.g. 'NCD.TIER_PROTECTED_ONE_CLAIM'
  statement_text  text NOT NULL,
  contains_limit  boolean NOT NULL DEFAULT false,   -- true => numeric limit must match product data
  approved_by     text NOT NULL,
  approved_at     timestamptz NOT NULL,
  version         int NOT NULL DEFAULT 1,
  status          text NOT NULL DEFAULT 'APPROVED' CHECK (status IN ('DRAFT','APPROVED','RETIRED')),
  UNIQUE (product_code, language, statement_key, version)
);

CREATE TABLE ref.bundle_discount_rule (
  bundle_rule_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  companion_product_code text NOT NULL REFERENCES ref.product,
  min_distinct_lobs     int  NOT NULL DEFAULT 2,
  discount_pct          numeric(5,2) NOT NULL CHECK (discount_pct >= 0 AND discount_pct <= 50),
  basis                 text NOT NULL DEFAULT 'RENEWAL_PLUS_COMPANION'
                         CHECK (basis IN ('RENEWAL_PLUS_COMPANION','COMPANION_ONLY','WHOLE_PORTFOLIO')),
  effective_from        date NOT NULL,
  effective_to          date
);

CREATE TABLE ref.skip_reason (
  reason_code       text PRIMARY KEY,               -- CUSTOMER_BUDGET, COVERED_EXTERNALLY, ...
  label_en          text NOT NULL,
  label_de          text NOT NULL,
  creates_cooldown  boolean NOT NULL,               -- true => counts as a customer decline (EL-03)
  requires_comment  boolean NOT NULL DEFAULT false,
  triggers_data_fix boolean NOT NULL DEFAULT false, -- e.g. UNRECORDED_RISK_CHANGE -> data-quality task
  active            boolean NOT NULL DEFAULT true
);

CREATE TABLE ref.defer_reason (
  reason_code  text PRIMARY KEY,                    -- CUSTOMER_CONTACT_PENDING, DATA_VERIFICATION
  label_en     text NOT NULL,
  label_de     text NOT NULL,
  max_defer_days int NOT NULL DEFAULT 7
);

CREATE TABLE ref.regulatory_reference (
  reg_code     text PRIMARY KEY,                    -- IDD-ART-20, GDPR-ART-21, VVG-6, UWG-7, AIACT-ART-50 ...
  title        text NOT NULL,
  jurisdiction text NOT NULL CHECK (jurisdiction IN ('EU','DE')),
  url          text
);

-- Jurisdiction facts the narrative may cite (e.g. state-level mandatory dog liability). Maintained by Compliance.
CREATE TABLE ref.jurisdiction_fact (
  fact_key     text NOT NULL,                       -- 'DOG_LIABILITY_MANDATORY'
  region_code  text NOT NULL,                       -- 'DE-BE', 'DE-HH', 'DE-NI', ...
  value        jsonb NOT NULL,
  source       text NOT NULL,
  verified_at  date NOT NULL,
  PRIMARY KEY (fact_key, region_code)
);

-- =============================================================================
-- SRC : MOCK systems of record (POC only - replaced by PAS/CRM/Claims adapters)
-- =============================================================================
CREATE TABLE src.customer (
  customer_id        text PRIMARY KEY,              -- CUST-90124
  full_name          text NOT NULL,                 -- [PII]
  date_of_birth      date,                          -- [PII] not used by rules; not shown by default
  street_address     text,                          -- [PII]
  postal_code        text,                          -- [PII]
  city               text,
  region_code        text,                          -- Bundesland, e.g. DE-BY
  preferred_language text NOT NULL DEFAULT 'de',
  preferred_channel  text NOT NULL DEFAULT 'POST' CHECK (preferred_channel IN ('POST','PORTAL','EMAIL')),
  occupancy          text CHECK (occupancy IN ('OWNER_OCCUPIER','TENANT','LANDLORD')),
  dwelling_type      text CHECK (dwelling_type IN ('APARTMENT','DETACHED','SEMI_DETACHED','TERRACED')),
  household_type     text CHECK (household_type IN ('SINGLE','COUPLE','FAMILY','SINGLE_PARENT')),
  primary_earner     boolean,
  has_dependants     boolean,
  household_vehicle_count int,
  payment_status     text NOT NULL DEFAULT 'CURRENT' CHECK (payment_status IN ('CURRENT','ARREARS','DEBT_RECOVERY','DD_RETURNED')),
  vulnerability_hold boolean NOT NULL DEFAULT false,  -- flag only; reason held in CRM, never here
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- Declared / verified customer facts with provenance (Data Integrity Gate input)
CREATE TABLE src.customer_declared_fact (
  customer_id   text NOT NULL REFERENCES src.customer,
  fact_key      text NOT NULL,                      -- dog_owner, horse_owner, high_value_bike_owner, external_vehicle ...
  value         jsonb NOT NULL,
  source        text NOT NULL CHECK (source IN ('APPLICATION','CSR_CALL','PORTAL','PAS','CLAIM','THIRD_PARTY')),
  verified      boolean NOT NULL DEFAULT false,
  declared_at   date NOT NULL,
  PRIMARY KEY (customer_id, fact_key)
);

CREATE TABLE src.consent (
  customer_id   text NOT NULL REFERENCES src.customer,
  purpose       text NOT NULL CHECK (purpose IN ('ADVISORY_RENEWAL','MARKETING_EMAIL','MARKETING_PHONE','MARKETING_POST','PROFILING')),
  status        text NOT NULL CHECK (status IN ('GRANTED','REVOKED','UNSPECIFIED')),
  channel       text,
  captured_at   timestamptz NOT NULL,
  evidence_ref  text,                               -- pointer to consent evidence (GDPR Art. 7(1))
  PRIMARY KEY (customer_id, purpose)
);

CREATE TABLE src.policy (
  policy_id        text PRIMARY KEY,                -- POL-CAR-440192
  customer_id      text NOT NULL REFERENCES src.customer,
  lob_code         text NOT NULL REFERENCES ref.line_of_business,
  base_product_code text NOT NULL REFERENCES ref.product,
  coverage_level   text CHECK (coverage_level IN ('TPL','PARTIAL','FULL')),   -- motor only
  package_tier     text CHECK (package_tier IN ('SMART','COMFORT','PREMIUM')),
  status           text NOT NULL CHECK (status IN ('ACTIVE','LAPSED','CANCELLED')),
  inception_date   date NOT NULL,
  expiry_date      date NOT NULL,
  annual_premium_gross numeric(12,2) NOT NULL,
  insurance_tax    numeric(12,2),                   -- Versicherungsteuer
  payment_frequency text NOT NULL DEFAULT 'ANNUAL' CHECK (payment_frequency IN ('ANNUAL','SEMI','QUARTERLY','MONTHLY'))
);

CREATE TABLE src.policy_module (
  policy_id     text NOT NULL REFERENCES src.policy,
  product_code  text NOT NULL REFERENCES ref.product,  -- riders, coverage, tiers attached
  attached_at   date NOT NULL,
  PRIMARY KEY (policy_id, product_code)
);

CREATE TABLE src.insured_vehicle (
  policy_id      text PRIMARY KEY REFERENCES src.policy,
  make_model     text NOT NULL,
  build_year     int  NOT NULL,
  first_registration date,
  market_value   numeric(12,2),
  market_value_as_of date,
  annual_km      int,
  annual_km_verified boolean NOT NULL DEFAULT false,
  bonus_tier     int,                               -- SF-Klasse (Schadenfreiheitsklasse)
  registration_plate text                           -- [PII]
);

CREATE TABLE src.insured_property (
  policy_id      text PRIMARY KEY REFERENCES src.policy,
  dwelling_type  text CHECK (dwelling_type IN ('APARTMENT','DETACHED','SEMI_DETACHED','TERRACED')),
  build_year     int,
  floor_area_sqm int,
  zuers_zone     int CHECK (zuers_zone BETWEEN 1 AND 4),    -- GDV ZUeRS Geo flood hazard class
  heavy_rain_class int CHECK (heavy_rain_class BETWEEN 1 AND 3), -- GDV Starkregen-Gefaehrdungsklasse
  backwater_valve_certified boolean,
  has_solar_or_heatpump boolean,
  basement_or_ground_floor_storage boolean
);

CREATE TABLE src.insured_animal (
  policy_id      text NOT NULL REFERENCES src.policy,
  animal_ref     text NOT NULL,
  species        text NOT NULL CHECK (species IN ('DOG','CAT','HORSE')),
  breed          text,
  birth_year     int,
  PRIMARY KEY (policy_id, animal_ref)
);

CREATE TABLE src.claim (
  claim_id       text PRIMARY KEY,
  policy_id      text NOT NULL REFERENCES src.policy,
  customer_id    text NOT NULL REFERENCES src.customer,
  loss_date      date NOT NULL,
  reported_date  date NOT NULL,
  peril          text,                              -- COLLISION, WATER, THEFT, VET ...
  at_fault       boolean,
  severity       text CHECK (severity IN ('MINOR','MAJOR')),
  status         text NOT NULL CHECK (status IN ('OPEN','IN_SETTLEMENT','DISPUTED','LITIGATION','CLOSED')),
  status_changed_at timestamptz NOT NULL
);

CREATE TABLE src.complaint (
  complaint_id   text PRIMARY KEY,
  customer_id    text NOT NULL REFERENCES src.customer,
  opened_at      timestamptz NOT NULL,
  status         text NOT NULL CHECK (status IN ('OPEN','ESCALATED','OMBUDSMAN','RESOLVED','CLOSED')),
  closed_at      timestamptz
  -- complaint narrative deliberately NOT replicated (data minimisation)
);

CREATE TABLE src.renewal_quote (
  quote_id         text PRIMARY KEY,                -- QUO-2026-88129
  policy_id        text NOT NULL REFERENCES src.policy,
  created_at       timestamptz NOT NULL,
  status           text NOT NULL CHECK (status IN ('QUOTED','WITHDRAWN','ACCEPTED','LAPSED')),
  renewal_date     date NOT NULL,
  letter_due_date  date NOT NULL,                   -- end of operational window
  expiring_premium_gross numeric(12,2) NOT NULL,
  renewal_premium_gross  numeric(12,2) NOT NULL,
  renewal_insurance_tax  numeric(12,2)
);

-- Rating-engine quotes for candidate riders/companions (BR-12 "verified pricing")
CREATE TABLE src.rating_quote (
  rating_quote_id  text PRIMARY KEY,
  quote_id         text NOT NULL REFERENCES src.renewal_quote,
  product_code     text NOT NULL REFERENCES ref.product,
  variant          text,                            -- e.g. PL tariff FAMILY / COMFORT
  annual_gross     numeric(12,2) NOT NULL,
  insurance_tax    numeric(12,2),
  instalment_surcharge_pct numeric(5,2) DEFAULT 0,  -- Ratenzahlungszuschlag if paid monthly
  valid_until      date NOT NULL,
  rated_at         timestamptz NOT NULL,
  UNIQUE (quote_id, product_code, variant)
);

-- =============================================================================
-- RULES : registry, parameters, maker-checker, tests
-- =============================================================================
CREATE TABLE rules.ruleset (
  ruleset_version  text PRIMARY KEY,                -- semver, e.g. 1.0.0
  jurisdiction     text NOT NULL DEFAULT 'DE',
  status           text NOT NULL CHECK (status IN ('DRAFT','IN_REVIEW','APPROVED','PUBLISHED','RETIRED')),
  catalog_json     jsonb NOT NULL,                  -- full compiled catalog (rule_catalog.vX.json)
  catalog_sha256   text NOT NULL,
  effective_from   timestamptz,
  created_by       text NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  approved_by      text,                            -- must differ from created_by (four-eyes)
  approved_at      timestamptz,
  published_at     timestamptz,
  golden_run_id    uuid,                            -- last green golden-test run (publish gate)
  CONSTRAINT four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by)
);
CREATE UNIQUE INDEX one_published_ruleset ON rules.ruleset (jurisdiction) WHERE status = 'PUBLISHED';

-- Denormalised view of rules for UI, search, reporting (source of truth = catalog_json)
CREATE TABLE rules.rule (
  ruleset_version  text NOT NULL REFERENCES rules.ruleset,
  rule_id          text NOT NULL,                   -- GK-01, UP-CAR-04, CS-LIA-01
  stage            text NOT NULL CHECK (stage IN ('WINDOW','GATEKEEPER','FILTER','OPPORTUNITY','RANKING')),
  rule_type        text CHECK (rule_type IN ('SUPPRESSION','UPSELL','CROSS_SELL','FILTER')),
  name             text NOT NULL,
  product_code     text REFERENCES ref.product,
  lob_code         text REFERENCES ref.line_of_business,
  priority_tier    text CHECK (priority_tier IN ('P1','P2','P3')),
  sequence         int,
  exclusion_group  text,
  risk_class       text,
  condition_jsonlogic jsonb,
  required_facts   text[] NOT NULL DEFAULT '{}',
  status           text NOT NULL CHECK (status IN ('ACTIVE','DRAFT','PENDING_DECISION','RETIRED')),
  source_refs      text[] NOT NULL DEFAULT '{}',    -- BA document IDs this rule supersedes
  regulatory_refs  text[] NOT NULL DEFAULT '{}',
  open_decisions   text[] NOT NULL DEFAULT '{}',
  PRIMARY KEY (ruleset_version, rule_id)
);

CREATE TABLE rules.parameter (
  ruleset_version  text NOT NULL REFERENCES rules.ruleset,
  param_key        text NOT NULL,
  value            jsonb NOT NULL,
  value_type       text NOT NULL CHECK (value_type IN ('int','decimal','enum','bool','text')),
  min_value        numeric,
  max_value        numeric,
  source           text,
  owner_role       text NOT NULL DEFAULT 'RULE_AUTHOR',
  PRIMARY KEY (ruleset_version, param_key)
);

CREATE TABLE rules.change_request (
  change_request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  base_version     text NOT NULL REFERENCES rules.ruleset,
  target_version   text NOT NULL,
  summary          text NOT NULL,
  diff_json        jsonb NOT NULL,                  -- RFC 6902 JSON Patch against catalog
  justification    text NOT NULL,                   -- business / regulatory rationale
  impact_report    jsonb,                           -- backtest: decisions that would change
  status           text NOT NULL CHECK (status IN ('DRAFT','SUBMITTED','APPROVED','REJECTED','PUBLISHED')),
  maker            text NOT NULL,
  checker          text,
  submitted_at     timestamptz,
  decided_at       timestamptz,
  CONSTRAINT cr_four_eyes CHECK (checker IS NULL OR checker <> maker)
);

CREATE TABLE rules.golden_test (
  test_id          text PRIMARY KEY,                -- BAC-04, SCN-01, X-07
  title            text NOT NULL,
  base_fixture     text NOT NULL,
  overrides        jsonb NOT NULL DEFAULT '{}',
  expectation      jsonb NOT NULL,
  origin           text NOT NULL CHECK (origin IN ('BRD_BAC','BRD_SCENARIO','ARCHITECT','REGRESSION','INCIDENT')),
  active           boolean NOT NULL DEFAULT true
);

CREATE TABLE rules.golden_run (
  golden_run_id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ruleset_version  text NOT NULL,
  engine_version   text NOT NULL,
  started_at       timestamptz NOT NULL DEFAULT now(),
  passed           int NOT NULL,
  failed           int NOT NULL,
  results          jsonb NOT NULL
);

-- =============================================================================
-- SRA : operational advisor data
-- =============================================================================
CREATE TABLE sra.renewal_case (
  case_id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id         text NOT NULL UNIQUE,
  quote_version    int  NOT NULL DEFAULT 1,           -- re-quotes from PAS increment; newer supersedes open recs
  policy_id        text NOT NULL,
  customer_id      text NOT NULL,
  lob_code         text NOT NULL,
  customer_display_name text NOT NULL,              -- [PII] queue display only
  renewal_date     date NOT NULL,
  letter_due_date  date NOT NULL,
  expiring_premium numeric(12,2) NOT NULL,
  renewal_premium  numeric(12,2) NOT NULL,
  state            text NOT NULL CHECK (state IN ('RECEIVED','EVALUATED','SUPPRESSED','READY_FOR_REVIEW','IN_REVIEW',
                                                  'DECIDED','LETTER_DRAFTED','LETTER_APPROVED','DISPATCHED','CLOSED','NOT_TRIGGERED')),
  opportunity_signal text CHECK (opportunity_signal IN ('NONE','UPSELL','CROSS_SELL','UPSELL_AND_CROSS_SELL','MULTI_UPSELL','MULTI_CROSS_SELL','SUPPRESSED')),
  suppression_reason_codes text[] NOT NULL DEFAULT '{}',
  current_decision_run_id uuid,
  assigned_officer text,                            -- Entra object id
  service_center   text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  row_version      int NOT NULL DEFAULT 1,          -- optimistic locking for concurrent officers
  retention_class  text NOT NULL DEFAULT 'ADVICE_RECORD'
);
CREATE INDEX renewal_case_queue_idx ON sra.renewal_case (state, letter_due_date);
CREATE INDEX renewal_case_lob_idx   ON sra.renewal_case (lob_code, state);
CREATE INDEX renewal_case_officer_idx ON sra.renewal_case (assigned_officer, state);

-- Immutable Policy Snapshot & Renewal Quote Record (BRD §5) as received + derived Decision Context
CREATE TABLE sra.policy_snapshot (
  snapshot_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  captured_at      timestamptz NOT NULL DEFAULT now(),
  source_event_id  text,                            -- CloudEvents id of RenewalQuoteCreated
  raw_payload      jsonb NOT NULL,                  -- [PII] as received from PAS/CRM/Claims
  decision_context jsonb NOT NULL,                  -- derived facts fed to the engine (see personas.json)
  context_sha256   text NOT NULL,
  fact_builder_version text NOT NULL,
  retention_class  text NOT NULL DEFAULT 'ADVICE_RECORD'
);
CREATE INDEX policy_snapshot_case_idx ON sra.policy_snapshot (case_id, captured_at DESC);
CREATE TRIGGER policy_snapshot_immutable BEFORE UPDATE OR DELETE ON sra.policy_snapshot
  FOR EACH ROW EXECUTE FUNCTION sra.forbid_mutation();

-- Per-fact provenance for the Data Integrity Gate and the officer "data quality" panel
CREATE TABLE sra.snapshot_fact (
  snapshot_id      uuid NOT NULL REFERENCES sra.policy_snapshot,
  fact_path        text NOT NULL,                   -- e.g. vehicle.annual_km
  value            jsonb,
  quality          text NOT NULL CHECK (quality IN ('OK','MISSING','UNVERIFIED','STALE')),
  source_system    text NOT NULL,
  source_ref       text,
  as_of            date,
  PRIMARY KEY (snapshot_id, fact_path)
);

CREATE TABLE sra.decision_run (
  decision_run_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  snapshot_id      uuid NOT NULL REFERENCES sra.policy_snapshot,
  ruleset_version  text NOT NULL REFERENCES rules.ruleset,
  engine_version   text NOT NULL,
  trigger          text NOT NULL CHECK (trigger IN ('EVENT','OFFICER_REQUEST','STALE_REFRESH','REPLAY','WHAT_IF')),
  is_sandbox       boolean NOT NULL DEFAULT false,  -- copilot what-if runs: never drive letters
  as_of            date NOT NULL,
  status           text NOT NULL CHECK (status IN ('NOT_TRIGGERED','SUPPRESSED','NO_OPPORTUNITY','RECOMMENDATIONS_AVAILABLE')),
  suppression_reasons text[] NOT NULL DEFAULT '{}',
  input_sha256     text NOT NULL,                   -- = snapshot.context_sha256 (+ overrides for what-if)
  output_sha256    text NOT NULL,                   -- reproducibility: replay must match
  duration_ms      int,
  requested_by     text,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX decision_run_case_idx ON sra.decision_run (case_id, created_at DESC);
CREATE TRIGGER decision_run_immutable BEFORE UPDATE OR DELETE ON sra.decision_run
  FOR EACH ROW EXECUTE FUNCTION sra.forbid_mutation();

-- One row per rule evaluated (fired or not) - the explainability backbone
CREATE TABLE sra.rule_evaluation (
  decision_run_id  uuid NOT NULL REFERENCES sra.decision_run,
  seq              int  NOT NULL,
  rule_id          text NOT NULL,
  stage            text NOT NULL,
  product_code     text,
  outcome          text NOT NULL CHECK (outcome IN ('PASSED','NOT_TRIGGERED','SUPPRESS','SUPPRESS_DATA_INTEGRITY','NOT_APPLICABLE',
                     'RULE_INACTIVE','ALREADY_COVERED','COVERED_BY_ENDORSEMENT','COOLDOWN_ACTIVE','DATA_INTEGRITY_FAIL',
                     'DISQUALIFIED_RISK','REFERRAL_REQUIRED','TARGET_MARKET_MISMATCH','DISQUALIFIED_NO_VERIFIED_PRICE','ELIGIBLE')),
  detail           text,
  clauses          jsonb NOT NULL DEFAULT '[]',     -- [{left,left_value,op,right,right_value,result}]
  PRIMARY KEY (decision_run_id, seq)
);
CREATE INDEX rule_evaluation_rule_idx ON sra.rule_evaluation (rule_id, outcome);  -- rule tuning analytics
CREATE TRIGGER rule_evaluation_immutable BEFORE UPDATE OR DELETE ON sra.rule_evaluation
  FOR EACH ROW EXECUTE FUNCTION sra.forbid_mutation();

CREATE TABLE sra.recommendation (
  recommendation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recommendation_ref text NOT NULL UNIQUE,          -- REC-2026-0041 (BRD output field)
  decision_run_id  uuid NOT NULL REFERENCES sra.decision_run,
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  rule_id          text NOT NULL,
  opportunity_type text NOT NULL CHECK (opportunity_type IN ('UPSELL','CROSS_SELL')),
  product_code     text NOT NULL REFERENCES ref.product,
  product_variant  text,
  priority_tier    text NOT NULL,
  selection        text NOT NULL CHECK (selection IN ('PRIMARY','ALTERNATIVE','NOT_SELECTED','EXCLUDED_BY_GROUP')),
  rank             int  NOT NULL,
  status           text NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING','INCLUDED','SKIPPED','DEFERRED','EXPIRED','SUPERSEDED')),
  superseded_by    uuid REFERENCES sra.recommendation,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX recommendation_case_idx ON sra.recommendation (case_id, status);

-- Deterministic pricing outputs (BR-12) incl. combination scenarios when both recs are included
CREATE TABLE sra.pricing_scenario (
  pricing_scenario_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  decision_run_id  uuid NOT NULL REFERENCES sra.decision_run,
  included_recommendation_ids uuid[] NOT NULL,      -- {} = base renewal only
  expiring_premium numeric(12,2) NOT NULL,
  base_renewal_premium numeric(12,2) NOT NULL,
  upsell_increment_annual numeric(12,2) NOT NULL DEFAULT 0,
  companion_standalone_annual numeric(12,2) NOT NULL DEFAULT 0,
  bundle_discount_pct numeric(5,2) NOT NULL DEFAULT 0,
  bundle_saving_annual numeric(12,2) NOT NULL DEFAULT 0,
  net_annual_total numeric(12,2) NOT NULL,
  monthly_equivalent numeric(12,2) NOT NULL,
  instalment_note  text,                            -- if monthly payment carries a surcharge
  rating_quote_refs text[] NOT NULL,                -- provenance to PAS rating quotes
  calc_version     text NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT net_consistency CHECK (net_annual_total = base_renewal_premium + upsell_increment_annual
                                                      + companion_standalone_annual - bundle_saving_annual)
);

-- GenAI narratives - versioned, validated, and editable by the officer
CREATE TABLE sra.narrative (
  narrative_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recommendation_id uuid NOT NULL REFERENCES sra.recommendation,
  audience         text NOT NULL CHECK (audience IN ('OFFICER','CUSTOMER_LETTER')),
  language         text NOT NULL CHECK (language IN ('de','en')),
  version          int  NOT NULL,
  origin           text NOT NULL CHECK (origin IN ('LLM','TEMPLATE_FALLBACK','OFFICER_EDIT')),
  content          jsonb NOT NULL,                  -- {why_recommended, current_gap, how_it_helps, key_benefits[], comparison_rows[], letter_rationale}
  fact_pack_sha256 text NOT NULL,                   -- cache key + provenance
  prompt_template_id text,
  model_deployment text,                            -- e.g. gpt-5.x-dz-eu / claude-sonnet-...
  llm_call_id      uuid,
  validation_status text NOT NULL CHECK (validation_status IN ('PASSED','FAILED','NOT_APPLICABLE')),
  edited_by        text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recommendation_id, audience, language, version)
);

CREATE TABLE sra.narrative_validation (
  narrative_id     uuid NOT NULL REFERENCES sra.narrative,
  validator        text NOT NULL CHECK (validator IN ('SCHEMA','NUMBER_PROVENANCE','APPROVED_CLAIMS','PROHIBITED_PHRASES',
                                                      'PII_LEAK','PROTECTED_ATTRIBUTES','LENGTH_READABILITY','CONTENT_SAFETY','GROUNDEDNESS')),
  passed           boolean NOT NULL,
  findings         jsonb NOT NULL DEFAULT '[]',
  PRIMARY KEY (narrative_id, validator)
);

-- Human-in-the-loop actions (BR-10 / BR-11). Undo is a new REVERSAL row, never an update.
CREATE TABLE sra.officer_action (
  action_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recommendation_id uuid NOT NULL REFERENCES sra.recommendation,
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  action           text NOT NULL CHECK (action IN ('INCLUDE','SKIP','DEFER','REVERSAL','VIEWED')),
  skip_reason_code text REFERENCES ref.skip_reason,
  defer_reason_code text REFERENCES ref.defer_reason,
  follow_up_at     timestamptz,
  comment          text,
  reverses_action_id uuid REFERENCES sra.officer_action,
  narrative_id_shown uuid REFERENCES sra.narrative, -- what the officer actually saw
  acted_by         text NOT NULL,
  acted_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT skip_needs_reason  CHECK (action <> 'SKIP'  OR skip_reason_code  IS NOT NULL),
  CONSTRAINT defer_needs_reason CHECK (action <> 'DEFER' OR (defer_reason_code IS NOT NULL AND follow_up_at IS NOT NULL)),
  CONSTRAINT reversal_target    CHECK (action <> 'REVERSAL' OR reverses_action_id IS NOT NULL)
);
CREATE INDEX officer_action_rec_idx ON sra.officer_action (recommendation_id, acted_at);

-- Cooldown ledger (EL-03). Durable across renewal cycles.
CREATE TABLE sra.recommendation_decline (
  decline_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id      text NOT NULL,
  product_code     text NOT NULL REFERENCES ref.product,
  declined_at      date NOT NULL,
  source           text NOT NULL CHECK (source IN ('OFFICER_SKIP','CUSTOMER_PORTAL','CSR_CALL','LETTER_NO_RESPONSE','MIGRATED')),
  recommendation_id uuid REFERENCES sra.recommendation,
  cooldown_until   date NOT NULL
);
CREATE INDEX recommendation_decline_lookup ON sra.recommendation_decline (customer_id, product_code, cooldown_until);

CREATE TABLE sra.letter_draft (
  letter_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  version          int  NOT NULL,
  language         text NOT NULL CHECK (language IN ('de','en')),
  template_version text NOT NULL,
  letter_type      text NOT NULL CHECK (letter_type IN ('STANDARD','ADVISORY')),
  pricing_scenario_id uuid REFERENCES sra.pricing_scenario,
  status           text NOT NULL CHECK (status IN ('DRAFT','APPROVED','SENT','CANCELLED')),
  rendered_html_uri text,
  rendered_pdf_uri  text,                           -- immutable blob once APPROVED
  content_sha256   text,
  approved_by      text,
  approved_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (case_id, version)
);

-- Section model enforces BR-13 demarcation: core terms vs optional advisory block
CREATE TABLE sra.letter_section (
  letter_id        uuid NOT NULL REFERENCES sra.letter_draft,
  seq              int  NOT NULL,
  section_type     text NOT NULL CHECK (section_type IN ('CORE_RENEWAL_TERMS','PREMIUM_CHANGE_NOTICE','ADVISORY_BLOCK',
                                                         'BUNDLE_SAVINGS','OPT_IN_INSTRUCTION','OBJECTION_NOTICE','ATTACHMENTS')),
  recommendation_id uuid REFERENCES sra.recommendation,
  content          jsonb NOT NULL,
  PRIMARY KEY (letter_id, seq)
);

CREATE TABLE sra.letter_dispatch (
  dispatch_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  letter_id        uuid NOT NULL REFERENCES sra.letter_draft,
  channel          text NOT NULL CHECK (channel IN ('POST','PORTAL','EMAIL')),
  oms_reference    text,
  dispatched_at    timestamptz NOT NULL,
  dispatched_by    text NOT NULL
);

-- Customer response to the advisory block (explicit opt-in only, BRD Stage 5)
CREATE TABLE sra.customer_response (
  response_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recommendation_id uuid NOT NULL REFERENCES sra.recommendation,
  response         text NOT NULL CHECK (response IN ('OPTED_IN','DECLINED','NO_RESPONSE')),
  channel          text NOT NULL CHECK (channel IN ('PORTAL','CSR_CALL','POST')),
  captured_at      timestamptz NOT NULL,
  captured_by      text,
  advice_record_id uuid,                            -- -> sra.advice_record when opted in via CSR
  pas_transaction_ref text                          -- endorsement / new policy number in PAS
);

-- Demands-and-needs / advice documentation (IDD Art. 20, VVG §6) when the customer engages
CREATE TABLE sra.advice_record (
  advice_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  recommendation_id uuid REFERENCES sra.recommendation,
  customer_wishes_needs text NOT NULL,
  advice_given     text NOT NULL,
  reasons          text NOT NULL,
  ipid_document_id uuid REFERENCES ref.product_document,
  advice_waived    boolean NOT NULL DEFAULT false,  -- separate written waiver held as evidence
  recorded_by      text NOT NULL,
  recorded_at      timestamptz NOT NULL DEFAULT now(),
  provided_to_customer_at timestamptz,
  retention_class  text NOT NULL DEFAULT 'ADVICE_RECORD'
);

-- Copilot (agentic) - every turn and tool call is recorded
CREATE TABLE sra.copilot_session (
  session_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id          uuid NOT NULL REFERENCES sra.renewal_case,
  officer_id       text NOT NULL,
  model_deployment text NOT NULL,
  agent_version    text NOT NULL,
  started_at       timestamptz NOT NULL DEFAULT now(),
  ended_at         timestamptz
);

CREATE TABLE sra.copilot_message (
  session_id       uuid NOT NULL REFERENCES sra.copilot_session,
  seq              int  NOT NULL,
  role             text NOT NULL CHECK (role IN ('OFFICER','ASSISTANT','TOOL')),
  content          text NOT NULL,                   -- pseudonymised before LLM; re-identified for display
  citations        jsonb NOT NULL DEFAULT '[]',     -- rule ids, decision_run ids, AVB passages
  safety_flags     jsonb NOT NULL DEFAULT '[]',
  feedback         text CHECK (feedback IN ('UP','DOWN')),
  created_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (session_id, seq)
);

CREATE TABLE sra.copilot_tool_call (
  session_id       uuid NOT NULL,
  seq              int  NOT NULL,
  tool_name        text NOT NULL CHECK (tool_name IN ('get_case_summary','get_decision_trace','explain_rule',
                                                     'simulate_what_if','search_product_terms','draft_call_notes')),
  arguments        jsonb NOT NULL,
  result_summary   jsonb,
  sandbox_decision_run_id uuid REFERENCES sra.decision_run,
  latency_ms       int,
  PRIMARY KEY (session_id, seq),
  FOREIGN KEY (session_id, seq) REFERENCES sra.copilot_message (session_id, seq)
);

-- =============================================================================
-- AI ops: prompt registry, model registry, LLM call log, evaluations
-- =============================================================================
CREATE TABLE sra.prompt_template (
  prompt_template_id text PRIMARY KEY,              -- narrative.officer.v3
  purpose          text NOT NULL CHECK (purpose IN ('NARRATIVE_OFFICER','NARRATIVE_LETTER','COPILOT_SYSTEM')),
  body             text NOT NULL,
  output_schema    jsonb,
  approved_by      text,
  approved_at      timestamptz,
  status           text NOT NULL CHECK (status IN ('DRAFT','APPROVED','RETIRED'))
);

CREATE TABLE sra.model_deployment (
  deployment_name  text PRIMARY KEY,
  provider         text NOT NULL CHECK (provider IN ('AZURE_OPENAI','ANTHROPIC_FOUNDRY')),
  model_id         text NOT NULL,
  deployment_type  text NOT NULL,                   -- DataZoneStandard (EU), GlobalStandard, ...
  data_boundary    text NOT NULL CHECK (data_boundary IN ('EU','GLOBAL','US')),
  allowed_data_classes text[] NOT NULL,             -- {'SYNTHETIC'} or {'SYNTHETIC','PSEUDONYMISED'}
  active           boolean NOT NULL DEFAULT true
);

CREATE TABLE sra.llm_call (
  llm_call_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purpose          text NOT NULL,
  deployment_name  text NOT NULL REFERENCES sra.model_deployment,
  prompt_template_id text REFERENCES sra.prompt_template,
  data_class       text NOT NULL CHECK (data_class IN ('SYNTHETIC','PSEUDONYMISED')),
  request_sha256   text NOT NULL,                   -- full prompt kept in Log Analytics (30-90d), not here
  input_tokens     int, output_tokens int, latency_ms int,
  finish_reason    text,
  content_safety   jsonb,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sra.eval_run (
  eval_run_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  suite            text NOT NULL,                   -- narrative_golden_v1, copilot_redteam_v1
  deployment_name  text NOT NULL,
  prompt_template_id text,
  metrics          jsonb NOT NULL,                  -- groundedness, number_accuracy, prohibited_rate, de_fluency ...
  passed_gate      boolean NOT NULL,
  run_at           timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- AUDIT : append-only, hash-chained ledger (BR-11 skip logging, BRD Stage 4 audit)
-- =============================================================================
CREATE TABLE audit.audit_event (
  event_seq        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id         uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  actor_type       text NOT NULL CHECK (actor_type IN ('SYSTEM','OFFICER','RULE_ADMIN','COPILOT','INTEGRATION')),
  actor_id         text NOT NULL,
  case_id          uuid,
  entity_type      text NOT NULL,                   -- DECISION_RUN, RECOMMENDATION, LETTER, RULESET, ...
  entity_id        text NOT NULL,
  event_type       text NOT NULL,                   -- EVALUATED, SUPPRESSED, INCLUDED, SKIPPED, DEFERRED, REVERSED, LETTER_APPROVED ...
  payload          jsonb NOT NULL,
  prev_hash        text NOT NULL,
  hash             text NOT NULL                    -- sha256(prev_hash || canonical(payload) || occurred_at)
);
CREATE INDEX audit_event_case_idx ON audit.audit_event (case_id, event_seq);
CREATE TRIGGER audit_event_immutable BEFORE UPDATE OR DELETE ON audit.audit_event
  FOR EACH ROW EXECUTE FUNCTION sra.forbid_mutation();

-- =============================================================================
-- Read models for the Officer Console (mirrors prototype screens)
-- =============================================================================
CREATE OR REPLACE VIEW sra.v_queue AS
SELECT c.case_id, c.policy_id, c.customer_id, c.customer_display_name, c.lob_code,
       c.expiring_premium, c.renewal_premium, c.renewal_date, c.letter_due_date,
       c.state, c.opportunity_signal, c.suppression_reason_codes, c.assigned_officer,
       (c.letter_due_date - CURRENT_DATE) AS days_to_letter_due
FROM sra.renewal_case c;

CREATE OR REPLACE VIEW sra.v_queue_kpis AS
SELECT count(*)                                              AS total_quotes,
       count(*) FILTER (WHERE state IN ('READY_FOR_REVIEW','IN_REVIEW','DECIDED','LETTER_DRAFTED')) AS pending_review,
       count(*) FILTER (WHERE state = 'SUPPRESSED')          AS conduct_hold,
       count(*) FILTER (WHERE state IN ('DISPATCHED','CLOSED')) AS dispatched
FROM sra.renewal_case;

-- Latest effective officer decision per recommendation (reversals cancel earlier actions)
CREATE OR REPLACE VIEW sra.v_recommendation_current_action AS
SELECT DISTINCT ON (a.recommendation_id) a.*
FROM sra.officer_action a
WHERE a.action IN ('INCLUDE','SKIP','DEFER')
  AND NOT EXISTS (SELECT 1 FROM sra.officer_action r WHERE r.reverses_action_id = a.action_id)
ORDER BY a.recommendation_id, a.acted_at DESC;

-- Rule-tuning analytics (feeds BA: skip reasons by rule; BR-11 intent)
CREATE OR REPLACE VIEW sra.v_rule_effectiveness AS
SELECT r.rule_id, r.product_code,
       count(*)                                         AS surfaced,
       count(*) FILTER (WHERE ca.action = 'INCLUDE')    AS included,
       count(*) FILTER (WHERE ca.action = 'SKIP')       AS skipped,
       array_agg(ca.skip_reason_code) FILTER (WHERE ca.action = 'SKIP') AS skip_reasons,
       count(*) FILTER (WHERE EXISTS (SELECT 1 FROM sra.customer_response cr
                                      WHERE cr.recommendation_id = r.recommendation_id
                                        AND cr.response = 'OPTED_IN')) AS customer_opt_ins
FROM sra.recommendation r
LEFT JOIN sra.v_recommendation_current_action ca ON ca.recommendation_id = r.recommendation_id
WHERE r.selection IN ('PRIMARY','ALTERNATIVE')
GROUP BY r.rule_id, r.product_code;
