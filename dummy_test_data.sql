-- Fix motor_vehicle_details (correct column names)
INSERT INTO motor_vehicle_details
    (policy_number, driver_license, vin, registration_number, vehicle_make, vehicle_model, vehicle_year)
VALUES
('POL-1001', NULL, '1HGCV1F30NA000001', 'TX-AB-1234', 'Honda',      'Accord',      2022),
('POL-1002', NULL, 'JT2BF22K1X0123456', 'TX-CD-5678', 'Toyota',     'Camry',       2021),
('POL-1003', NULL, '1FA6P8CF3N5000003', 'TX-EF-9012', 'Ford',       'Mustang GT',  2023),
('POL-1004', NULL, 'MALA851BLNM000004', 'TX-GH-3456', 'Hyundai',    'Creta',       2022),
('POL-1005', NULL, 'KNDJN2A26J7000005', 'AZ-IJ-7890', 'Kia',        'Seltos',      2021),
('POL-1006', NULL, 'WBA8E9G55JNU00006', 'CA-KL-2345', 'BMW',        '3 Series',    2023),
('POL-1007', NULL, 'WDDWF4JB8FR000007', 'CA-MN-6789', 'Mercedes',   'C-Class',     2023),
('POL-1008', NULL, '1C4HJWDG8JL000008', 'CO-OP-0123', 'Jeep',       'Wrangler',    2022),
('POL-1009', NULL, '4S4BSANC2J3000009', 'WA-QR-4567', 'Subaru',     'Outback',     2021),
('POL-1010', NULL, 'JM3KFBDM1J0000010', 'OR-ST-8901', 'Mazda',      'CX-5',        2022),
('POL-1011', NULL, 'WAUFFAFL8JA000011', 'IL-UV-2345', 'Audi',       'A4',          2023),
('POL-1012', NULL, '3GCUKREC1JG000012', 'TN-WX-6789', 'Chevrolet',  'Silverado',   2022),
('POL-1013', NULL, 'MA3EYDMS1J000013',  'GA-YZ-0123', 'Maruti',     'Swift',       2021),
('POL-1014', NULL, 'TATAF01FXLA000014', 'FL-AB-4567', 'Tata',       'Nexon',       2022),
('POL-1015', NULL, 'WP1AF2A23JLA00015', 'NV-CD-8901', 'Porsche',    'Cayenne',     2023),
('POL-1016', NULL, '1V2MR2CA5JC000016', 'MA-EF-2345', 'Volkswagen', 'Tiguan',      2022),
('POL-1017', NULL, 'JN8AT2MT4JW000017', 'MN-GH-6789', 'Nissan',     'Rogue',       2021),
('POL-1018', NULL, '1C6RR7LT4JS000018', 'MI-IJ-0123', 'Dodge',      'Ram 1500',    2022),
('POL-1019', NULL, '2T2BZMCA0JC000019', 'PA-KL-4567', 'Lexus',      'RX 350',      2023),
('POL-1020', NULL, 'YV4A22RL4J1000020', 'OH-MN-8901', 'Volvo',      'XC60',        2022)
ON CONFLICT (policy_number) DO NOTHING;
-- Fix motor_fnol_mandatory_fields (correct column names)
INSERT INTO motor_fnol_mandatory_fields
    (field_name, field_label, field_category, is_required, can_be_inferred, inference_question, input_type, input_options, display_order)
VALUES
('loss_type',         'Type of Loss',         'incident',   TRUE,  TRUE,
 'What type of motor loss occurred? (Collision, Theft, Vandalism, Fire, Natural Disaster, Third-Party Liability, Windshield Damage)',
 'select', '["Collision","Theft","Vandalism","Fire","Natural Disaster","Third-Party Liability","Windshield Damage"]', 1),

('cause_of_loss',     'Cause of Loss',         'incident',   TRUE,  TRUE,
 'What caused the loss or damage? Describe the incident.',
 'text', NULL, 2),

