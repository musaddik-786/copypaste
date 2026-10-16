# Rules Audit: Document vs Codebase
# Smart Renewal Advisor — Complete Rule Coverage Analysis

---

## Gatekeeper Rules (BR-01 to BR-06)

| Rule | Document Condition | In Codebase? | How It Is Checked | Gap? |
|---|---|---|---|---|
| BR-01 | `Advisory_Marketing_Consent == REVOKED or UNSPECIFIED` | ✅ GK-01 | `consent.advisory_renewal != "GRANTED"` | None |
| BR-02 | `Policy_Payment_Status != CURRENT` | ✅ GK-02 | `account.payment_status != "CURRENT"` | None |
| BR-03 | `Open_Complaint_Flag == TRUE` within 180 days | ✅ GK-03 | `conduct.open_complaint == true` | None |
| BR-03 | `Disputed_Claim_Flag == TRUE` within 180 days | ✅ GK-04 | `conduct.disputed_claim_in_lookback == true` | None |
| BR-04 | Declined same product within **180 days** | ⚠️ EL-03 | RIDER cooldown = 6 months (180 days ✅). COMPANION cooldown = **12 months** — document says 180 days for all products, catalog doubled it for companion products | Cooldown for companions is 2x what document says — needs BA confirmation |
| BR-05 | `At_Fault_Claims_24Mo >= 2` | ✅ EL-05 | `claims.at_fault_24m > 1` (equivalent to >= 2) | None |
| BR-05 | `Penalty_Points >= 4` | ❌ **MISSING** | Not anywhere in the codebase or rule catalog | **Penalty points check is entirely absent** |
| BR-05 | `Open_Litigation_Claims > 0` (property) | ⚠️ GK-04 | Handled as full case suppression, not per-rule disqualification | Covered but applied more broadly than document requires |
| BR-06 | Target market mismatch (e.g. Building Insurance to tenant) | ✅ EL-04 | JsonLogic `target_market` condition per product in catalog | None |

---

## Upsell Rules

| Rule | Document Condition | In Codebase? | Gap? |
|---|---|---|---|
| UP-CAR-01 NCD — Full Comprehensive coverage required | ✅ | `policy.coverage_level == "FULL"` | None |
| UP-CAR-01 NCD — `Bonus_Tier >= 8` | ✅ | `motor.bonus_tier >= 8` | None |
| UP-CAR-01 NCD — 0 at-fault claims in last 36 months | ✅ | `claims.at_fault_36m <= 0` | None |
| UP-CAR-01 NCD — NCD rider not already attached | ✅ | EL-01 already-covered check | None |
| UP-CAR-02 Comprehensive — Vehicle market value >= €8,000 | ✅ | `vehicle.market_value >= 8000` | None |
| UP-CAR-02 Comprehensive — Vehicle age <= 8 years | ✅ | `vehicle.age_years <= 8` | None |
| UP-CAR-02 Comprehensive — 0 claims in last 12m, max 1 in last 36m | ✅ | Both conditions in `when` clause | None |
| UP-CAR-03 Roadside — Annual km >= **12,000** | ✅ | `vehicle.annual_km >= 12000` | None — document AND catalog both say 12,000 |
| UP-CAR-03 Roadside — Household vehicle count = 1 | ✅ | `customer.household_vehicle_count <= 1` | None |
| UP-HOM-01 Flood — Property in Zone 2 or 3 | ✅ | `property.zuers_zone <= 3` | None |
| UP-HOM-01 Flood — Backwater valve certified | ✅ | `property.backwater_valve_certified == true` | None |
| UP-HOM-01 Flood — Zone 4 → referral to underwriting | ✅ | `referral_when: zuers_zone > 3` | None |
| UP-HOM-01 Flood — No open water damage claim in 24m | ✅ | `claims.open_water_claim_24m == false` | None |
| UP-HOM-02 Valuables — Active Contents policy + floor area >= 120 sqm | ⚠️ | Exists in catalog as UP-HOM-05 but status = **DRAFT** — never fires in production | Rule coded but blocked pending IDD compliance sign-off (open decision D-12) |
| UP-PET-01 Vet — Pet age <= 7 years | ✅ | `pet.age_years <= 7` | None |
| UP-PET-01 Vet — Max 1 minor claim in last 24 months | ✅ | `claims.pet_claims_24m <= 1` | None |

---

## Cross-Sell Rules

> **Note:** The document names cross-sell rules by the current policy held (e.g. CS-CAR-01 = car holder getting liability). The catalog renames them by the product being recommended (e.g. CS-LIA-01 = personal liability rule). The table below maps document rule → catalog rule → what changed.

