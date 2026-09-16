INSERT INTO motor_fnol_mandatory_fields
    (field_name, field_label, field_category, is_required, can_be_inferred, inference_question, input_type, input_options, display_order)
VALUES
('loss_type',         'Type of Loss',       'incident',   1, 1,
 'What type of motor loss occurred? (Collision, Theft, Vandalism, Fire, Natural Disaster, Third-Party Liability, Windshield Damage)',
 'select', '["Collision","Theft","Vandalism","Fire","Natural Disaster","Third-Party Liability","Windshield Damage"]', 1),

('cause_of_loss',     'Cause of Loss',      'incident',   1, 1,
 'What caused the loss or damage? Describe the incident.',
 'text', NULL, 2),

('date_of_loss',      'Date of Loss',       'incident',   1, 1,
 'What date did the incident occur? (YYYY-MM-DD)',
 'date', NULL, 3),

('time_of_loss',      'Time of Loss',       'incident',   0, 1,
 'Approximately what time did the incident occur?',
 'time', NULL, 4),

('accident_location', 'Accident Location',  'location',   1, 1,
 'Where did the accident occur? Please provide the location.',
 'text', NULL, 5),

('severity',          'Damage Severity',    'assessment', 1, 1,
 'How severe is the vehicle damage? Low, Medium, or High?',
 'select', '["Low","Medium","High"]', 6),

('urgency_indicator', 'Urgency Level',      'assessment', 0, 1,
 'How urgently does this claim need attention? Immediate, Standard, or Low?',
 'select', '["Immediate","Standard","Low"]', 7),

('emotional_context', 'Policyholder State', 'context',    0, 1,
 'How is the policyholder feeling? Are they distressed, calm, or worried?',
 'text', NULL, 8)

ON CONFLICT (field_name) DO NOTHING;
