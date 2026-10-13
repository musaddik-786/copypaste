# Cross-Sell/Upsell Database Schema Documentation

**Generated:** 2026-10-13 14:08:47

**Database:** `cross_selldb`

**Host:** `jarvis-life-uw.postgres.database.azure.com`

---

## Table of Contents

- [bundle_discounts](#bundle_discounts)
- [call_signals](#call_signals)
- [calls](#calls)
- [claims_history](#claims_history)
- [crosselldb](#crosselldb)
- [customers](#customers)
- [opportunity_decisions](#opportunity_decisions)
- [opportunity_recommendations](#opportunity_recommendations)
- [policies](#policies)
- [recommendation_cooldown](#recommendation_cooldown)
- [rule_matrix](#rule_matrix)
- [rule_matrix_2](#rule_matrix_2)
- [rule_matrix_conditions](#rule_matrix_conditions)
- [transcript_lines](#transcript_lines)

---


## bundle_discounts

**Rows:** 1


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| discount_id | integer | NO | nextval('bundle_discounts_discount_id_seq'::regclass) |
| lob_combo | text | NO | — |
| discount_pct | numeric | NO | — |
| active | boolean | YES | true |
| created_at | timestamp with time zone | YES | now() |

### Data

| discount_id | lob_combo | discount_pct | active | created_at |
|---|---|---|---|---|
| 1 | Motor+Home | 15.00 | True | 2026-10-09 07:30:13.977097+00:00 |



## call_signals

**Rows:** 0


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| signal_row_id | integer | NO | nextval('call_signals_signal_row_id_seq'::regclass) |
| call_id | text | YES | — |
| signals | jsonb | YES | — |
| sentiment | jsonb | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

*No data in this table*



## calls

**Rows:** 3


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| call_id | text | NO | — |
| customer_id | text | YES | — |
| scenario_tag | text | YES | — |
| started_at | timestamp with time zone | YES | now() |
| ended_at | timestamp with time zone | YES | — |
| status | text | YES | 'active'::text |

### Data

| call_id | customer_id | scenario_tag | started_at | ended_at | status |
|---|---|---|---|---|---|
| CALL-1791789042 | CUS-10842 | sample_1 | 2026-10-12 07:11:59.736019+00:00 | NULL | active |
| CALL-1791790469 | CUS-10925 | sample_2 | 2026-10-12 07:35:24.970473+00:00 | NULL | active |
| CALL-1791792856 | CUS-10842 | sample_1 | 2026-10-12 08:15:22.751567+00:00 | NULL | active |



## claims_history

**Rows:** 2


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| claim_id | integer | NO | nextval('claims_history_claim_id_seq'::regclass) |
| customer_id | text | YES | — |
| claims_last_3yrs_count | text | YES | — |
| last_claim_coverage_type | text | YES | — |
| driver_history_summary | text | YES | — |
| demerit_points | integer | YES | — |
| licence_tenure_years | integer | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| claim_id | customer_id | claims_last_3yrs_count | last_claim_coverage_type | driver_history_summary | demerit_points | licence_tenure_years | created_at |
|---|---|---|---|---|---|---|---|
| 1 | CUS-10842 | 1 Motor claim | Comprehensive Essentials | Clean Record (0 demerit points, no suspensions, 16 yrs licenced) | 0 | 16 | 2026-10-09 07:30:13.977097+00:00 |
| 2 | CUS-10925 | 1 (Not-at-fault collision) | Third Party Property Damage | Clean Record (0 demerits, valid QLD open licence, 20 yrs licenced) | 0 | 20 | 2026-10-09 07:30:13.977097+00:00 |



## crosselldb

**Rows:** 0


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|

### Data

*No data in this table*



## customers

**Rows:** 2


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| customer_id | text | NO | — |
| full_name | text | NO | — |
| dob | text | NO | — |
| dob_display | text | YES | — |
| age | integer | YES | — |
| customer_since | text | YES | — |
| location | text | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| customer_id | full_name | dob | dob_display | age | customer_since | location | created_at |
|---|---|---|---|---|---|---|---|
| CUS-10842 | Sarah Williams | 14/03/1988 | 14 March 1988 | 38 | 2019 | Queensland | 2026-10-09 07:30:13.977097+00:00 |
| CUS-10925 | Michael Brown | 22/09/1982 | 22 September 1982 | 42 | 2018 | Queensland | 2026-10-09 07:30:13.977097+00:00 |



## opportunity_decisions

**Rows:** 3


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| decision_id | text | NO | — |
| call_id | text | YES | — |
| customer_id | text | YES | — |
| opportunities_offered | jsonb | YES | — |
| initial_state | text | YES | — |
| result_state | text | YES | — |
| applied_at | timestamp with time zone | YES | now() |

### Data

| decision_id | call_id | customer_id | opportunities_offered | initial_state | result_state | applied_at |
|---|---|---|---|---|---|---|
| DEC-20261012072317-bc8a10 | CALL-1791789042 | CUS-10842 | {
  "outcome_items": [
    "Upgrade to full Comprehensive motor cover to gain agreed value, renta... |  | Comprehensive (Full Tier) | 2026-10-12 07:23:18.802750+00:00 |
| DEC-20261012073848-d55f7d | CALL-1791790469 | CUS-10925 | {
  "outcome_items": [
    "Covers your own vehicle for accidental damage, theft, vandalism, weat... |  | Upgrade to Full Comprehensive Motor Insurance | 2026-10-12 07:38:49.770382+00:00 |
| DEC-20261012081911-7b336a | CALL-1791792856 | CUS-10842 | {
  "outcome_items": [
    "Unlocks agreed value, choice of repairer, rental car after any covere... |  | Upgrade to Comprehensive (Full Tier) | 2026-10-12 08:19:13.581484+00:00 |



## opportunity_recommendations

**Rows:** 20


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| recommendation_id | integer | NO | nextval('opportunity_recommendations_recommendation_id_seq'::regclass) |
| call_id | text | YES | — |
| customer_id | text | YES | — |
| agent_decision | text | YES | — |
| guardrail | text | YES | — |
| opportunities | jsonb | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| recommendation_id | call_id | customer_id | agent_decision | guardrail | opportunities | created_at |
|---|---|---|---|---|---|---|
| 7 | CALL-1791789042 | CUS-10842 | The customer expressed strong interest in additional features such as rental car after an acciden... | Conversation transcript, explicit feature inquiry, product rules catalogue, policy details. | [
  {
    "why": "Customer explicitly asked how to get rental car cover after an accident and to ... | 2026-10-12 07:12:59.483562+00:00 |
| 8 | CALL-1791789042 | CUS-10842 | Customer Sarah Williams is highly interested in extra cover features (rental car, choice of repai... | Decisioning sources: conversation content (feature inquiry), customer policy details, live produc... | [
  {
    "why": "Customer asked explicitly about rental car provision after any accident and sel... | 2026-10-12 07:14:19.178211+00:00 |
| 9 | CALL-1791789042 | CUS-10842 | Sarah inquired specifically about getting rental car cover and choice of repairer, both of which ... | Decisioning draws from the live conversation transcript (direct feature inquiry), customer snapsh... | [
  {
    "why": "Sarah explicitly asked about rental car after an accident and choice of repaire... | 2026-10-12 07:14:46.747188+00:00 |
| 10 | CALL-1791789042 | CUS-10842 | The customer asked about rental car cover and choice of repairer—both not available on their curr... | Decisioning sources: live conversation (explicit feature requests), policy details, product mappi... | [
  {
    "why": "Customer asked specifically about both rental car cover and choice of repairer,... | 2026-10-12 07:22:04.373729+00:00 |
| 11 | CALL-1791789042 | CUS-10842 | The customer asked explicitly about rental car cover and choice of repairer, both of which are on... | Decisioning based on conversation (feature interest), customer snapshot, policy details, and rule... | [
  {
    "why": "Customer clearly indicated wanting both rental car cover and choice of repairer... | 2026-10-12 07:22:39.417779+00:00 |
| 12 | CALL-1791789042 | CUS-10842 | The customer expressed a strong, explicit interest in both rental car cover and choice of repaire... | Decisioning based on explicit feature inquiry and confirmation from transcript, mapped to product... | [
  {
    "why": "Customer explicitly requested rental car and repairer choice coverage (not avai... | 2026-10-12 07:23:14.229516+00:00 |
| 13 | CALL-1791789042 | CUS-10842 | Recommended upgrade to Comprehensive Full Tier with rental car and choice of repairer option as c... | Decision is based on the customer conversation (explicit feature interest in rental car and repai... | [
  {
    "why": "Customer explicitly requested rental car cover and choice of repairer, and is a... | 2026-10-12 07:23:43.930351+00:00 |
| 14 | CALL-1791790469 | CUS-10925 | There are two highly relevant opportunities: (1) Upsell to Comprehensive or Comprehensive Essenti... | Decisioning used live conversation (interest in cover upgrade, mention of owner-occupied home), p... | [
  {
    "why": "Customer explicitly asked for a comparison of comprehensive cover options and e... | 2026-10-12 07:36:07.596234+00:00 |
| 15 | CALL-1791790469 | CUS-10925 | Recommend urgent upsell from Third Party Property Damage to Comprehensive due to recent claims ex... | Decisioning based on conversation signals (feature/cover interest, address and ownership change),... | [
  {
    "why": "You directly requested a move to Comprehensive for greater peace of mind, promp... | 2026-10-12 07:36:46.167152+00:00 |
| 16 | CALL-1791790469 | CUS-10925 | Two highly relevant opportunities: upgrade to comprehensive motor cover (matching customer's requ... | Decisioning based on live transcript signals (feature interest, coverage need, address/home statu... | [
  {
    "why": "Customer directly requested info and confirmed intent to upgrade to full compre... | 2026-10-12 07:37:13.049748+00:00 |
| 17 | CALL-1791790469 | CUS-10925 | The customer expressed clear interest in upgrading from Third Party Property Damage to Comprehens... | Decisioning validated using live conversation (explicit upgrade/homeownership interest), customer... | [
  {
    "why": "Customer requested full comprehensive after last incident and wants broader pro... | 2026-10-12 07:37:53.793911+00:00 |
| 18 | CALL-1791790469 | CUS-10925 | Customer is highly receptive and directly requested both an upgrade from Third Party Property Dam... | Decisioning uses live transcript signals (feature/model interest, owner-occupier status, renewal ... | [
  {
    "why": "Customer explicitly requested an upgrade to full comprehensive, citing peace of... | 2026-10-12 07:38:43.736918+00:00 |
| 19 | CALL-1791790469 | CUS-10925 | Recommend both upgrading motor cover to Full Comprehensive and cross-sell Home & Contents with bu... | Decisioning sources: Conversation signals (expressed interest in upgrade and home insurance, conf... | [
  {
    "why": "Customer directly requested an upgrade after prior claim and expressed desire f... | 2026-10-12 07:39:02.180983+00:00 |
| 20 | CALL-1791790469 | CUS-10925 | The customer explicitly requested an upgrade from Third Party Property Damage to Comprehensive Mo... | Decisioning sources: live conversation (explicit upgrade and home ownership/bundle interest), cus... | [
  {
    "why": "Customer expressed desire for more cover and explicitly requested 'full compreh... | 2026-10-12 07:39:22.848309+00:00 |
| 21 | CALL-1791790469 | CUS-10925 | Michael proactively requested an upgrade to comprehensive motor insurance after a claims experien... | Decisioning sources: live conversation (feature query, owner-occupier disclosure), customer snaps... | [
  {
    "why": "Customer explicitly requested full comprehensive due to increased risk awarenes... | 2026-10-12 07:39:40.324695+00:00 |
| 22 | CALL-1791792856 | CUS-10842 | The customer expressed concern about limited features in her current Comprehensive Essentials pol... | Decisioning used live conversation signals (explicit feature interest in rental car and choice of... | [
  {
    "why": "Customer specifically asked about rental car after any incident and the ability... | 2026-10-12 08:16:19.403271+00:00 |
| 23 | CALL-1791792856 | CUS-10842 | Sarah expressed explicit concern about not having rental car cover after any incident and not bei... | Decisioning sources: live conversation (feature interest signals), customer snapshot (policy/clai... | [
  {
    "why": "Sarah requested info about rental car cover after any incident and ability to c... | 2026-10-12 08:16:48.022958+00:00 |
| 24 | CALL-1791792856 | CUS-10842 | The customer expressed explicit interest in additional features such as agreed value, new car rep... | Decision is based on live conversation signals (explicit feature inquiry), the current product in... | [
  {
    "why": "Customer directly asked about features unique to the full Comprehensive tier an... | 2026-10-12 08:18:43.388324+00:00 |
| 25 | CALL-1791792856 | CUS-10842 | Customer Sarah directly requested an upgrade to Full Comprehensive cover, expressing concern abou... | Decisioning sources: live conversation (feature and concern mentions, renewal timing, explicit re... | [
  {
    "why": "Customer expressed explicit interest in agreed value, new-for-old, choice of re... | 2026-10-12 08:19:21.436575+00:00 |
| 26 | CALL-1791792856 | CUS-10842 | Sarah expressed a strong interest in upgrading her cover due to concern over her new car's protec... | Signals and sentiment from the conversation were analysed, mapped against candidate rules, valida... | [
  {
    "why": "Sarah explicitly requested features only available in the full Comprehensive co... | 2026-10-12 08:19:45.938485+00:00 |



## policies

**Rows:** 2


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| policy_id | integer | NO | nextval('policies_policy_id_seq'::regclass) |
| customer_id | text | YES | — |
| lob | text | YES | — |
| current_product | text | YES | — |
| vehicle_desc | text | YES | — |
| vehicle_value_aud | text | YES | — |
| vehicle_usage | text | YES | — |
| renewal_days | text | YES | — |
| home_insurance_status | text | YES | — |
| address_change | text | YES | — |
| new_address_type | text | YES | — |
| created_at | timestamp with time zone | YES | now() |
| updated_at | timestamp with time zone | YES | now() |

### Data

| policy_id | customer_id | lob | current_product | vehicle_desc | vehicle_value_aud | vehicle_usage | renewal_days | home_insurance_status | address_change | new_address_type | created_at | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CUS-10842 | Motor | Comprehensive Essentials | 2024 Toyota RAV4 | AUD 48,000 | Personal | 30 days | NULL | NULL | NULL | 2026-10-09 07:30:13.977097+00:00 | 2026-10-09 07:30:13.977097+00:00 |
| 2 | CUS-10925 | Motor | Third Party Property Damage | 2023 Toyota RAV4 | AUD 45,000 | Personal | 45 days | None | Yes | Owner-occupied home | 2026-10-09 07:30:13.977097+00:00 | 2026-10-09 07:30:13.977097+00:00 |



## recommendation_cooldown

**Rows:** 0


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| cooldown_id | integer | NO | nextval('recommendation_cooldown_cooldown_id_seq'::regclass) |
| customer_id | text | YES | — |
| opportunity_name | text | YES | — |
| declined_at | timestamp with time zone | YES | — |
| cooldown_until | timestamp with time zone | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

*No data in this table*



## rule_matrix

**Rows:** 23


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| rule_id | integer | NO | nextval('rule_matrix_rule_id_seq'::regclass) |
| row_order | integer | NO | — |
| existing_product_lob | text | YES | — |
| core_product_cover | text | YES | — |
| rule_type | text | YES | — |
| opportunity | text | YES | — |
| opportunity_description | text | YES | — |
| data_required | text | YES | — |
| eligibility_suppression_rules | text | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| rule_id | row_order | existing_product_lob | core_product_cover | rule_type | opportunity | opportunity_description | data_required | eligibility_suppression_rules | created_at |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | Motor – Third Party Property Damage | Cover for loss or damage caused to other people's cars or property up to  Million legal liability... | Upsell | Comprehensive / Comprehensive Essentials | Generic Trigger: Customer has cover for damage caused to others but no cover for their own vehicl... | Current motor product; vehicle year/make/model/value; renewal date; vehicle/usage changes; intera... | TPPD active; target product eligible; no existing Comprehensive/Essentials; CTP recorded separate... | 2026-10-09 07:30:13.977097+00:00 |
| 2 | 2 | Motor – Comprehensive Essentials | Comprehensive essentials cover at market value for accidental damage, theft, weather events, lega... | Upsell | Comprehensive (Full Tier) | Generic Trigger: Re-evaluate when the customer is approaching renewal, has a newer/higher-value v... | Current product/options; vehicle year/value; usage; renewal; relevant interactions/claims. | Essentials active; target product applicable; required data valid; not already Comprehensive; no ... | 2026-10-09 07:30:13.977097+00:00 |
| 3 | 3 | Motor – Comprehensive | Full Comprehensive cover including accidental damage/theft, weather events, legal liability up to... | Upsell | Comprehensive Optional Benefits (Add-Ons) | Generic Trigger: At renewal, after a relevant claim/interaction (e.g., windscreen chip claim), or... | Current Comprehensive options; claim/interaction history; vehicle/use; renewal. | Comprehensive active; target option available and not selected; suppress duplicate/cooldown.

Dri... | 2026-10-09 07:30:13.977097+00:00 |
| 4 | 4 | Home – Building | Building cover for the insured residential home/property against loss or damage caused by defined... | Upsell | Home & Contents (Combined Policy) | Generic Trigger: Customer has Building cover and verified residential contents exposure. At renew... | Building policy; occupancy/ownership; contents exposure/value; renewal; policy status. | Building active; contents exposure confirmed; owner-occupier confirmed via title registry; no equ... | 2026-10-09 07:30:13.977097+00:00 |
| 5 | 5 | NULL | NULL | Upsell | Building Optional Benefits (Enhanced Building Protection) | Generic Trigger: At renewal or when property characteristics, location/environmental exposure, re... | Property type; building sum insured; rebuild indicators; location risk; appliance age/type; curre... | Building eligible; owner-occupier status verified via title registry; relevant option available a... | 2026-10-09 07:30:13.977097+00:00 |
| 14 | 14 | NULL | NULL | Cross-sell | Boat / Pleasure Craft | Generic Trigger: Customer has confirmed boat/pleasure-craft exposure and no corresponding cover.
... | Asset ownership; boat type; existing policies. | Qualifying pleasure craft confirmed; boat usage verified; no corresponding cover. | 2026-10-09 07:30:13.977097+00:00 |
| 6 | 6 | Home – Contents | Contents cover for household belongings, furniture, appliances, electronics, clothing, and person... | Upsell | Contents Optional Benefits (Enhanced Contents Protection) | Generic Trigger: At renewal, after a contents claim, when high-value/portable items are identifie... | Contents profile/value; portable-item indicators; storage status; appliance age/type; claims; int... | Contents active; relevant option applicable and not selected; item/storage conditions pass; suppr... | 2026-10-09 07:30:13.977097+00:00 |
| 7 | 7 | Home & Contents | Combined Building + Contents cover under one Home Insurance policy, protecting both physical buil... | Upsell | Home & Contents Optional Benefits | Generic Trigger: At renewal, after a property/contents change or claim, or when location, rebuild... | Building/contents details; sum insured; location risk; item/storage/appliance data; claims; curre... | Home & Contents active; owner-occupier status verified via land title registry; target option ava... | 2026-10-09 07:30:13.977097+00:00 |
| 8 | 8 | Renter | Contents cover designed specifically for renters/tenants, protecting internal household belonging... | Upsell | Renter Optional Benefits | Generic Trigger: At renewal, after a contents claim, when portable/high-value items are identifie... | Renter policy; contents/portable-item profile; storage; claims; interactions; current options. | Renter active; confirmed tenant status at residential address (satisfying TMD target market rules... | 2026-10-09 07:30:13.977097+00:00 |
| 9 | 9 | Landlord | Landlord Building and/or Contents cover for investment/rental property; loss of rental income fol... | Upsell | Landlord Optional Benefits | Generic Trigger: At renewal, after a tenancy/property change or landlord claim, or when rental-in... | Landlord status; building/contents cover; tenancy/rental status; sum insured/rebuild indicators; ... | Landlord policy active; confirmed investment/rental property ownership via title registry; active... | 2026-10-09 07:30:13.977097+00:00 |
| 10 | 10 | Motor | Existing Motor policy (Third Party, Comprehensive Essentials, or Comprehensive) protecting the cu... | Cross-sell | Home Building/Contents / Home & Contents | Generic Trigger: Customer is a confirmed owner/occupier with residential property exposure with c... | Occupancy; property ownership; address/property type; existing policies. | Owner/occupier confirmed via title registry; eligible residential property & contents exposure; T... | 2026-10-09 07:30:13.977097+00:00 |
| 11 | 11 | NULL | NULL | Cross-sell | Renter | Generic Trigger: Customer is a confirmed renter/tenant with contents exposure and no active Rente... | Occupancy; address; existing policies. | Renter status confirmed via address/profile data; tenant TMD criteria met; no Renter policy. | 2026-10-09 07:30:13.977097+00:00 |
| 12 | 12 | NULL | NULL | Cross-sell | Landlord | Generic Trigger: Customer has a confirmed investment/rental property and no active Landlord polic... | Property ownership/use; tenancy; existing policies. | Investment/rental property confirmed via title registry; active tenancy; Landlord TMD criteria me... | 2026-10-09 07:30:13.977097+00:00 |
| 13 | 13 | NULL | NULL | Cross-sell | Caravan & Trailer | Generic Trigger: Customer has confirmed caravan/trailer/camper/horse-trailer exposure and no corr... | Asset ownership; asset type; existing policies. | Qualifying leisure asset confirmed; no equivalent policy. | 2026-10-09 07:30:13.977097+00:00 |
| 15 | 15 | Home / Contents / Home & Contents | Existing Home Building, Contents, or combined Home & Contents policy protecting the customer's re... | Cross-sell | Motor/Caravan & Trailer/Boat / Pleasure Craft | Generic Trigger: Customer has a confirmed personal vehicle, caravan, or boat not represented by M... | Vehicle ownership/use; vehicle details; existing Motor policy. | Eligible personal vehicle; Driver & Claims History Validation: Driver licence status, 3–5 year cl... | 2026-10-09 07:30:13.977097+00:00 |
| 16 | 16 | Renter | Existing Renter Contents policy protecting tenant household belongings. | Cross-sell | Motor/Caravan & Trailer/Boat / Pleasure Craft | Generic Trigger: Customer has a confirmed personal vehicle, caravan, or boat without Motor/asset ... | Vehicle ownership/use; existing policies. | Eligible personal vehicle; Driver & Claims History Validation: Licence status, claims history, de... | 2026-10-09 07:30:13.977097+00:00 |
| 17 | 17 | Landlord | Existing Landlord Insurance policy protecting an investment/rental property. | Cross-sell | Motor/Caravan & Trailer/Boat / Pleasure Craft | Generic Trigger: Customer has a confirmed personal vehicle/towing vehicle, boat/pleasure-craft wi... | Vehicle ownership/use; existing policies. | Eligible personal vehicle; Driver & Claims History Validation: Licence status, driver history; no... | 2026-10-09 07:30:13.977097+00:00 |
| 18 | 18 | NULL | NULL | Cross-sell | Home / Contents | Generic Trigger: Customer has a separate owner-occupied residence not represented by Home cover.
... | Property ownership/occupancy; addresses; existing policies. | Separate owner-occupied property confirmed via title registry; owner-occupier TMD criteria met; n... | 2026-10-09 07:30:13.977097+00:00 |
| 19 | 19 | Caravan & Trailer | Insurance for qualifying caravans, camper trailers, horse floats, and associated risks. | Cross-sell | Motor/Boat / Pleasure Craft | Generic Trigger: Customer has a confirmed personal vehicle/towing vehicle, boat/pleasure-craft wi... | Vehicle data; existing policies. | Eligible personal vehicle; Driver & Claims History Validation: Licence status, towing experience,... | 2026-10-09 07:30:13.977097+00:00 |
| 20 | 20 | NULL | NULL | Cross-sell | Home / Contents | Generic Trigger: Customer has confirmed residential property/contents exposure not represented by... | Occupancy/ownership; property; existing policies. | Eligible residential exposure; no equivalent cover. | 2026-10-09 07:30:13.977097+00:00 |
| 21 | 21 | Boat / Pleasure Craft | Club Marine Pleasure Craft Insurance distributed through Allianz Australia; cover includes accide... | Cross-sell | Motor | Generic Trigger: Customer has confirmed personal vehicle without Motor policy.

Detailed Coverage... | Vehicle data; existing policies. | Eligible vehicle; Driver & Claims History Validation: Licence status, 3–5 year claims history, de... | 2026-10-09 07:30:13.977097+00:00 |
| 22 | 22 | NULL | NULL | Cross-sell | Home / Contents | Generic Trigger: Customer has confirmed residential property/contents exposure without correspond... | Property/occupancy; existing policies. | Eligible residential exposure; no equivalent cover. | 2026-10-09 07:30:13.977097+00:00 |
| 23 | 23 | NULL | NULL | Cross-sell | Caravan & Trailer | Generic Trigger: Customer has confirmed caravan/trailer exposure without corresponding cover.

De... | Asset data; existing policies. | Qualifying asset; no policy. | 2026-10-09 07:30:13.977097+00:00 |



## rule_matrix_2

**Rows:** 16


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| rule_id | text | NO | — |
| opportunity_type | text | NO | — |
| target_product_category | text | NO | — |
| existing_customer_policy_situation | text | NO | — |
| opportunity_trigger | text | NO | — |
| proposed_recommendation | text | NO | — |
| business_rationale_customer_value | text | NO | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| rule_id | opportunity_type | target_product_category | existing_customer_policy_situation | opportunity_trigger | proposed_recommendation | business_rationale_customer_value | created_at |
|---|---|---|---|---|---|---|---|
| UP-CAR-01 | Upsell | Car Insurance | Active Third-Party Liability only | Policyholder holds zero physical damage protection on a vehicle carrying significant market value. | Upgrade to Partial or Full Comprehensive cover. | Protects the customer against total financial loss from environmental storm damage, fire, theft, ... | 2026-10-13 11:29:54.898275+00:00 |
| UP-CAR-02 | Upsell | Car Insurance | Active Partial Comprehensive cover | Vehicle retains substantial market value; self-inflicted collision or vandalism risk remains unhe... | Upgrade to Full Comprehensive cover. | Closes the critical gap for own-vehicle collision damage and parking vandalism. | 2026-10-13 11:29:54.898275+00:00 |
| UP-CAR-03 | Upsell | Car Insurance | Active Full Comprehensive policy in Smart package tier; vehicle age ≤ 3 years. | Vehicle is near-new; customer lacks multi-year replacement price guarantees. | Upgrade from Smart to Comfort or Premium package tier. | Unlocks 24–36 month new-vehicle purchase price reimbursement and lower deductibles. | 2026-10-13 11:29:54.898275+00:00 |
| UP-CAR-04 | Upsell | Car Insurance | Active Full Comprehensive policy; customer bonus standing in Tier 4 or higher; clean claims histo... | High accumulated bonus equity at risk; an at-fault accident would trigger a costly bonus-malus do... | Add No-Claims Discount Protection rider. | Protects the customer's hard-earned discount level so that one at-fault accident per year does no... | 2026-10-13 11:29:54.898275+00:00 |
| UP-CAR-05 | Upsell | Car Insurance | Active Car policy of any tier; declared annual commuter mileage ≥ 15,000 km no breakdown cover held. | Customer is a regular long-distance commuter with high breakdown vulnerability. | Add Roadside Assistance & Breakdown Mobility module. | Secures 24/7 towing, breakdown support, and replacement mobility during commute disruptions. | 2026-10-13 11:29:54.898275+00:00 |
| UP-CAR-06 | Upsell | Car Insurance | Active Car policy; policyholder is primary household earner; transports family dependants. | Third-party liability strictly excludes compensation for the driver's own injuries in an at-fault... | Add Driver Personal Injury Cover. | Closes the major bodily injury gap by funding medical costs, disability capital, and loss of inco... | 2026-10-13 11:29:54.898275+00:00 |
| UP-HOM-01 | Upsell | Home Insurance (Building) | Active Residential Building policy; Natural Hazards / Flood cover currently excluded; property in... | Property is exposed to heavy torrential downpours, surface water runoff, and sewer backflow. | Add Extended Natural Hazards / Flood Cover. | Protects against severe weather and flash flooding, which are strictly excluded from standard fir... | 2026-10-13 11:29:54.898275+00:00 |
| UP-HOM-02 | Upsell | Home Insurance (Building) | Active Residential Building policy in Smart tier; building age ≥ 20 years or features solar/heat ... | Property structure faces external pipe aging risks or features modern renewable energy equipment. | Upgrade to Comfort or Premium Building tier. | Extends cover to external underground supply pipes and provides all-risk protection for renewable... | 2026-10-13 11:29:54.898275+00:00 |
| UP-HOM-03 | Upsell | Home Insurance (Contents) | Active Home Contents policy; ground floor or basement storage areas utilized; natural perils excl... | High vulnerability to water ingress and flash flood damage to stored furnishings and electronics. | Add Natural Hazards Cover for Contents. | Protects household inventory and basement storage against heavy rain inundation and sewer backflow. | 2026-10-13 11:29:54.898275+00:00 |
| UP-HOM-04 | Upsell | Home Insurance (Contents) | Active Home Contents policy of any tier; customer profile indicates ownership of high-value bicyc... | Standard burglary cover is restricted to home premises and includes night-time exclusion clauses. | Add Comprehensive Bicycle & E-Bike Protection. | Provides 24/7 worldwide theft and crash damage protection without restrictive lock covenants. | 2026-10-13 11:29:54.898275+00:00 |
| CS-CAR-01 | Cross-Sell | Home Insurance | Policyholder holds Car Insurance; verified residential homeowner or long-term tenant; no property... | Expiring car renewal indicates stable residential footprint with an unprotected home asset or hou... | Recommend Home Insurance (Building for owner, Contents for tenant). | Consolidates core asset protection under one insurer and unlocks multi-policy bundle savings. | 2026-10-13 11:29:54.898275+00:00 |
| CS-CAR-02 | Cross-Sell | Personal Liability | Policyholder holds Car Insurance; zero personal liability insurance record exists in the customer... | Customer faces unlimited legal liability for daily private accidents outside of vehicle operation. | Recommend Personal Liability Insurance (Smart or Comfort tier). | Foundational risk protection shielding personal assets and wages against lifetime third-party dam... | 2026-10-13 11:29:54.898275+00:00 |
| CS-CAR-03 | Cross-Sell | Animal/Pet Insurance | Policyholder holds Car Insurance; customer master profile records verified dog ownership; no pet ... | Policyholder is exposed to strict civil liability for injuries or traffic accidents caused by the... | Recommend Dog Owner Liability Insurance. | Covers legal compensation claims, rental property damage, and off-leash incidents. | 2026-10-13 11:29:54.898275+00:00 |
| CS-HOM-01 | Cross-Sell | Personal Liability | Customer holds Home Insurance (Building or Contents); zero personal liability policy on record. | Property ownership or tenancy introduces severe liability exposures (e.g., icy pavement falls, te... | Recommend Personal Liability Insurance (Comfort Family or Single). | Protects against catastrophic third-party liability claims and provides passive legal defense. | 2026-10-13 11:29:54.898275+00:00 |
| CS-HOM-02 | Cross-Sell | Car Insurance | Customer holds Home Insurance; customer owns a registered private vehicle insured with an externa... | High-retention household asset customer can benefit from integrated portfolio pricing. | Recommend Car Insurance (Comprehensive or Partial). | Unlocks compounding multi-policy bundle discount across both Home and Car insurance premiums. | 2026-10-13 11:29:54.898275+00:00 |
| CS-LIA-01 | Cross-Sell | Home Contents | Customer holds Personal Liability Insurance; confirmed residential tenant or owner; no contents p... | Policyholder protects against third-party damage but leaves their own household furnishings compl... | Recommend Home Contents Insurance. | Reimburses household goods at brand-new replacement cost in the event of fire, tap water burst, o... | 2026-10-13 11:29:54.898275+00:00 |



## rule_matrix_conditions

**Rows:** 3


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| condition_id | integer | NO | nextval('rule_matrix_conditions_condition_id_seq'::regclass) |
| rule_id | integer | YES | — |
| current_product_code | text | YES | — |
| target_product_code | text | YES | — |
| trigger_keywords | ARRAY | YES | — |
| already_held_check | text | YES | — |
| notes | text | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| condition_id | rule_id | current_product_code | target_product_code | trigger_keywords | already_held_check | notes | created_at |
|---|---|---|---|---|---|---|---|
| 1 | 2 | MOTOR_COMPREHENSIVE_ESSENTIALS | MOTOR_COMPREHENSIVE_FULL | [
  "rental car",
  "choice of repairer",
  "agreed value",
  "extra protection"
] | MOTOR_COMPREHENSIVE_FULL | Sample 1 (Sarah Williams) upsell rule. | 2026-10-09 07:30:13.977097+00:00 |
| 2 | 1 | MOTOR_TPPD | MOTOR_COMPREHENSIVE_ESSENTIALS_OR_FULL | [
  "comprehensive",
  "own vehicle",
  "renewal"
] | MOTOR_COMPREHENSIVE_ESSENTIALS_OR_FULL | Sample 2 (Michael Brown) upsell rule. | 2026-10-09 07:30:13.977097+00:00 |
| 3 | 10 | MOTOR_ANY | HOME_AND_CONTENTS | [
  "own home",
  "new address",
  "owner-occupied",
  "bundle discount"
] | HOME_AND_CONTENTS | Sample 2 (Michael Brown) cross-sell rule — owner-occupier confirmed via conversation. | 2026-10-09 07:30:13.977097+00:00 |



## transcript_lines

**Rows:** 42


### Schema

| Column Name | Data Type | Nullable | Default |
|---|---|---|---|
| line_id | integer | NO | nextval('transcript_lines_line_id_seq'::regclass) |
| call_id | text | YES | — |
| speaker | text | YES | — |
| text | text | YES | — |
| created_at | timestamp with time zone | YES | now() |

### Data

| line_id | call_id | speaker | text | created_at |
|---|---|---|---|---|
| 5 | CALL-1791789042 | csr | Thank you Sarah. I have your policy up on my screen now. You currently have comprehensive Essenti... | 2026-10-12 07:12:42.215992+00:00 |
| 6 | CALL-1791789042 | customer | Thanks for explaining that. So, just to check—if I wanted things like a rental car after an accid... | 2026-10-12 07:12:45.764685+00:00 |
| 7 | CALL-1791789042 | csr | So I would suggest you to upgrade to a comprehensive full tier motor cover. So here the reason wh... | 2026-10-12 07:14:04.204046+00:00 |
| 8 | CALL-1791789042 | customer | Right, that sounds like exactly what I’m after then. Especially with a new car, I’d definitely wa... | 2026-10-12 07:14:08.092965+00:00 |
| 9 | CALL-1791789042 | csr | Hello. | 2026-10-12 07:14:32.181418+00:00 |
| 10 | CALL-1791789042 | customer | Hi again! Was there anything else you needed to check about the policy or the upgrade? Happy to c... | 2026-10-12 07:14:34.879206+00:00 |
| 11 | CALL-1791789042 | csr | Hello, are you still there? | 2026-10-12 07:21:49.303932+00:00 |
| 12 | CALL-1791789042 | customer | Yeah, I'm still here! Just let me know if you’ve got any other questions or need more info about ... | 2026-10-12 07:21:52.037769+00:00 |
| 13 | CALL-1791789042 | csr | Absolutely, like I have checked your eligibility against our underwriting rules and you are eligi... | 2026-10-12 07:22:24.433681+00:00 |
| 14 | CALL-1791789042 | customer | Oh, that’s great news—thanks for checking that for me! I really appreciate it. I reckon I’ll go a... | 2026-10-12 07:22:28.584974+00:00 |
| 15 | CALL-1791789042 | csr | that you can I can assure of like you will be covered properly. So if you can Give me a green sig... | 2026-10-12 07:23:01.602362+00:00 |
| 16 | CALL-1791789042 | customer | Yep, all good—go ahead and set it up for my renewal. I definitely want the comprehensive full tie... | 2026-10-12 07:23:05.213272+00:00 |
| 17 | CALL-1791789042 | csr | Okay, I have applied for that. | 2026-10-12 07:23:27.942275+00:00 |
| 18 | CALL-1791789042 | csr | Thank you. | 2026-10-12 07:23:30.195965+00:00 |
| 19 | CALL-1791789042 | customer | No worries, thanks for your help today! Have a good one. | 2026-10-12 07:23:32.583965+00:00 |
| 20 | CALL-1791790469 | csr | So Michael, your motor policy is due for renewal in 45 days. I was reviewing your policy and noti... | 2026-10-12 07:35:51.123547+00:00 |
| 21 | CALL-1791790469 | customer | Thanks for bringing that up. I’ve been meaning to look into a bit more cover actually, after that... | 2026-10-12 07:35:53.837168+00:00 |
| 22 | CALL-1791790469 | csr | So basically, comprehensive essentials provides protection for damage to your own vehicle in addi... | 2026-10-12 07:36:28.651517+00:00 |
| 23 | CALL-1791790469 | customer | Right, gotcha. I reckon I’d like to go with full comprehensive then, just for the extra peace of ... | 2026-10-12 07:36:32.326976+00:00 |
| 24 | CALL-1791790469 | csr | So is the new home which you are there currently, so it's kind of your own home or are you in a r... | 2026-10-12 07:36:57.772892+00:00 |
| 25 | CALL-1791790469 | customer | Yeah, it’s my own home — I’m the owner-occupier now. | 2026-10-12 07:37:00.179383+00:00 |
| 26 | CALL-1791790469 | csr | Great! Congratulations on your new home. In that case, I would strongly recommend setting up home... | 2026-10-12 07:37:39.864631+00:00 |
| 27 | CALL-1791790469 | customer | Oh, that sounds spot on actually. I’d much rather have everything sorted with the same insurer an... | 2026-10-12 07:37:42.752287+00:00 |
| 28 | CALL-1791790469 | csr | So can I apply for the selected opportunity for both the upgrade to the full comprehensive motor ... | 2026-10-12 07:38:30.175979+00:00 |
| 29 | CALL-1791790469 | customer | Yeah, that’d be great. Let’s go ahead and do the upgrade to full comprehensive for the car, and g... | 2026-10-12 07:38:32.963029+00:00 |
| 30 | CALL-1791790469 | csr | Okay, great. So I will apply for the selected opportunity. | 2026-10-12 07:38:49.720252+00:00 |
| 31 | CALL-1791790469 | customer | Perfect, sounds good. Let me know if you need anything else from me. Cheers! | 2026-10-12 07:38:52.005686+00:00 |
| 32 | CALL-1791790469 | csr | So I have applied for the opportunity and it's logged for the code binding. | 2026-10-12 07:39:10.354859+00:00 |
| 33 | CALL-1791790469 | customer | Beauty, thanks for letting me know. Just let me know what happens next, or if you need anything e... | 2026-10-12 07:39:12.591591+00:00 |
| 34 | CALL-1791790469 | csr | Nothing as of now. Thank you. Have a great day. | 2026-10-12 07:39:28.040196+00:00 |
| 35 | CALL-1791790469 | customer | No worries, thanks for your help. Have a good one! | 2026-10-12 07:39:30.329952+00:00 |
| 36 | CALL-1791792856 | csr | Thank you Sarah. I have your policy up on my screen now. You currently have like comprehensive es... | 2026-10-12 08:16:01.683662+00:00 |
| 37 | CALL-1791792856 | customer | Ah, okay, thanks for explaining that. So if my car gets damaged and it’s not my fault, I don’t ge... | 2026-10-12 08:16:07.875065+00:00 |
| 38 | CALL-1791792856 | csr | You take up to me. | 2026-10-12 08:16:32.784191+00:00 |
| 39 | CALL-1791792856 | customer | Sorry, I didn’t quite catch that—could you repeat what you meant? I just want to make sure I’m fo... | 2026-10-12 08:16:35.079876+00:00 |
| 40 | CALL-1791792856 | csr | So Sarah, you can upgrade from comprehensive essential to over full comprehensive cover. Like wit... | 2026-10-12 08:18:26.136636+00:00 |
| 41 | CALL-1791792856 | customer | Oh, that actually sounds perfect. The agreed value and new car replacement are really important t... | 2026-10-12 08:18:30.868360+00:00 |
| 42 | CALL-1791792856 | csr | Yeah, it's totally possible to upgrade your cover. So if you suggest to me so can I just apply fo... | 2026-10-12 08:19:06.280928+00:00 |
| 43 | CALL-1791792856 | customer | Yep, that’d be great, thanks! If you could check if I’m eligible for the upgrade at my renewal, t... | 2026-10-12 08:19:09.680540+00:00 |
| 44 | CALL-1791792856 | csr | Thanks, Sarah. I have applied for the full comprehensive cover. If you need any further inputs. | 2026-10-12 08:19:29.685665+00:00 |
| 45 | CALL-1791792856 | csr | Then I would be there for help to you. | 2026-10-12 08:19:32.393558+00:00 |
| 46 | CALL-1791792856 | customer | Thanks heaps for sorting that out for me! If anything else pops up or if I’ve got more questions,... | 2026-10-12 08:19:34.849548+00:00 |

