-- ── MOTOR LOB — 5 pre-submitted claims ───────────────────────────────────────
INSERT INTO motor_fnol_submissions (
    policy_number, policyholder_name, lob, status, claim_number,
    loss_type, cause_of_loss, date_of_loss, time_of_loss,
    accident_location, severity, estimated_loss_amount
) VALUES
('POL-1001','John Smith',   'Motor','submitted','MCLM-2026-0001','Collision','Rear-ended at traffic signal',   '2026-09-10','09:00','MG Road, Bangalore',       'High',  45000.00),
('POL-1002','Jane Doe',     'Motor','submitted','MCLM-2026-0002','Theft',    'Vehicle stolen from parking lot','2026-09-11','22:00','HSR Layout, Bangalore',    'High',  80000.00),
('POL-1003','Robert Jones', 'Motor','submitted','MCLM-2026-0003','Fire',     'Engine fire due to short circuit','2026-09-12','14:30','Outer Ring Road, Bangalore','Medium',60000.00),
('POL-1004','Mary Brown',   'Motor','submitted','MCLM-2026-0004','Vandalism','Scratches and broken windshield','2026-09-13','08:00','Koramangala, Bangalore',   'Low',    8000.00),
('POL-1005','David Wilson', 'Motor','submitted','MCLM-2026-0005','Collision','Hit a divider at highway speed', '2026-09-14','16:00','NICE Road, Bangalore',     'High',  25000.00)
ON CONFLICT DO NOTHING;


-- ── HOMEOWNERS LOB — 5 pre-submitted claims ──────────────────────────────────
INSERT INTO claims (
    claim_number, policyholder_name, policy_number,
    loss_type, short_description, severity, estimated_cost,
    status, date_of_loss, location, ai_confidence, filed_at
) VALUES
('HO-2026-0001','Alice Thompson',  '73-300676','Fire',       'Kitchen fire caused by electrical fault',        'High',  85000.00,'Open','2026-09-10','10 Lakewood Drive, Boston MA',      88, NOW()),
('HO-2026-0002','Alice Thompson',  '73-300676','Waterdamage','Burst pipe flooded basement and living room',    'Medium',32000.00,'Open','2026-09-11','10 Lakewood Drive, Boston MA',      82, NOW()),
('HO-2026-0003','Brian Foster',    '73-400676','burglary',   'Break-in through rear window, electronics stolen','Medium',15000.00,'Open','2026-09-12','22 Riverside Ave, Chicago IL',     79, NOW()),
('HO-2026-0004','Brian Foster',    '73-400676','Hurricane',  'Roof damage and broken windows from storm',      'High',  55000.00,'Open','2026-09-13','22 Riverside Ave, Chicago IL',     91, NOW()),
('HO-2026-0005','Catherine Park',  '73-123676','Waterdamage','Gradual leak from roof damaged ceiling',        'Low',    9500.00,'Open','2026-09-14','44 Hillcrest Blvd, Denver CO',     75, NOW())
ON CONFLICT DO NOTHING;
