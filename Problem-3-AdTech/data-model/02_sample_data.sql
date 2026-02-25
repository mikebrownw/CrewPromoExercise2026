-- SQL Server (T-SQL)
-- Sample Data for AdTech Analytics with Realistic JSON Payloads

-- Insert sample users across different countries
INSERT INTO users (user_id, country, created_at) VALUES
(1001, 'US', '2024-01-15'),
(1002, 'US', '2024-02-20'),
(1003, 'CA', '2024-03-10'),
(1004, 'US', '2024-04-05'),
(1005, 'CA', '2024-05-12'),
(1006, 'UK', '2024-06-18'),
(1007, 'US', '2024-07-22'),
(1008, 'CA', '2024-08-30'),
(1009, 'US', '2024-09-14'),
(1010, 'FR', '2024-10-01'),
(1011, 'US', '2024-10-15'),
(1012, 'CA', '2024-11-20'),
(1013, 'US', '2024-12-05'),
(1014, 'CA', '2025-01-10'),
(1015, 'US', '2025-02-14');

-- Insert events with complex JSON payloads
-- Q4 2025 is Oct-Dec 2025

INSERT INTO events (event_id, user_id, event_time, payload_json) VALUES

-- October 2025 events (Q4)
(20001, 1001, '2025-10-01 10:15:00', '{"utm": {"source": "google", "campaign": "fall_sale", "medium": "cpc"}, "page": "/products", "device": "mobile", "session_id": "sess_001"}'),
(20002, 1002, '2025-10-02 14:30:00', '{"utm": {"source": "facebook", "campaign": "fall_sale", "medium": "social"}, "page": "/home", "device": "desktop", "session_id": "sess_002"}'),
(20003, 1003, '2025-10-03 09:45:00', '{"utm": {"source": "bing", "campaign": "back_to_school", "medium": "cpc"}, "page": "/search", "device": "tablet", "session_id": "sess_003"}'),
(20004, 1004, '2025-10-04 16:20:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/checkout", "device": "mobile", "session_id": "sess_004"}'),
(20005, 1005, '2025-10-05 11:10:00', '{"utm": {"source": "instagram", "campaign": "holiday_prep", "medium": "social"}, "page": "/products", "device": "mobile", "session_id": "sess_005"}'),
(20006, 1001, '2025-10-06 13:25:00', '{"utm": {"source": "google", "campaign": "fall_sale", "medium": "cpc"}, "page": "/cart", "device": "desktop", "session_id": "sess_006"}'),
(20007, 1007, '2025-10-07 08:50:00', '{"utm": {"source": "email", "campaign": "newsletter", "medium": "email"}, "page": "/blog", "device": "mobile", "session_id": "sess_007"}'),
(20008, 1008, '2025-10-08 19:15:00', '{"utm": {"source": "google", "campaign": "fall_sale", "medium": "cpc"}, "page": "/products", "device": "desktop", "session_id": "sess_008"}'),
(20009, 1009, '2025-10-09 12:40:00', '{"utm": {"source": "tiktok", "campaign": "viral_challenge", "medium": "social"}, "page": "/video", "device": "mobile", "session_id": "sess_009"}'),
(20010, 1010, '2025-10-10 15:55:00', '{"utm": {"source": "google", "campaign": "fall_sale", "medium": "cpc"}, "page": "/home", "device": "mobile", "session_id": "sess_010"}'),

-- November 2025 events (more volume for campaign analysis)
(20011, 1011, '2025-11-01 10:00:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/sale", "device": "desktop", "session_id": "sess_011"}'),
(20012, 1012, '2025-11-02 11:30:00', '{"utm": {"source": "facebook", "campaign": "black_friday", "medium": "social"}, "page": "/sale", "device": "mobile", "session_id": "sess_012"}'),
(20013, 1013, '2025-11-03 09:15:00', '{"utm": {"source": "google", "campaign": "cyber_monday", "medium": "cpc"}, "page": "/electronics", "device": "desktop", "session_id": "sess_013"}'),
(20014, 1014, '2025-11-04 14:45:00', '{"utm": {"source": "instagram", "campaign": "black_friday", "medium": "social"}, "page": "/fashion", "device": "mobile", "session_id": "sess_014"}'),
(20015, 1015, '2025-11-05 16:20:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/home", "device": "tablet", "session_id": "sess_015"}'),
(20016, 1001, '2025-11-06 08:30:00', '{"utm": {"source": "email", "campaign": "black_friday", "medium": "email"}, "page": "/sale", "device": "mobile", "session_id": "sess_016"}'),
(20017, 1002, '2025-11-07 13:10:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/checkout", "device": "desktop", "session_id": "sess_017"}'),
(20018, 1003, '2025-11-08 10:25:00', '{"utm": {"source": "bing", "campaign": "black_friday", "medium": "cpc"}, "page": "/search", "device": "mobile", "session_id": "sess_018"}'),
(20019, 1004, '2025-11-09 15:50:00', '{"utm": {"source": "google", "campaign": "cyber_monday", "medium": "cpc"}, "page": "/tech", "device": "desktop", "session_id": "sess_019"}'),
(20020, 1005, '2025-11-10 12:15:00', '{"utm": {"source": "tiktok", "campaign": "black_friday", "medium": "social"}, "page": "/video", "device": "mobile", "session_id": "sess_020"}'),
(20021, 1001, '2025-11-11 09:40:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/products", "device": "mobile", "session_id": "sess_021"}'),
(20022, 1002, '2025-11-12 17:05:00', '{"utm": {"source": "facebook", "campaign": "cyber_monday", "medium": "social"}, "page": "/deals", "device": "desktop", "session_id": "sess_022"}'),
(20023, 1003, '2025-11-13 11:30:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/cart", "device": "mobile", "session_id": "sess_023"}'),
(20024, 1004, '2025-11-14 14:55:00', '{"utm": {"source": "instagram", "campaign": "cyber_monday", "medium": "social"}, "page": "/fashion", "device": "mobile", "session_id": "sess_024"}'),
(20025, 1005, '2025-11-15 10:20:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/home", "device": "desktop", "session_id": "sess_025"}'),

