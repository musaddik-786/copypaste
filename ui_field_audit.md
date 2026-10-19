# UI Field Audit — Every UI Element vs `renewal_advisor` Schema
# Smart Renewal Advisor — Sarah Jenkins (POL-CAR-771204)

---

## HEADER BAR

| UI Field | Source Table | Column(s) | Status |
|---|---|---|---|
| Policy Number: POL-CAR-771204 | `src.policy` | `policy_id` | ✅ |
| "Car Insurance" badge | `ref.line_of_business` | `name_en` (looked up via `lob_code`) | ✅ |
| Policyholder: Sarah Jenkins | `src.customer` | `full_name` | ✅ |
| DOB: 22 Jul 1988 | `src.customer` | `date_of_birth` | ✅ |
| Quote Created: 13 Oct 2026 | `src.renewal_quote` | `created_at` | ✅ |
| Renewal Date: 20 Nov 2026 | `src.renewal_quote` | `renewal_date` | ✅ |
| Expiring Premium: €490.00 | `src.renewal_quote` | `expiring_premium_gross` | ✅ |
| Renewal Quote: €515.00 | `src.renewal_quote` | `renewal_premium_gross` | ✅ |

---

## CUSTOMER PROFILE

| UI Field | Source Table | Column(s) | Status |
|---|---|---|---|
| Full Name | `src.customer` | `full_name` | ✅ |
| Customer ID | `src.customer` | `customer_id` | ✅ |
| Date of Birth: 22 Jul 1988 | `src.customer` | `date_of_birth` | ✅ |
| Age: 38 years | — | Derived: `EXTRACT(YEAR FROM AGE(date_of_birth))` | ✅ |
| Address: 82 Park Lane | `src.customer` | `street_address` | ✅ |
| City: Hamburg | `src.customer` | `city` | ✅ |
| Occupancy: Tenant | `src.customer` | `occupancy` | ✅ |
| (Rented Apartment) | `src.customer` | `dwelling_type` | ✅ |
| Advisory Consent: Granted | `src.consent` | `status` (purpose = 'ADVISORY_RENEWAL') | ✅ |
| Other Policies: None — single-policy holder | — | Derived: count of `src.policy` rows for customer | ✅ |
| "Good Standing" status badge | — | Derived: `payment_status = CURRENT` + no open complaints | ✅ |

---

## CURRENT COVERAGE

| UI Field | Source Table | Column(s) | Status |
|---|---|---|---|
| Policy Number | `src.policy` | `policy_id` | ✅ |
| Product: Car Insurance | `ref.line_of_business` | `name_en` (via `src.policy.lob_code`) | ✅ |
| Coverage Tier: Comprehensive | `src.policy` | `coverage_level` (FULL → "Comprehensive") | ✅ |
| Coverage Tier: (Comfort) | `src.policy` | `package_tier` | ✅ |
| Insured Asset: 2022 Audi A3 | `src.insured_vehicle` | `build_year` + `make_model` | ✅ |
| Market Value: €24,000 | `src.insured_vehicle` | `market_value` | ✅ |
| Add-Ons Active: Roadside Assistance Rider | `src.policy_module` + `ref.product` | `product_code` joined to `ref.product.name_en` | ✅ |
| INCLUDED BENEFITS (3 items) | `ref.product_benefit_statement` | Pre-loaded ref data — 80 rows already in `renewal_advisor` | ✅ |

---

## RISK & CLAIMS PROFILE

