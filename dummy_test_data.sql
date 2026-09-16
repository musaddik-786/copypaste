INSERT INTO fnol_mandatory_fields
    (field_name, field_label, field_category, is_required, can_be_inferred, inference_question, input_type, input_options, display_order)
VALUES
('loss_type',         'Type of Loss',         'incident',   1, 1,
 'What type of property loss occurred? (Water Damage, Fire, Theft, Storm, Vandalism, etc.)',
 'select', '["Water Damage","Fire","Theft","Storm","Vandalism","Structural Damage","Electrical","Other"]', 1),

('cause_of_loss',     'Cause of Loss',         'incident',   1, 1,
 'What caused the loss or damage to the property?',
 'text', NULL, 2),

('date_of_loss',      'Date of Loss',           'incident',   1, 1,
 'What date did the damage occur? (YYYY-MM-DD)',
 'date', NULL, 3),

('time_of_loss',      'Time of Loss',           'incident',   0, 1,
 'Approximately what time did the incident occur?',
 'time', NULL, 4),

('area_affected',     'Area Affected',          'location',   1, 1,
 'Which part of the property was damaged? (e.g. kitchen ceiling, basement, roof)',
 'text', NULL, 5),

('occupancy_at_loss', 'Occupancy at Time',      'context',    0, 1,
 'Was the property occupied when the loss occurred?',
 'select', '["Occupied","Unoccupied","Partially Occupied"]', 6),

('sudden_vs_gradual', 'Sudden or Gradual',      'incident',   0, 1,
 'Did the damage happen suddenly or develop gradually over time?',
 'select', '["Sudden","Gradual","Unknown"]', 7),

('severity',          'Damage Severity',        'assessment', 1, 1,
 'How severe is the property damage? Low, Medium, or High?',
 'select', '["Low","Medium","High"]', 8),

('urgency_indicator', 'Urgency Level',          'assessment', 0, 1,
 'How urgently does this claim need attention? Immediate, Standard, or Low?',
 'select', '["Immediate","Standard","Low"]', 9)

ON CONFLICT (field_name) DO NOTHING;