('date_of_loss',      'Date of Loss',           'incident',   TRUE,  TRUE,
 'What date did the incident occur? (YYYY-MM-DD)',
 'date', NULL, 3),

('time_of_loss',      'Time of Loss',           'incident',   FALSE, TRUE,
 'Approximately what time did the incident occur?',
 'time', NULL, 4),

('accident_location', 'Accident Location',      'location',   TRUE,  TRUE,
 'Where did the accident occur? Please provide the location.',
 'text', NULL, 5),

('severity',          'Damage Severity',        'assessment', TRUE,  TRUE,
 'How severe is the vehicle damage? Low, Medium, or High?',
 'select', '["Low","Medium","High"]', 6),

('urgency_indicator', 'Urgency Level',          'assessment', FALSE, TRUE,
 'How urgently does this claim need attention? Immediate, Standard, or Low?',
 'select', '["Immediate","Standard","Low"]', 7),

('emotional_context', 'Policyholder State',     'context',    FALSE, TRUE,
 'How is the policyholder feeling? Are they distressed, calm, or worried?',
 'text', NULL, 8)

ON CONFLICT (field_name) DO NOTHING;
-- Fix motor_policy_details (without postal_code which may not exist)
INSERT INTO motor_policy_details
    (policy_number, status, coverage_type, deductible, coverage_limit,
     remaining_coverage_limit, effective_date, expiration_date, premium_amount,
     policyholder_name, account_number, policy_address, city, state, exclusions, term_type, currency, country)
