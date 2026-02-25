-- SQL Server (T-SQL)
-- Sample Data for Healthcare Analytics

-- Insert sample patients (with mix of regions and creation dates)
INSERT INTO patients (patient_id, name, birth_date, created_at, region) VALUES
(1001, 'James Wilson', '1985-03-15', '2020-01-15', 'Northeast'),
(1002, 'Maria Garcia', '1978-07-22', '2020-03-20', 'West'),
(1003, 'Robert Chen', '1992-11-08', '2020-06-10', 'South'),
(1004, 'Patricia Brown', '1965-09-30', '2021-02-05', 'Midwest'),
(1005, 'Michael Lee', '1988-12-12', '2021-04-18', 'Northeast'),
(1006, 'Jennifer Kim', '1995-05-25', '2021-08-30', 'West'),
(1007, 'David Rodriguez', '1972-08-19', '2022-01-12', 'South'),
(1008, 'Lisa Thompson', '1983-04-05', '2022-03-25', 'Midwest'),
(1009, 'William Taylor', '1990-10-10', '2022-07-08', 'Northeast'),
(1010, 'Sarah Martinez', '1976-12-03', '2022-09-14', 'West'),
(1011, 'Thomas Anderson', '1982-06-28', '2023-01-20', 'South'),
(1012, 'Emily White', '1998-02-14', '2023-04-05', 'Midwest'),
(1013, 'Charles Davis', '1969-11-17', '2023-06-30', 'Northeast'),
(1014, 'Jessica Miller', '1993-08-09', '2023-09-15', 'West'),
(1015, 'Daniel Wilson', '1987-04-22', '2024-01-10', 'South');

-- Insert sample appointments (spread across 2+ years)
INSERT INTO appointments (appt_id, patient_id, appt_date, status) VALUES
-- 2024 appointments
(20001, 1001, '2024-01-15', 'COMPLETED'),
(20002, 1002, '2024-01-22', 'COMPLETED'),
(20003, 1003, '2024-02-03', 'COMPLETED'),
(20004, 1004, '2024-02-18', 'NO_SHOW'),
(20005, 1005, '2024-03-05', 'COMPLETED'),
(20006, 1001, '2024-03-20', 'COMPLETED'),
(20007, 1006, '2024-04-02', 'COMPLETED'),
(20008, 1007, '2024-04-15', 'COMPLETED'),
(20009, 1008, '2024-05-01', 'NO_SHOW'),
(20010, 1002, '2024-05-14', 'COMPLETED'),
(20011, 1003, '2024-05-28', 'COMPLETED'),
(20012, 1009, '2024-06-10', 'COMPLETED'),
(20013, 1004, '2024-06-24', 'SCHEDULED'), -- Cancelled? Actually this was scheduled for future but now past
(20014, 1005, '2024-07-08', 'COMPLETED'),
(20015, 1010, '2024-07-22', 'COMPLETED'),
(20016, 1001, '2024-08-05', 'NO_SHOW'),
(20017, 1006, '2024-08-19', 'COMPLETED'),
(20018, 1007, '2024-09-02', 'COMPLETED'),
(20019, 1011, '2024-09-16', 'COMPLETED'),
(20020, 1002, '2024-09-30', 'NO_SHOW'),

-- 2025 appointments
(20021, 1003, '2025-01-10', 'COMPLETED'),
(20022, 1008, '2025-01-24', 'COMPLETED'),
(20023, 1012, '2025-02-07', 'COMPLETED'),
(20024, 1004, '2025-02-21', 'COMPLETED'),
(20025, 1009, '2025-03-07', 'NO_SHOW'),
(20026, 1005, '2025-03-21', 'COMPLETED'),
(20027, 1013, '2025-04-04', 'COMPLETED'),
(20028, 1001, '2025-04-18', 'COMPLETED'),
(20029, 1006, '2025-05-02', 'COMPLETED'),
(20030, 1010, '2025-05-16', 'NO_SHOW'),
(20031, 1007, '2025-05-30', 'COMPLETED'),
(20032, 1014, '2025-06-13', 'COMPLETED'),
(20033, 1002, '2025-06-27', 'COMPLETED'),
(20034, 1011, '2025-07-11', 'SCHEDULED'),
(20035, 1003, '2025-07-25', 'SCHEDULED'),
(20036, 1015, '2025-08-08', 'SCHEDULED'),
(20037, 1008, '2025-08-22', 'SCHEDULED'),
(20038, 1004, '2025-09-05', 'SCHEDULED'),
(20039, 1012, '2025-09-19', 'SCHEDULED'),
(20040, 1005, '2025-10-03', 'SCHEDULED'),

-- Patient 1001's appointments (showing pattern)
(20041, 1001, '2024-11-12', 'COMPLETED'),
(20042, 1001, '2025-02-15', 'COMPLETED'),
(20043, 1001, '2025-05-20', 'NO_SHOW'),
(20044, 1001, '2025-06-25', 'NO_SHOW'),
(20045, 1001, '2025-07-30', 'NO_SHOW'), -- 3 consecutive NO_SHOWs!

-- Patient 1006's appointments (no shows pattern)
(20046, 1006, '2024-12-05', 'NO_SHOW'),
(20047, 1006, '2025-01-09', 'NO_SHOW'),
(20048, 1006, '2025-02-13', 'NO_SHOW'), -- 3 consecutive NO_SHOWs
(20049, 1006, '2025-03-20', 'COMPLETED'),

-- Patient 1013 (newer patient, no recent appointments - for question 1)
(20050, 1013, '2024-08-15', 'COMPLETED'), -- Last appt >12 months ago

-- Patient 1014 (new patient, no appointments at all)
-- (No appointments for 1014 intentionally)

-- Patient 1015 (brand new, only future appointments)
(20051, 1015, '2025-08-08', 'SCHEDULED'), -- Future only

-- Additional appointments to test date ranges
(20052, 1002, '2024-10-15', 'COMPLETED'),
(20053, 1002, '2024-11-19', 'COMPLETED'),
(20054, 1007, '2024-12-22', 'COMPLETED'),
(20055, 1009, '2024-11-30', 'COMPLETED');

PRINT 'Healthcare sample data inserted successfully';