| UI Field | Source Table | Column(s) | Status |
|---|---|---|---|
| Prior 12M Claim: "1 claim" count | `src.claim` | Derived: count where `loss_date >= today - 12 months` | ✅ |
| "Coastal Storm Gale / Fallen Branch" description | `src.claim` | `peril` (stored as descriptive text, not a code) | ✅ |
| **"€1,200 settled" claim amount** | `src.claim` | ❌ **NO `settled_amount` column in schema** | ❌ **GAP** |
| Claim Type: Catastrophe / Coastal Gale (Windstorm Damage) | `src.claim` | `peril` | ✅ |
| Fault Status: ✓ 0 At-Fault | `src.claim` | Derived: count where `at_fault = true` in lookback | ✅ |
| 3-Year Claims: 1 non-fault claim | `src.claim` | Derived: count where `at_fault = false` and within 36 months | ✅ |
| Safe Driver Tier: Bonus Tier 8 | `src.insured_vehicle` | `bonus_tier` | ✅ |
| Safe Driving Record: 8 Years Safe Driving | — | Derived: `bonus_tier` value = years of safe driving | ✅ |
| Annual Mileage: 12,000 km/yr | `src.insured_vehicle` | `annual_km` | ✅ |
| Formal Dispute: None | `src.complaint` | Derived: no rows with `status IN ('OPEN','ESCALATED','OMBUDSMAN')` | ✅ |

---

## Summary

### ✅ Everything Covered (31 of 32 fields)

All fields shown in the UI have a corresponding column or derivation in the `renewal_advisor` schema.
The `ref.*` benefit statements are already pre-loaded (80 rows). Derived fields (Age, Good Standing,
Fault Status, Safe Driving Record, Other Policies, Formal Dispute) are all computable from existing
src columns — no additional storage needed.

### ❌ 1 Real Gap — Claim Amount

| Gap | UI Shows | Schema Has | Impact |
|---|---|---|---|
| Claim settled amount | "€1,200 settled" in Prior 12M Claim | `src.claim` has no `settled_amount` or `claim_amount` column | The amount cannot be displayed from current schema |

**What to check:** Run the query below to see how the manager's 5 demo personas store claim data.
If their `peril` field contains the full text including the amount (e.g. `"Coastal Storm Gale — €1,200"`),
then the amount is embedded in the text. If not, a `settled_amount numeric(12,2)` column needs adding
to `src.claim`.

```bash
python3 - <<'EOF'
from dotenv import dotenv_values
import psycopg
config = dotenv_values('/home/JarvisClaims/Musaddique/Smart Renewal Advisor/.env')
url = config['DATABASE_URL'].split('?')[0]
conn = psycopg.connect(url, sslmode='require')
cur = conn.cursor()
cur.execute("SELECT claim_id, peril, at_fault, severity, status FROM src.claim")
for r in cur.fetchall(): print(r)
conn.close()
EOF
```

---

## Fields Our T001-T052 Seeds Are Missing (Blockers for `renewal_advisor`)

These are columns that exist in `renewal_advisor` but are absent from our seed files,
which will cause INSERT failures:

| Table | Missing Column | Type | Issue |
|---|---|---|---|
| `src.customer` | `preferred_language` | `text NOT NULL` | Seeds don't set it → INSERT fails |
| `src.customer` | `preferred_channel` | `text NOT NULL` | Seeds don't set it → INSERT fails |
| `src.customer` | `vulnerability_hold` | `boolean NOT NULL` | Seeds don't set it → INSERT fails |
| `src.insured_vehicle` | `penalty_points` | `integer NOT NULL` | Seeds use `demerit_points` (wrong name) → INSERT fails |

These columns exist in seeds but NOT in `renewal_advisor` (must be removed):

| Table | Column to Remove | Why |
|---|---|---|
| `src.customer` | `active_external_covers` | Column does not exist in new schema |
| `src.customer` | `external_policies_active` | Column does not exist in new schema |

These facts must move to `src.customer_declared_fact` instead:

| Old Column | Customer(s) | New fact_key | New value |
|---|---|---|---|
| `active_external_covers = ['PERSONAL_DISABILITY']` | CUST-T041 | `active_external_covers` | `{"covers": ["PERSONAL_DISABILITY"]}` |
| `external_policies_active = ['TPL']` | CUST-T046, CUST-T047 | `external_vehicle` | `{"declared": true, "cover": "TPL"}` |
| `external_policies_active = ['FULL']` | CUST-T049 | `external_vehicle` | `{"declared": true, "cover": "FULL"}` |
