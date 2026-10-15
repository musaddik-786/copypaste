# SRA Rule Engine — Notes

---

## What this whole system does in one sentence

When a customer's car/home/pet insurance is up for renewal, this engine looks at their profile and decides: **"Should we recommend them an extra product, and if yes — which one?"**

---

## The 4 stages, explained simply

**Stage 1 — Is it even the right time?**

Before doing anything, it checks: has a renewal quote been generated? Is the letter not sent yet? Is the due date still upcoming? If any of these fail, it stops immediately and says `NOT_TRIGGERED` — meaning "don't bother this customer right now."

**Stage 2 — Is the customer in a good state to receive a recommendation?**

These are called gatekeepers. It checks things like:
- Did the customer give consent to receive advisory calls?
- Are they up to date with payments?
- Do they have an open complaint against us?
- Is there an active claim being disputed?
- Are they flagged as a vulnerable customer?

If any of these are true → the whole case is **SUPPRESSED**. We don't recommend anything. And importantly, even if 3 gatekeepers fire, all 6 are still checked — so the audit log is complete.

**Stage 3 — Go through every possible product and check if it makes sense**

For each product (NCD protection, roadside, personal liability, home contents etc.) it runs through a checklist in order:

1. Is this rule even active? (UP-HOM-05 is still DRAFT so it never fires)
2. Does this rule apply to this customer's policy type?
3. Does the customer already own this product? → no point recommending it
4. Is it already included in their existing cover for free?
5. Did they say no to this product recently? (cooldown — riders: 6 months, new policies: 12 months)
6. Do we have all the facts we need? If mileage is unverified, any mileage-based rule fails
7. Is the customer too high risk for this product? (e.g. 2 at-fault claims in 2 years blocks motor upgrades)
8. Does the customer actually qualify for this product?
9. Is this product right for their situation? (e.g. don't recommend building insurance to a tenant)
10. Do we have a verified price from the system? If not, we can't show it

If it passes all 10 → **ELIGIBLE**. Otherwise it gets a specific reason like `COOLDOWN_ACTIVE`, `ALREADY_COVERED`, `DATA_INTEGRITY_FAIL` etc.

**Stage 4 — Pick the best one to show**

From all the ELIGIBLE products, rank them:
- P1 first (existential gap — e.g. customer has no personal liability cover at all)
- Then P2 (major asset protection)
- Then P3 (enhancements/riders)
- Within same tier, the one saving the customer more money wins

Pick the top 2 — one **PRIMARY** (the main recommendation) and one **ALTERNATIVE**. If two products are in the same exclusion group (e.g. Driver Injury rider and Personal Accident cover overlap), only the higher-ranked one is shown.

---

## What the tests are checking

| Test file | What it checks |
|---|---|
| `test_engine_semantics.py` | Basic building blocks — can it read facts correctly, does null mean missing, does AND/OR logic work |
| `test_contract.py` | 31 fixed scenarios — for each one, does the engine produce exactly the expected result |
| `test_cooldown_boundary.py` | Exactly at the cooldown boundary — declined exactly 6 months ago = eligible again, 6 months minus 1 day = still blocked |
| `test_differential.py` | 400 random customer profiles — the simple reference version and the production engine must always agree |
| `test_pricing.py` | Bundle discounts, rounding, what happens if price is missing |

---

## Summary

The engine is a pure function — you give it a customer's facts and the rule catalog, it gives back a decision. All 136 tests pass. The test strategy has four layers: unit tests for the building blocks, 31 fixed golden scenarios covering every BRD acceptance criteria, a boundary test for cooldown off-by-one, and 400 random property-based tests. The engine itself has no database connection — a separate Fact Builder component (not yet built) would pull data from the PAS database and feed it in.

---

## Test examples from the actual test files

### Example 1 — `test_contract.py` (BAC-06)

Golden test for "open complaint → suppressed".

```python
ctx["conduct"]["open_complaint"] = True

result = evaluate(ctx, catalog, as_of)

assert result.status == "SUPPRESSED"
assert "GK-03:GRIEVANCE_ACTIVE" in result.suppression_reasons
```

What happens inside the engine:

1. Window check — David has a quote, letter not dispatched, due date in future → passes
2. GK-01 — consent is GRANTED → passes
3. GK-02 — payment is CURRENT → passes
4. GK-03 — checks `conduct.open_complaint` → it's `True` → fires, adds `GK-03:GRIEVANCE_ACTIVE` to reasons
5. GK-04, GK-05, GK-06 — still checked (for audit), all pass
6. Engine sees reasons list is not empty → returns `SUPPRESSED`
7. Never even reaches the opportunity rules

---

### Example 2 — `test_contract.py` (X-02)

"Null consent → fail closed" test.

```python
ctx["consent"]["advisory_renewal"] = None

result = evaluate(ctx, catalog, as_of)

assert result.status == "SUPPRESSED"
assert "GK-01:DATA_INTEGRITY" in result.suppression_reasons
```

What happens inside the engine:

1. Window check → passes
2. GK-01 — before evaluating the condition, engine calls `_bad_facts()` which checks if `consent.advisory_renewal` is present and not null → it's `None` → counts as MISSING
3. Because a required fact is missing, it doesn't even try to evaluate the rule condition
4. Immediately returns `GK-01:DATA_INTEGRITY` suppression

The point: the engine never guesses. If a fact is null or missing, it suppresses rather than accidentally recommending something.

---

### Example 3 — `test_contract.py` (BAC-04)

"Roadside declined 4 months ago → cooldown active" test.

```python
ctx["history"]["declines"] = [
    {"product_code": "CAR_ROADSIDE", "declined_at": "2026-06-13", "source": "CUSTOMER"}
]

result = evaluate(ctx, catalog, as_of)  # as_of = 2026-10-13

assert result.outcomes["UP-CAR-05"] == "COOLDOWN_ACTIVE"
```

What happens inside the engine for rule UP-CAR-05:

1. Window → passes. Gatekeepers → all pass. Reaches opportunity stage.
2. For rule UP-CAR-05 (Roadside):
   - Status ACTIVE → continue
   - LOB is CAR, policy LOB is CAR → continue
   - `CAR_ROADSIDE` not in active products → continue
   - Not in embedded covers → continue
   - Cooldown check — finds `CAR_ROADSIDE` declined on `2026-06-13`. Months between `2026-06-13` and `2026-10-13` = 4 months. Roadside is a RIDER class, cooldown = 6 months. 4 < 6 → **COOLDOWN_ACTIVE**, stops here
3. Other rules continue their own checks independently

---

### Example 4 — `test_cooldown_boundary.py`

Checks the exact boundary — off by one day.

```python
# declined exactly 6 months ago → ELIGIBLE again
declined_at = months_back(as_of, 6) + timedelta(days=0)
# result: ELIGIBLE

# declined 6 months ago minus 1 day → still in cooldown
declined_at = months_back(as_of, 6) + timedelta(days=1)
# result: COOLDOWN_ACTIVE
```

- `months_between("2026-04-13", "2026-10-13")` = exactly 6 → 6 < 6 is **False** → ELIGIBLE
- `months_between("2026-04-14", "2026-10-13")` = 5 months → 5 < 6 is **True** → COOLDOWN_ACTIVE

This test exists because off-by-one errors here are a real compliance risk — keeping a customer in cooldown one day too long is a complaint waiting to happen.

---

### Example 5 — `test_differential.py`

This one is different — it doesn't have fixed inputs.

```python
@given(ctx=contexts(), shift=st.integers(-400, 400))
def test_production_matches_reference(ctx, shift):
    as_of = AS_OF + timedelta(days=shift)
    expected = reference_evaluator.evaluate(ctx, catalog, as_of)
    actual = production_engine.evaluate(ctx, catalog, as_of)
    assert actual == expected
```

Hypothesis generates a random customer profile — random consent status, random claims, random portfolio, random date — runs it through both the simple reference version and the real production engine, and checks they give identical results. It does this 400 times.

The 31 golden tests only cover cases the developer thought of. The 400 random tests catch edge cases nobody thought of — like what happens when someone has 3 declines for the same product, or the date falls exactly on a month boundary, or all facts are null at once.

---

## Does the codebase cover all rules from the original document?

### Gatekeepers

| Original doc | Catalog | Status |
|---|---|---|
| BR-01 Consent | GK-01 | ✅ Covered |
| BR-02 Payment | GK-02 | ✅ Covered |
| BR-03 Open complaint | GK-03 | ✅ Covered |
| BR-04 Disputed claim | GK-04 | ✅ Covered |
| BR-05 At-fault claims | GK-04 + EL-05 | ✅ Covered (split into two — full suppression + per-rule risk gate) |
| *(not in doc)* | GK-05 Open claim in settlement | ➕ New — architect added |
| *(not in doc)* | GK-06 Vulnerability hold | ➕ New — architect added, needs BA sign-off (D-10) |

### Upsell rules

| Original doc | Catalog | Status |
|---|---|---|
| UP-CAR-01 NCD Protection | UP-CAR-04 | ✅ Covered (ID changed) |
| UP-CAR-02 Comprehensive upgrade | UP-CAR-01 + UP-CAR-02 | ✅ Covered — split into two tiers (TPL→Full, TPL→Partial) |
| UP-CAR-03 Roadside | UP-CAR-05 | ✅ Covered (ID changed, km threshold differs — doc says 15,000, catalog uses 12,000, open decision D-07) |
| *(not in doc)* | UP-CAR-03 Smart→Comfort tier | ➕ New |
| *(not in doc)* | UP-CAR-06 Driver Personal Injury | ➕ New |
| UP-HOM-01 Flood | UP-HOM-01 | ✅ Covered |
| UP-HOM-02 Valuables extension | UP-HOM-05 | ⚠️ Covered but DRAFT — blocked because floor area alone is not IDD-compliant (D-12) |
| *(not in doc)* | UP-HOM-02 Building tier | ➕ New |
| *(not in doc)* | UP-HOM-03 Nat-Haz contents | ➕ New |
| *(not in doc)* | UP-HOM-04 Bicycle/E-Bike | ➕ New |
| UP-PET-01 Surgery→Comprehensive | UP-PET-01 | ✅ Covered |

### Cross-sell rules

| Original doc | Catalog | Status |
|---|---|---|
| CS-CAR-01 Car cross-sell (tenant) | CS-CAR-01 | ⚠️ Covered but trigger changed — doc said tenant+single policy, catalog triggers on declared external vehicle |
| CS-CAR-02 Personal Accident (high mileage) | CS-ACC-01 | ✅ Covered (ID changed) |
| CS-PET-01 Dog owner liability | CS-PET-01 | ✅ Covered |
| CS-LIA-01 Personal Liability | CS-LIA-01 | ✅ Covered |
| *(not in doc)* | CS-PET-02 Horse owner liability | ➕ New |
| *(not in doc)* | CS-PET-03 Pet Health Surgery | ➕ New |
| *(not in doc)* | CS-HOM-01 Home Contents | ➕ New |
| *(not in doc)* | CS-HOM-02 Residential Building | ➕ New |

### Things to flag

1. **UP-HOM-05 (Valuables)** is in the catalog but permanently DRAFT — it won't fire until a compliance issue is resolved
2. **CS-CAR-01 trigger changed** — the original doc described it differently, needs BA confirmation that the new trigger (external vehicle declaration) is the correct one
3. **GK-06 (Vulnerability hold) and GK-05 (claim in settlement)** are architect additions not in the original doc — need explicit BA sign-off before go-live