-- December 2025 events (holiday season)
(20026, 1006, '2025-12-01 10:10:00', '{"utm": {"source": "google", "campaign": "holiday_sale", "medium": "cpc"}, "page": "/gifts", "device": "mobile", "session_id": "sess_026"}'),
(20027, 1007, '2025-12-02 13:35:00', '{"utm": {"source": "facebook", "campaign": "holiday_sale", "medium": "social"}, "page": "/wishlist", "device": "desktop", "session_id": "sess_027"}'),
(20028, 1008, '2025-12-03 09:50:00', '{"utm": {"source": "google", "campaign": "boxing_day", "medium": "cpc"}, "page": "/sale", "device": "tablet", "session_id": "sess_028"}'),
(20029, 1009, '2025-12-04 16:15:00', '{"utm": {"source": "email", "campaign": "holiday_sale", "medium": "email"}, "page": "/blog", "device": "mobile", "session_id": "sess_029"}'),
(20030, 1010, '2025-12-05 11:40:00', '{"utm": {"source": "google", "campaign": "holiday_sale", "medium": "cpc"}, "page": "/checkout", "device": "desktop", "session_id": "sess_030"}'),
(20031, 1011, '2025-12-06 14:05:00', '{"utm": {"source": "tiktok", "campaign": "holiday_sale", "medium": "social"}, "page": "/video", "device": "mobile", "session_id": "sess_031"}'),
(20032, 1012, '2025-12-07 08:30:00', '{"utm": {"source": "google", "campaign": "boxing_day", "medium": "cpc"}, "page": "/products", "device": "mobile", "session_id": "sess_032"}'),
(20033, 1013, '2025-12-08 12:55:00', '{"utm": {"source": "bing", "campaign": "holiday_sale", "medium": "cpc"}, "page": "/search", "device": "desktop", "session_id": "sess_033"}'),
(20034, 1014, '2025-12-09 15:20:00', '{"utm": {"source": "google", "campaign": "holiday_sale", "medium": "cpc"}, "page": "/home", "device": "mobile", "session_id": "sess_034"}'),
(20035, 1015, '2025-12-10 09:45:00', '{"utm": {"source": "instagram", "campaign": "boxing_day", "medium": "social"}, "page": "/fashion", "device": "mobile", "session_id": "sess_035"}'),

-- Additional US/CA events specifically for Q4 analysis
(20036, 1001, '2025-11-16 10:30:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/products", "device": "mobile", "session_id": "sess_036"}'),
(20037, 1002, '2025-11-17 14:45:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/products", "device": "desktop", "session_id": "sess_037"}'),
(20038, 1003, '2025-11-18 09:15:00', '{"utm": {"source": "facebook", "campaign": "black_friday", "medium": "social"}, "page": "/sale", "device": "mobile", "session_id": "sess_038"}'),
(20039, 1004, '2025-11-19 16:50:00', '{"utm": {"source": "google", "campaign": "cyber_monday", "medium": "cpc"}, "page": "/tech", "device": "desktop", "session_id": "sess_039"}'),
(20040, 1005, '2025-11-20 11:20:00', '{"utm": {"source": "instagram", "campaign": "black_friday", "medium": "social"}, "page": "/fashion", "device": "mobile", "session_id": "sess_040"}'),
(20041, 1007, '2025-10-15 13:40:00', '{"utm": {"source": "google", "campaign": "fall_sale", "medium": "cpc"}, "page": "/products", "device": "mobile", "session_id": "sess_041"}'),
(20042, 1008, '2025-10-22 10:05:00', '{"utm": {"source": "facebook", "campaign": "fall_sale", "medium": "social"}, "page": "/home", "device": "desktop", "session_id": "sess_042"}'),
(20043, 1009, '2025-12-15 15:30:00', '{"utm": {"source": "google", "campaign": "holiday_sale", "medium": "cpc"}, "page": "/gifts", "device": "mobile", "session_id": "sess_043"}'),
(20044, 1011, '2025-12-18 12:55:00', '{"utm": {"source": "email", "campaign": "holiday_sale", "medium": "email"}, "page": "/blog", "device": "desktop", "session_id": "sess_044"}'),
(20045, 1012, '2025-11-25 09:20:00', '{"utm": {"source": "google", "campaign": "black_friday", "medium": "cpc"}, "page": "/checkout", "device": "mobile", "session_id": "sess_045"}');

PRINT 'AdTech sample data inserted successfully';
