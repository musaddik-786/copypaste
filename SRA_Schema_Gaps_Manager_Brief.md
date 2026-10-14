# SRA Schema Gap Analysis — Manager Call Brief

**Document:** `001_sra_schema.sql` Review  
**Prepared by:** Schema Review Team  
**Date:** 2026-10-14  
**Purpose:** Pre-call brief identifying gaps between the current schema and the rule requirements in `Smart_Renewal_Advisor_Rules 1.docx`

---

## Executive Summary

The schema architecture is solid — the multi-schema separation, immutable snapshots, versioned rule engine with four-eyes approval, hash-chained audit ledger, and narrative validation pipeline are exactly right for a regulated product.

**The gaps identified are all data model gaps, not architecture gaps.** They are small fixes on top of a good foundation — not a redesign. However, two of the six gaps directly cause underwriting risk or regulatory mis-selling exposure and must be resolved before go-live.

---

## Gap Summary Table

| # | Gap | Rule(s) Affected | Severity | Fix Size |
|---|---|---|---|---|
| 1 | No demerit / penalty points column | BR-05 | 🔴 **High** — gatekeeper partially broken | 1 column on `src.insured_vehicle` |
| 2 | No disability / accident cover flag | CS-CAR-02 | 🔴 **High** — Consumer Duty mis-sell risk | 1 column on `src.customer` OR 1 declared fact |
| 3 | External motor policy tier is untyped JSONB | CS-PET-01 | 🟡 **Medium** — rule fires unreliably | Add CHECK or trigger on `customer_declared_fact` |
| 4 | Claim-free years definition is ambiguous | CS-PET-01 | 🟡 **Medium** — needs BA clarification | Clarify rule + Fact Builder spec |
| 5 | Litigation claim count not in Fact Builder spec | BR-05 (property) | 🟢 **Low** — structurally fine, needs Fact Builder inclusion | Fact Builder spec update only |
| 6 | ZUeRS zone integer vs string alignment | UP-HOM-01 | 🟢 **Low** — silent failure risk | Fact Builder spec + rule parameter type check |

---

## Detailed Gap Breakdown

---

### Gap 1 — BR-05 Cannot Fully Evaluate

**Severity:** 🔴 High — Gatekeeper partially broken

#### The Rule Says

> `At_Fault_Claims_24Mo >= 2` **OR** `Penalty_Points >= 4` → disqualify from comprehensive upgrades.

#### What the Schema Has

`src.insured_vehicle` has a `bonus_tier` column (SF-Klasse — the no-claims discount tier).

This is **not** the same as penalty or demerit points:

| | Bonus Tier (SF-Klasse) | Penalty / Demerit Points |
|---|---|---|
| **What it measures** | Accumulated claim-free driving years | Traffic offences (speeding, DUI, red lights) |
| **Who issues it** | The insurer | Traffic authority |
| **Direction** | Goes UP with clean years | Accumulates with violations |
| **Can they diverge?** | Yes — a driver can have a perfect bonus tier AND 5 demerit points simultaneously |

#### What the Schema Is Missing

There is no `demerit_points` or `penalty_points` column anywhere:
- Not in `src.insured_vehicle`
- Not in `src.customer`
- Not in `src.customer_declared_fact`

#### Consequence If Not Fixed

BR-05 can only check **half** of its condition. A driver with `At_Fault_Claims_24Mo = 0` but `Penalty_Points = 5` passes through the gatekeeper and receives a recommendation they should be blocked from — an underwriting risk and a potential conduct issue.

#### Fix Needed

```sql
ALTER TABLE src.insured_vehicle
    ADD COLUMN demerit_points integer NOT NULL DEFAULT 0;
```

---

### Gap 2 — CS-CAR-02 Cannot Fully Evaluate

**Severity:** 🔴 High — Consumer Duty mis-selling risk

#### The Rule Says

> CS-CAR-02 qualification: Commuter driving 15,000+ km/year; primary household wage earner; **no personal disability cover**.