| Document Rule | Document Trigger | Recommends | Catalog Rule | Catalog Trigger | Gap? |
|---|---|---|---|---|---|
| CS-CAR-01 | Car holder + **renter** + no liability policy | Personal Liability Insurance | CS-LIA-01 | Any `household_type` (SINGLE / COUPLE / FAMILY / SINGLE_PARENT) — not restricted to renters | ⚠️ Document: renter with car only. Catalog: any household type. Trigger broadened — needs BA confirmation |
| CS-CAR-02 | Car holder + annual_km >= 15,000 + primary earner + no disability cover | Personal Accident Insurance | CS-ACC-01 | `annual_km >= 15000` AND `primary_earner == true` AND holds CAR_POLICY | ✅ Same conditions, different rule ID |
| CS-HOM-01 | Home Building holder + **owner-occupier** + **detached house** + **floor area >= 140 sqm** + no contents policy | Home Contents Insurance | CS-HOM-01 | Any occupancy (OWNER / TENANT / LANDLORD), no floor area threshold on trigger | ⚠️ Document: owner-occupier in detached house 140sqm+. Catalog: offers to tenants too, no sqm requirement. Needs BA confirmation |
| CS-PET-01 | Pet holder + **3+ claim-free years** + family car externally insured under **basic cover** | Car Insurance Full Comprehensive | CS-CAR-01 | `declared_external_vehicle == true` AND `declaration_age_months <= 24` | ⚠️ Concept exists but trigger completely changed. Document: claim-free years + basic external car. Catalog: declaration age only. Needs BA confirmation |
| CS-LIA-01 | Personal Liability holder + **dog or horse declared** | Pet Health & Surgery Insurance | CS-PET-03 | `dog_owner == true` OR `cat_owner == true` — no requirement to hold Personal Liability first | ⚠️ Document: must already hold liability policy. Catalog: pet ownership alone triggers it, and includes cats. Needs BA confirmation |

---

## Summary

### Hard Gap — Rule Not Checked At All

| # | Gap | Impact |
|---|---|---|
| 1 | **BR-05: `Penalty_Points >= 4` not implemented** | A customer with 4+ penalty points but fewer than 2 at-fault claims will incorrectly receive motor upgrade recommendations |

### Soft Gaps — Rule Exists But With Different Threshold or Trigger (Needs BA Confirmation)

| # | Gap | Document Says | Catalog Has |
|---|---|---|---|
| 2 | BR-04 companion cooldown | 180 days for all declined products | 12 months (360 days) for companion products |
| 3 | CS-CAR-01 / CS-LIA-01 Personal Liability trigger | Car holder in rented flat with no liability | Any household type — not restricted to renters |
| 4 | CS-HOM-01 Home Contents trigger | Owner-occupier + detached + 140 sqm+ | Any occupancy, no floor area threshold |
| 5 | CS-PET-01 / CS-CAR-01 Car cross-sell trigger | Pet holder + 3+ claim-free years + basic external car | Declared external vehicle + declaration <= 24 months |
| 6 | CS-LIA-01 / CS-PET-03 Pet Health trigger | Must hold Personal Liability + dog or horse | Dog, cat, or horse owner — no prerequisite policy |

### Blocked Rule (In Catalog But Never Fires)

| # | Rule | Reason |
|---|---|---|
| 7 | UP-HOM-02 Valuables Extension (UP-HOM-05 in catalog) | Status = DRAFT — floor area alone is not IDD Art. 20 compliant. Waiting for compliance sign-off (open decision D-12) |

### Architect Additions Not In Document (Safer Than Document Requires)

| # | Addition | What It Does |
|---|---|---|
| A | GK-05 Open Claim in Settlement | Suppresses recommendations if customer has a claim currently in settlement — document does not mention this |
| B | GK-06 Vulnerability Hold | Suppresses recommendations for flagged vulnerable customers — document does not mention this |

---

## What Is Working Correctly

All of the following are fully implemented and match the document exactly:

- BR-01 Consent check (fail-closed: null = suppressed)
- BR-02 Payment status check
- BR-03 Open complaint and disputed claim checks
- BR-05 At-fault claims risk gate (at_fault_24m >= 2)
- BR-06 Target market / IDD POG per product
- UP-CAR-01 NCD Protection (all 4 conditions)
- UP-CAR-02 Comprehensive upgrade (vehicle value, age, claims)
- UP-CAR-03 Roadside (12,000 km threshold, household vehicle count)
- UP-HOM-01 Flood cover (zone, backwater valve, referral at zone 4, no open water claim)
- UP-PET-01 Vet upgrade (pet age, claim frequency)
- CS-CAR-02 / CS-ACC-01 Personal Accident (km, primary earner)
- 4-stage pipeline: Window → Gatekeepers → Opportunity rules → Ranking
- Priority ranking (P1 before P2 before P3)
- Exclusion groups (e.g. driver injury vs personal accident)
- Max 2 recommendations (1 PRIMARY + 1 ALTERNATIVE)
- Bundle discount (5% companion, 10% for car policy)
- Verified pricing gate (no unverified prices shown)
- Human-in-the-loop (Include / Skip / Defer)
- Hash-chained audit trail
- AI-generated narratives with 9 validators
