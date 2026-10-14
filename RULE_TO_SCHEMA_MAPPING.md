# Smart Renewal Advisor — Rule-to-Schema Mapping

This document maps every rule in **Section 2 (Gatekeeper Safeguards)**, **Section 3 (Upsell Rules)**
and **Section 4 (Cross-Sell Rules)** of `Smart_Renewal_Advisor_Rules 1.docx` to the exact table(s)
and column(s) needed to evaluate it against your existing `cross_selldb` schema.

The accompanying `new_schema.sql` contains the actual `CREATE TABLE` / `ALTER TABLE` statements and
sample data. Nothing here has been run against your Azure Postgres instance — it's a design + script
for you to review and apply yourself (or ask me to run once you confirm).

---

## ⚠️ Data-integrity flag before you build this

`rule_matrix_2` (already in your DB) and the Word doc use **the same rule IDs for different rules**:

| Rule ID | `rule_matrix_2` says | Word doc says |
|---|---|---|
| UP-CAR-01 | TPL → Comprehensive upgrade | No-Claims Discount Protection Rider |
| UP-CAR-02 | Partial → Full Comprehensive upgrade | Basic Third-Party → Full Comprehensive upgrade |
| UP-CAR-03 | Smart → Comfort/Premium package tier | 24/7 Roadside Assistance & Courtesy Car Rider |
| CS-CAR-01 | Home Insurance cross-sell | Personal Liability Insurance cross-sell |

This schema is built to evaluate the **Word doc's** version of each rule (it's the one with real
qualification criteria, disqualification conditions, and pricing — `rule_matrix_2` is closer to a
summary/marketing table). You'll want to either retire `rule_matrix_2`'s overlapping rows or
renumber one of the two sets so IDs stop colliding.

---

## 1. Design approach

- **Extend `policies`** with fields common to every LOB (normalized coverage tier, numeric vehicle
  value, policy status).
- **Add one "detail" table per LOB** (`motor_policy_details`, `home_policy_details`,
  `pet_policy_details`) holding the facts only that LOB's rules need, 1:1 with `policies.policy_id`.
  This avoids a single sparse table with 40 mostly-NULL columns.
- **Add `claims_history` columns** for the numeric claim-window counts the rules actually test
  (`at_fault_claims_12mo`, `_24mo`, `_36mo`) — the existing `claims_last_3yrs_count` is free text
  ("1 Motor claim") and can't be compared with `>=`/`==`.
- **Add `customer_profile_facts`** — one row per customer — for facts that aren't tied to a specific
  policy (occupancy status, household vehicle count, employment/disability/pet-ownership facts,
  externally-held policies).
- **Add `customer_compliance_flags`** — one row per customer — for the BR-01..BR-06 gatekeeper facts
  (consent, payment status, complaints/disputes). These gate *everything*, so they're checked once
  per customer before any rule in Section 3/4 runs.
- **Add `rule_evaluation_log`** — an audit trail row per rule evaluated per call, which is what
  Section 1.1 of the doc says regulators require ("exact audit trail of every rule evaluated").
  Not strictly asked for, but it's the direct schema consequence of that requirement, and your
  existing tables have nothing that records a rule *firing* vs *failing* vs *suppressed*.
- **Reused, not duplicated:** anything derivable from existing data gets a note instead of a new
  column — e.g. "is single-policy holder" = `COUNT(*) FROM policies WHERE customer_id=... AND
  policy_status='Active'`, not a stored boolean that can drift out of sync.

---

## 2. Gatekeeper Safeguard Rules (Section 2, BR-01 to BR-06)