VALUES
('POL-1001','Active','Motor', 500.00,150000.00,150000.00,'2025-01-01','2026-01-01', 4500.00,'John Smith',      'ACC-M-1001','12 Oak Street, Austin TX 78701',    'Austin',      'TX','Racing, DUI','Annual','USD','USA'),
('POL-1002','Active','Motor', 500.00,120000.00,120000.00,'2025-03-01','2026-03-01', 3600.00,'Jane Doe',        'ACC-M-1002','34 Elm Ave, Houston TX 77001',      'Houston',     'TX', NULL,         'Annual','USD','USA'),
('POL-1003','Active','Motor', 750.00,200000.00,200000.00,'2025-06-01','2026-06-01', 6000.00,'Robert Jones',    'ACC-M-1003','56 Pine Rd, Dallas TX 75201',       'Dallas',      'TX','Racing',      'Annual','USD','USA'),
('POL-1004','Active','Motor', 500.00,100000.00,100000.00,'2025-01-15','2026-01-15', 3000.00,'Mary Brown',      'ACC-M-1004','78 Maple Dr, San Antonio TX 78201', 'San Antonio', 'TX', NULL,         'Annual','USD','USA'),
('POL-1005','Active','Motor', 250.00, 80000.00, 80000.00,'2025-02-01','2026-02-01', 2400.00,'David Wilson',    'ACC-M-1005','90 Cedar Ln, Phoenix AZ 85001',     'Phoenix',     'AZ', NULL,         'Annual','USD','USA'),
('POL-1006','Active','Motor', 500.00,175000.00,175000.00,'2025-04-01','2026-04-01', 5250.00,'Sarah Johnson',   'ACC-M-1006','23 Birch Blvd, Los Angeles CA 90001','Los Angeles', 'CA','Racing, Off-road','Annual','USD','USA'),
('POL-1007','Active','Motor', 750.00,250000.00,250000.00,'2025-05-01','2026-05-01', 7500.00,'Michael Davis',   'ACC-M-1007','45 Spruce St, San Diego CA 92101',  'San Diego',   'CA', NULL,         'Annual','USD','USA'),
('POL-1008','Active','Motor', 500.00,130000.00,130000.00,'2025-07-01','2026-07-01', 3900.00,'Emily Martinez',  'ACC-M-1008','67 Willow Way, Denver CO 80201',    'Denver',      'CO','DUI',         'Annual','USD','USA'),
('POL-1009','Active','Motor', 250.00, 90000.00, 90000.00,'2025-08-01','2026-08-01', 2700.00,'James Taylor',    'ACC-M-1009','89 Aspen Ave, Seattle WA 98101',    'Seattle',     'WA', NULL,         'Annual','USD','USA'),
('POL-1010','Active','Motor', 500.00,160000.00,160000.00,'2025-09-01','2026-09-01', 4800.00,'Lisa Anderson',   'ACC-M-1010','11 Hickory Ct, Portland OR 97201',  'Portland',    'OR', NULL,         'Annual','USD','USA'),
('POL-1011','Active','Motor', 750.00,220000.00,220000.00,'2025-01-01','2026-01-01', 6600.00,'Christopher Lee', 'ACC-M-1011','33 Sycamore St, Chicago IL 60601',  'Chicago',     'IL','Racing',      'Annual','USD','USA'),
('POL-1012','Active','Motor', 500.00,110000.00,110000.00,'2025-02-15','2026-02-15', 3300.00,'Amanda White',    'ACC-M-1012','55 Poplar Pl, Nashville TN 37201',  'Nashville',   'TN', NULL,         'Annual','USD','USA'),
('POL-1013','Active','Motor', 250.00, 75000.00, 75000.00,'2025-03-15','2026-03-15', 2250.00,'Daniel Harris',   'ACC-M-1013','77 Magnolia Dr, Atlanta GA 30301',  'Atlanta',     'GA', NULL,         'Annual','USD','USA'),
('POL-1014','Active','Motor', 500.00,140000.00,140000.00,'2025-04-15','2026-04-15', 4200.00,'Jessica Clark',   'ACC-M-1014','99 Dogwood Ln, Miami FL 33101',     'Miami',       'FL','Off-road',    'Annual','USD','USA'),
('POL-1015','Active','Motor', 750.00,300000.00,300000.00,'2025-05-15','2026-05-15', 9000.00,'Matthew Robinson','ACC-M-1015','21 Redwood Rd, Las Vegas NV 89101', 'Las Vegas',   'NV','Racing, DUI', 'Annual','USD','USA'),
('POL-1016','Active','Motor', 500.00,125000.00,125000.00,'2025-06-15','2026-06-15', 3750.00,'Ashley Lewis',    'ACC-M-1016','43 Juniper St, Boston MA 02101',    'Boston',      'MA', NULL,         'Annual','USD','USA'),
('POL-1017','Active','Motor', 250.00, 85000.00, 85000.00,'2025-07-15','2026-07-15', 2550.00,'Ryan Walker',     'ACC-M-1017','65 Fir Ave, Minneapolis MN 55401',  'Minneapolis', 'MN', NULL,         'Annual','USD','USA'),
('POL-1018','Active','Motor', 500.00,190000.00,190000.00,'2025-08-15','2026-08-15', 5700.00,'Megan Hall',      'ACC-M-1018','87 Cypress Ct, Detroit MI 48201',   'Detroit',     'MI','DUI',         'Annual','USD','USA'),
('POL-1019','Active','Motor', 750.00,240000.00,240000.00,'2025-09-15','2026-09-15', 7200.00,'Kevin Young',     'ACC-M-1019','9 Walnut Blvd, Philadelphia PA 19101','Philadelphia','PA', NULL,        'Annual','USD','USA'),
('POL-1020','Active','Motor', 500.00,145000.00,145000.00,'2025-10-01','2026-10-01', 4350.00,'Stephanie King',  'ACC-M-1020','31 Chestnut Rd, Columbus OH 43201', 'Columbus',    'OH', NULL,         'Annual','USD','USA')
ON CONFLICT (policy_number) DO UPDATE SET
    remaining_coverage_limit = EXCLUDED.coverage_limit,
    policyholder_name        = EXCLUDED.policyholder_name,
    status                   = EXCLUDED.status;
