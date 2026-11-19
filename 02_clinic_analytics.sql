-- ============================================================================
-- CareLoop Clinics: Operational No-Show Analytics (MySQL)
-- ============================================================================

-- 1. High-Volume Clinic No-Show Leaderboard (Minimum 95 Appointments)
SELECT 
    c.clinic_name,
    c.city,
    COUNT(a.appointment_id) AS total_appointments,
    SUM(a.no_show) AS total_no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(a.appointment_id), 1) AS no_show_pct
FROM clinics c
INNER JOIN appointments a 
    ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(a.appointment_id) >= 95
ORDER BY no_show_pct DESC;


-- 2. No-Show Escalation Across Booking Lead-Time Bands
SELECT 
    CASE 
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30 days'
        WHEN lead_days >= 31 THEN '31+ days'
    END AS lead_time_band,
    COUNT(*) AS total_appointments,
    SUM(no_show) AS total_no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
WHERE lead_days > 0
GROUP BY lead_time_band
ORDER BY MIN(lead_days);


-- 3. Month-over-Month No-Show Rate Trajectory
WITH monthly_summary AS (
    SELECT 
        SUBSTR(appt_date, 1, 7) AS appt_month,
        COUNT(*) AS total_appointments,
        SUM(no_show) AS total_no_shows,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY appt_month
)
SELECT 
    appt_month,
    total_appointments,
    no_show_pct,
    ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY appt_month), 1) AS mom_pct_point_delta
FROM monthly_summary
ORDER BY appt_month;


-- 4. Intra-City Clinic Ranking & Network Benchmark Comparison
WITH clinic_metrics AS (
    SELECT 
        c.clinic_id,
        c.clinic_name,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(a.appointment_id), 1) AS no_show_pct,
        RANK() OVER (
            PARTITION BY c.city 
            ORDER BY ROUND(100.0 * SUM(a.no_show) / COUNT(a.appointment_id), 1) DESC
        ) AS city_rank
    FROM clinics c
    INNER JOIN appointments a 
        ON c.clinic_id = a.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
),
network_avg AS (
    SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS overall_pct
    FROM appointments
)
SELECT 
    cm.clinic_name,
    cm.city,
    cm.no_show_pct,
    cm.city_rank,
    CASE 
        WHEN cm.no_show_pct > na.overall_pct THEN 'above'
        WHEN cm.no_show_pct < na.overall_pct THEN 'below'
        ELSE 'equal'
    END AS vs_network_avg
FROM clinic_metrics cm
CROSS JOIN network_avg na
ORDER BY cm.city, cm.city_rank;