#### What the Schema Has

| Criterion | Column | Status |
|---|---|---|
| Commuter mileage ≥ 15,000 km/year | `src.insured_vehicle.annual_km` | ✅ Covered |
| Primary household wage earner | `src.customer.primary_earner` | ✅ Covered |
| No personal disability cover | — | ❌ Missing |

#### What the Schema Is Missing

There is no column or declared fact anywhere that records whether a customer already holds a personal disability or income protection policy — either with this insurer or externally.

The cross-sell should **only fire when there is a gap**. Recommending Personal Accident Insurance to someone who already has disability cover elsewhere is pitching something they do not need — a direct Consumer Duty / TCF (Treating Customers Fairly) violation.

#### Consequence If Not Fixed

CS-CAR-02 fires for **all** high-mileage primary earners regardless of whether they already have disability cover. Personal Accident Insurance gets recommended to customers who already hold it with another insurer — a regulatory mis-selling risk.

#### Fix Needed

**Option A — New column (simplest):**
```sql
ALTER TABLE src.customer
    ADD COLUMN has_disability_or_accident_cover boolean NOT NULL DEFAULT false;
```

**Option B — Declared fact (preferred, consistent with existing pattern):**
Add a `src.customer_declared_fact` row with:
```
fact_key  = 'disability_cover_held'
value     = true | false
source    = 'APPLICATION' | 'CSR_CALL' | 'PORTAL'
verified  = true | false
```
This is consistent with how `dog_owner` and `external_vehicle` are already handled in the schema.

---

### Gap 3 — CS-PET-01 External Motor Policy Tier Is Untyped

**Severity:** 🟡 Medium — Rule fires unreliably

#### The Rule Says

> CS-PET-01 qualification: Operates a family car insured externally **under basic cover**.

#### What the Schema Has

`src.customer_declared_fact` with `fact_key = 'external_vehicle'` and a JSONB `value` column. The tier (Basic vs Comprehensive) would be embedded inside that JSONB blob.

#### What the Schema Is Missing

There is no enforced structure for what that JSONB must contain. Nothing prevents a CSR entering any of these inconsistent values:

```json
{"held": true}                         -- tier missing entirely
{"tier": "basic"}                      -- lowercase, won't match engine expectation
{"tier": "Basic"}                      -- titlecase
{"coverage": "TPL"}                    -- different key name
```

#### Consequence If Not Fixed

The rule engine cannot reliably compare tier values — it is pattern-matching against unvalidated free-form JSON. CS-PET-01 will either:
- Always fire (if the engine skips the tier check due to missing key), or
- Silently fail (if the JSON key name differs from what the engine expects)

Both outcomes are wrong.

#### Fix Needed

**Option A — Add a typed column:**
```sql
ALTER TABLE src.customer
    ADD COLUMN external_motor_policy_tier text
    CHECK (external_motor_policy_tier IN ('NONE', 'TPL', 'PARTIAL', 'FULL'));
```

**Option B (preferred) — Document and enforce a strict JSON schema:**

Define the canonical structure for `fact_key = 'external_vehicle'`:
```json
{"held": true, "tier": "TPL" | "PARTIAL" | "FULL"}
```
Then add a CHECK constraint or trigger that validates the JSONB against this schema whenever `fact_key = 'external_vehicle'` is inserted or updated.

---

### Gap 4 — CS-PET-01 Claim-Free Years Definition Is Ambiguous

**Severity:** 🟡 Medium — Requires BA clarification before implementation

#### The Rule Says

> CS-PET-01 qualification: Loyal policyholder — **3 or more claim-free years**.

#### What the Schema Has

`src.claim` with `loss_date` and `policy_id`. You can compute "years since last claim" from the most recent `loss_date`. However, `src.policy.inception_date` tells you when the specific pet policy started — not the customer's total relationship tenure across all lines.

#### The Ambiguity

Consider this scenario:

