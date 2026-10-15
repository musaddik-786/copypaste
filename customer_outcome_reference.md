# Customer → Rule → Expected Outcome Reference

Use this when testing to know what result each customer should produce.

---

## Gatekeeper / Suppression customers (T001–T011)

| Customer | Rule | Expected Outcome | Reason |
|---|---|---|---|
| T001 | BR-01 / GK-01 | SUPPRESSED | Consent = REVOKED |
| T002 | BR-01 / GK-01 | SUPPRESSED | Consent = UNSPECIFIED |
| T003 | BR-02 / GK-02 | SUPPRESSED | Payment = ARREARS |
| T004 | BR-02 / GK-02 | SUPPRESSED | Payment = DD_RETURNED |
| T005 | BR-03 / GK-03 | SUPPRESSED | Open complaint within 180 days |
| T006 | BR-03 / GK-04 | SUPPRESSED | Disputed claim within 180 days |
| T007 | BR-04 | COOLDOWN_ACTIVE on CAR_NCD_PROTECTION | Product declined 30 days ago (cooldown = 6 months) |
| T008 | BR-05 / EL-05 | DISQUALIFIED_RISK on motor upgrades | 2 at-fault claims in 24 months |
| T009 | BR-05 / EL-05 | DISQUALIFIED_RISK | Demerit points = 5 |
| T010 | BR-05 / GK-04 | SUPPRESSED | Open litigation claim (property) |
| T011 | BR-06 / EL-04 | TARGET_MARKET_MISMATCH on HOME_BUILDING | Customer is TENANT |

---

## Baseline customer

| Customer | Expected Outcome | Reason |
|---|---|---|
| T012 | RECOMMENDATIONS_AVAILABLE | All gatekeepers pass, clean car customer |

---

## UP-CAR-01 — NCD Protection rider (T013–T016)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T013 | ELIGIBLE | Bonus tier = 10, clean record |
| T014 | DISQUALIFIED_RISK | Bonus tier = 6 (below threshold of 8) |
| T015 | DISQUALIFIED_RISK | 1 at-fault claim in 36 months |
| T016 | ALREADY_COVERED | NCD rider already attached to policy |

---

## UP-CAR-02 — Comprehensive upgrade (T017–T020)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T017 | ELIGIBLE | Clean record, good vehicle value |
| T018 | DISQUALIFIED_RISK | Vehicle market value = €5,000 (below €8,000 threshold) |
| T019 | DISQUALIFIED_RISK | Vehicle age > 8 years |
| T020 | DISQUALIFIED_RISK | 1 at-fault claim in 12 months |

---

## UP-CAR-03 — Roadside Assistance (T021–T024)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T021 | ELIGIBLE | Annual km = 15,000 (above 12,000 threshold) |
| T022 | DISQUALIFIED_RISK | Annual km = 8,000 (below 12,000 threshold) |
| T023 | DISQUALIFIED_RISK | Household vehicle count = 2 (max is 1) |
| T024 | ALREADY_COVERED | Roadside rider already attached |

---

## UP-HOM-01 — Flood Cover (T025–T028)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T025 | ELIGIBLE | ZUeRS zone = 2, backwater valve certified |
| T026 | REFERRAL_REQUIRED | ZUeRS zone = 4 (needs underwriting referral) |
| T027 | DISQUALIFIED_RISK | Open water damage claim in last 24 months |
| T028 | ALREADY_COVERED | Flood cover rider already attached |

---

## UP-HOM-02 — Valuables Extension (T029–T030)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T029 | ELIGIBLE | Floor area = 150 sqm (above 120 sqm threshold) |
| T030 | DISQUALIFIED_RISK | Floor area = 100 sqm (below 120 sqm threshold) |

> Note: UP-HOM-02 in our seed maps to UP-HOM-05 in the rule catalog which is currently DRAFT — so in the actual engine both T029 and T030 will get RULE_INACTIVE until the DRAFT status is lifted.

---

## UP-PET-01 — Comprehensive Vet upgrade (T031–T033)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T031 | ELIGIBLE | Pet age = 7, 0 vet claims in 24 months |
| T032 | DISQUALIFIED_RISK | Pet age = 13 (above max age of 7 years) |
| T033 | DISQUALIFIED_RISK | 2 minor vet claims in 24 months (above limit of 1) |

---

## CS-CAR-01 — Car cross-sell (T034–T037)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T034 | ELIGIBLE | Single policy, TENANT, no liability cover |
| T035 | NOT_APPLICABLE | Has 2 active policies (not single policy) |
| T036 | NOT_APPLICABLE | OWNER_OCCUPIER (not TENANT) |
| T037 | ALREADY_COVERED | Already has a LIABILITY policy |

> Note: CS-CAR-01 trigger in the rule catalog was changed from tenant+single policy to declared external vehicle. So T034–T037 may give different results against the actual engine depending on whether these customers have an external vehicle declared.

---

## CS-CAR-02 — Personal Accident / high mileage (T038–T041)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T038 | ELIGIBLE | Annual km = 16,000, primary earner, no disability cover |
| T039 | DISQUALIFIED_RISK | Annual km = 12,000 (below 15,000 threshold) |
| T040 | DISQUALIFIED_RISK | primary_earner = false |
| T041 | ALREADY_COVERED | PERSONAL_DISABILITY in active external covers |

---

## CS-HOM-01 — Home Contents cross-sell (T042–T045)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T042 | ELIGIBLE | OWNER_OCCUPIER, DETACHED, floor = 160 sqm, no contents policy |
| T043 | NOT_APPLICABLE | TENANT |
| T044 | DISQUALIFIED_RISK | Floor area = 120 sqm (below 140 sqm threshold) |
| T045 | ALREADY_COVERED | Already has HOME_CONTENTS policy |

---

## CS-PET-01 — Dog owner liability cross-sell (T046–T049)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T046 | ELIGIBLE | Claim-free 4 years, external policy = TPL, no car policy |
| T047 | DISQUALIFIED_RISK | Has a claim within last 3 years |
| T048 | NOT_APPLICABLE | No external motor policy declared |
| T049 | NOT_APPLICABLE | External policy = FULL (not TPL) |

---

## CS-LIA-01 — Personal Liability cross-sell (T050–T052)

| Customer | Expected Outcome | Reason |
|---|---|---|
| T050 | ELIGIBLE | Dog owner, no pet health policy |
| T051 | NOT_APPLICABLE | No dog or horse declared |
| T052 | ALREADY_COVERED | Already has PET_HEALTH policy |

---

## Quick summary by outcome type

| Outcome | Customers |
|---|---|
| SUPPRESSED | T001, T002, T003, T004, T005, T006, T010 |
| COOLDOWN_ACTIVE | T007 |
| TARGET_MARKET_MISMATCH | T011 |
| RECOMMENDATIONS_AVAILABLE (baseline) | T012 |
| ELIGIBLE | T013, T017, T021, T025, T029, T031, T034, T038, T042, T046, T050 |
| ALREADY_COVERED | T016, T024, T028, T037, T041, T045, T052 |
| DISQUALIFIED_RISK | T008, T009, T014, T015, T018, T019, T020, T022, T023, T027, T030, T032, T033, T039, T040, T044, T047 |
| NOT_APPLICABLE | T035, T036, T043, T048, T049, T051 |
| REFERRAL_REQUIRED | T026 |
| RULE_INACTIVE | T029, T030 (UP-HOM-05 is DRAFT in catalog) |