| Rule | Condition | Table.Column | Allowed values |
|---|---|---|---|
| BR-01 | `Advisory_Marketing_Consent == 'REVOKED'/'UNSPECIFIED'` | `customer_compliance_flags.advisory_marketing_consent` | `GRANTED`, `REVOKED`, `UNSPECIFIED` |
| BR-02 | `Policy_Payment_Status != 'CURRENT'` | `customer_compliance_flags.policy_payment_status` | `CURRENT`, `ARREARS`, `DEBT_RECOVERY`, `DISHONORED_DD` |
| BR-03 | `Open_Complaint_Flag`/`Disputed_Claim_Flag` within 180 days | `customer_compliance_flags.open_complaint_flag` (bool), `.disputed_claim_flag` (bool), `.complaint_or_dispute_date` (date — compare to `now() - interval '180 days'`) | bool; date |
| BR-04 | Declined same product within 180 days | **existing** `recommendation_cooldown` (`customer_id`, `opportunity_name`, `declined_at`, `cooldown_until`) — no new table needed | — |
| BR-05 (motor) | `At_Fault_Claims_24Mo >= 2` or `Penalty_Points >= 4` | `claims_history.at_fault_claims_24mo` (new); `claims_history.demerit_points` (**existing** — reuse as `Penalty_Points`, do not duplicate) | int; int |
| BR-05 (property) | `Open_Litigation_Claims > 0` | `home_policy_details.open_litigation_claims` | int |
| BR-06 | Profile mismatch (e.g. Building cover offered to a tenant) | logic only — compare `customer_profile_facts.occupancy_status` to the product's target LOB; no new column | — |

---

## 3. Upsell Rules (Section 3)

### 3.1 Motor

**UP-CAR-01 — NCD Protection Rider**
| Criterion | Table.Column |
|---|---|
| Primary policy is Car Insurance, Full Comprehensive | `policies.lob = 'Motor'`, `policies.coverage_tier = 'Full Comprehensive'` |
| Bonus_Tier >= 8 | `motor_policy_details.bonus_tier` (int) |
| 0 at-fault claims in preceding 36 months | `claims_history.at_fault_claims_36mo = 0` |
| NCD_Protection_Attached == FALSE | `motor_policy_details.ncd_protection_attached` (bool) |

**UP-CAR-02 — Third-Party → Full Comprehensive**
| Criterion | Table.Column |
|---|---|
| Vehicle market value >= €8,000 | `policies.vehicle_market_value_eur` (numeric, new) |
| Vehicle age <= 8 years | `policies.vehicle_age_years` (int, new) |
| <=1 minor claim in 36mo, 0 claims in 12mo | `claims_history.minor_claims_36mo`, `claims_history.at_fault_claims_12mo` |
| Marketing consent granted | `customer_compliance_flags.advisory_marketing_consent = 'GRANTED'` |

**UP-CAR-03 — Roadside Assistance & Courtesy Car Rider**
| Criterion | Table.Column |
|---|---|
| Annual mileage >= 12,000 km | `motor_policy_details.annual_mileage_km` (int) |
| Household vehicle count == 1 | `customer_profile_facts.household_vehicle_count` (int) |
| No Roadside Assistance rider currently | `motor_policy_details.roadside_assistance_attached = FALSE` |

### 3.2 Property & Home

**UP-HOM-01 — Extended Natural Hazards / Flood Cover Rider**
| Criterion | Table.Column |
|---|---|
| Primary policy is Home Building | `policies.lob = 'Home Building'` |
| Environmental_Zone in ('Zone 2','Zone 3') | `home_policy_details.environmental_zone` |
| Backwater valve certified / ground-level ingress protection | `home_policy_details.backwater_valve_certified`, `.ground_level_ingress_protection` (bool) |
| Flood_Cover_Attached == FALSE | `home_policy_details.flood_cover_attached` |
| Disqualify: Zone 4, or open water-damage claim in 24mo | `home_policy_details.environmental_zone = 'Zone 4'`; `.open_water_damage_claim_24mo` (bool) |

**UP-HOM-02 — High-Value Valuables Extension**
| Criterion | Table.Column |
|---|---|
| Active Contents policy | `policies.lob = 'Home Contents'`, `.policy_status = 'Active'` |
| Floor area >= 120 sqm | `home_policy_details.floor_area_sqm` (numeric) |

### 3.3 Pet