| Policy | Tenure | Last Claim |
|---|---|---|
| Pet policy | 1 year | None |
| Car policy | 5 years | None |

- If "claim-free years" means **pet policy only** → customer has 1 year → does NOT qualify
- If "claim-free years" means **any policy across all lines** → customer has 5 years → DOES qualify

The schema can compute either interpretation. But the rule catalog (`rules.rule.condition_jsonlogic`) must specify exactly which interpretation to use — otherwise two developers will implement it differently.

#### Action Required

Clarify with the BA / rule author: does "3 or more claim-free years" mean:
1. 3 claim-free years on the **pet policy specifically**, OR
2. 3 years as a customer with **no claims on any active policy**?

Update `rules.rule.condition_jsonlogic` and `rules.rule.required_facts` to explicitly reflect the agreed interpretation before the engine is built.

---

### Gap 5 — BR-05 Property Litigation Check Not in Fact Builder Spec

**Severity:** 🟢 Low — Structurally fine, Fact Builder inclusion needed

#### The Rule Says

> BR-05 (property side): `Open_Litigation_Claims > 0` → Underwriting disqualification.

#### What the Schema Has

`src.claim.status` can be `'LITIGATION'`, so the query:
```sql
WHERE status = 'LITIGATION' AND policy_id IN (SELECT policy_id FROM src.policy WHERE customer_id = ?)
```
returns open litigation claims for a customer. This works structurally.

#### The Subtlety

`src.claim` links to `policy_id`, not directly to `customer_id`. The gatekeeper query requires a join:

```
src.claim → src.policy → src.customer
```

This is fine architecturally. However, the `rules.rule.required_facts` array and the **Fact Builder** need to explicitly include `open_litigation_claims_count` as a derived fact in the `decision_context` JSON snapshot.

If it is not included in the Fact Builder spec, the rule engine will not have this fact available at evaluation time without going back to source — breaking the immutability guarantee of the snapshot.

#### Action Required

Confirm the Fact Builder spec includes:
```json
"open_litigation_claims_count": <int>
```
as a derived fact computed from `src.claim WHERE status = 'LITIGATION'` scoped to the customer's active policies.

---

### Gap 6 — UP-HOM-01 ZUeRS Zone Naming Inconsistency

**Severity:** 🟢 Low — Silent failure risk

#### The Rule Document Says

> Property Postcode Classification: `Environmental_Zone == 'Zone 2'` or `'Zone 3'` (moderate to elevated surface water risk).

#### What the Schema Has

```sql
src.insured_property.zuers_zone  int  CHECK (zuers_zone BETWEEN 1 AND 4)
```

This is correctly modelled as an **integer** using the GDV ZUeRS industry standard. ✅

#### The Gap

The Word document uses string labels like `"Zone 2"` and `"Zone 3"`. The schema stores integers `2` and `3`.

If the Fact Builder maps `zuers_zone` to `decision_context` as the string `"Zone 2"` instead of the integer `2`, the JsonLogic condition:
```json
{"in": [{"var": "property.zuers_zone"}, [2, 3]]}
```
will silently fail — `"Zone 2" IN [2, 3]` evaluates to false.

#### Action Required

1. Confirm in the Fact Builder spec that `zuers_zone` is passed to `decision_context` as an **integer**, not a string.
2. Confirm the rule parameter in `rules.parameter` for the flood zone threshold is defined with `value_type = 'int'`.
3. Update the Word document's next revision to use integer notation (`Zone 2` → `zuers_zone = 2`) to eliminate future ambiguity.

---

## Closing Note for the Call

All six gaps are fixable without touching the core architecture. The two high-severity gaps (Gap 1 and Gap 2) each require adding a single column. The two medium gaps (Gap 3 and Gap 4) require either a schema constraint or a BA clarification. The two low gaps (Gap 5 and Gap 6) are purely specification alignment issues with no schema change needed.

**Recommended action:** Prioritize Gap 1 and Gap 2 for the next sprint. They are the only gaps that create regulatory exposure if left open at go-live.
