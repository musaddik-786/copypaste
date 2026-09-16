INSERT INTO motor_fnol_mandatory_fields
    (field_name, display_name, field_type, is_required, display_order, placeholder, description)
VALUES
('loss_type',         'Type of Loss',        'select', TRUE,  1, NULL,
    'Motor loss category — Collision, Theft, Vandalism, Fire, Natural Disaster, Third-Party Liability, Windshield Damage'),

('cause_of_loss',     'Cause of Loss',       'text',   TRUE,  2, 'e.g. Rear-ended at traffic signal',
    'Detailed cause or description of what happened'),

('date_of_loss',      'Date of Loss',        'date',   TRUE,  3, 'YYYY-MM-DD',
    'Date when the motor incident occurred'),

('time_of_loss',      'Time of Loss',        'time',   FALSE, 4, 'HH:MM (24-hr)',
    'Approximate time of the incident'),

('accident_location', 'Accident Location',   'text',   TRUE,  5, 'e.g. MG Road near traffic signal, Bangalore',
    'Exact or approximate location of the accident'),

('severity',          'Damage Severity',     'select', TRUE,  6, NULL,
    'Low / Medium / High — based on visible damage assessment'),

('urgency_indicator', 'Urgency Level',       'select', FALSE, 7, NULL,
    'Immediate / Standard / Low — how quickly the claim needs action'),

('emotional_context', 'Policyholder State',  'text',   FALSE, 8, 'e.g. Worried, Calm, Distressed',
    'Emotional state of the policyholder during intake');


claimsagenti… | postgres | schema: session default
Open in New Tab
12:38:25 PM
Started executing query at Line 1
NOTICE: relation "motor_fnol_mandatory_fields" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 782
NOTICE: relation "motor_policy_details" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 807
NOTICE: relation "motor_vehicle_details" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 822
NOTICE: relation "motor_coverage_verification_results" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 835
NOTICE: relation "motor_fnol_submissions" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 868
NOTICE: relation "motor_fnol_mandatory_question_log" already exists, skipping
CREATE TABLE
12:38:25 PM
Started executing query at Line 880