**UP-PET-01 — Surgical → Comprehensive Veterinary Health Rider**
| Criterion | Table.Column |
|---|---|
| Active Pet policy | `policies.lob = 'Pet'`, `.policy_status = 'Active'` |
| Pet age <= 7 years | `pet_policy_details.pet_age_years` (int) |
| <=1 minor outpatient claim in 24mo | `pet_policy_details.minor_outpatient_claims_24mo` (int) |

---

## 4. Cross-Sell Rules (Section 4)

**CS-CAR-01 — Car → Personal Liability**
| Criterion | Table.Column |
|---|---|
| Single-policy holder | derived: `COUNT(policies) WHERE policy_status='Active' = 1` (no stored column — see note below) |
| Lives in rented flat/home | `customer_profile_facts.occupancy_status = 'Tenant'` |
| No active liability policy on record | derived: `NOT EXISTS (SELECT 1 FROM policies WHERE lob='Personal Liability' AND policy_status='Active')` |

**CS-CAR-02 — Car → Personal Accident**
| Criterion | Table.Column |
|---|---|
| Commuter, >=15,000 km/year | `motor_policy_details.annual_mileage_km >= 15000` |
| Primary household wage earner | `customer_profile_facts.is_primary_wage_earner` (bool) |
| No personal disability cover | `customer_profile_facts.has_personal_disability_cover = FALSE` |

**CS-HOM-01 — Home Building → Home Contents**
| Criterion | Table.Column |
|---|---|
| Owner-occupier, detached house >=140 sqm | `customer_profile_facts.occupancy_status = 'Owner-Occupier'`; `home_policy_details.dwelling_type = 'Detached House'`; `.floor_area_sqm >= 140` |
| Zero contents insurance | derived: `NOT EXISTS (... lob='Home Contents' ...)` |

**CS-PET-01 — Pet → Car (Full Comprehensive)**
| Criterion | Table.Column |
|---|---|
| Loyal, >=3 claim-free years | `pet_policy_details.claim_free_years >= 3` |
| Operates family car insured externally, basic cover | `customer_profile_facts.external_motor_policy_held = TRUE`; `.external_motor_policy_tier = 'Basic'` |

**CS-LIA-01 — Personal Liability → Pet Health**
| Criterion | Table.Column |
|---|---|
| Declared dog/horse ownership | `customer_profile_facts.dog_or_horse_ownership = TRUE`; `.pet_type_owned` |
| Zero pet insurance policy | derived: `NOT EXISTS (... lob='Pet' ...)` |

---

## 5. "Derived, not stored" facts

These were explicitly asked about in your message but are **better computed at query time** than
stored, because a stored copy can go stale the moment a policy is added/cancelled:

| Fact | How to compute |
|---|---|
| Is single-policy holder | `SELECT COUNT(*) FROM policies WHERE customer_id=? AND policy_status='Active'` → `=1` |
| Has active liability policy on record | `EXISTS(... lob='Personal Liability' AND policy_status='Active')` |
| Has contents insurance | `EXISTS(... lob='Home Contents' AND policy_status='Active')` |
| Has pet insurance | `EXISTS(... lob='Pet' AND policy_status='Active')` |
| Penalty points (BR-05) | `claims_history.demerit_points` — same concept, already exists, don't duplicate |

---

## 6. Full new-table / new-column inventory

### New tables
- `motor_policy_details` (1:1 with `policies` where `lob='Motor'`)
- `home_policy_details` (1:1 with `policies` where `lob` is a Home variant)
- `pet_policy_details` (1:1 with `policies` where `lob='Pet'`)
- `customer_profile_facts` (1:1 with `customers`)
- `customer_compliance_flags` (1:1 with `customers`)
- `rule_evaluation_log` (audit trail, many rows per customer/call)

### New columns on existing tables
- `policies`: `coverage_tier`, `vehicle_market_value_eur`, `vehicle_age_years`, `policy_status`
- `claims_history`: `at_fault_claims_12mo`, `at_fault_claims_24mo`, `at_fault_claims_36mo`, `minor_claims_36mo`

See `new_schema.sql` for exact DDL, `CHECK` constraints enumerating every allowed value, and sample
rows that exercise every rule above (both the "qualifies" and "disqualifies" path where the doc
specifies one).
