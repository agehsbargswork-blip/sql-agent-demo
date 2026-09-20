/*
Derived fact views for the mobile-app event data.

All dates use UTC.

fact_user_daily_activity:
One row per active user per day.

fact_daily_activity:
One row per day with overall activity totals.

fact_daily_purchases:
One row per day with purchase totals.

fact_user_ftu:
One row per user with FTU activity and completion information.
*/

CREATE OR REPLACE VIEW fact_user_daily_activity AS
SELECT
    (e.client_ts AT TIME ZONE 'UTC')::DATE AS activity_date,
    e.user_id,
    MIN(e.client_ts) AS first_event_ts,
    MAX(e.client_ts) AS last_event_ts,
    COUNT(*) AS event_count,
    COUNT(DISTINCT e.session_id) AS session_count,
    BOOL_OR(e.action_type = 'purchase') AS is_payer,
    COALESCE(
        SUM(e.action_value) FILTER (
            WHERE e.action_type = 'purchase'
        ),
        0
    ) AS payments
FROM events e
GROUP BY
    (e.client_ts AT TIME ZONE 'UTC')::DATE,
    e.user_id;


CREATE OR REPLACE VIEW fact_daily_activity AS
SELECT
    activity_date,
    COUNT(*) AS daily_active_users,
    SUM(event_count) AS event_count,
    SUM(session_count) AS session_count
FROM fact_user_daily_activity
GROUP BY activity_date;


CREATE OR REPLACE VIEW fact_daily_purchases AS
SELECT
    (e.client_ts AT TIME ZONE 'UTC')::DATE AS purchase_date,
    COUNT(*) AS purchase_count,
    COUNT(DISTINCT e.user_id) AS purchasing_users,
    SUM(e.action_value) AS total_revenue,
    AVG(e.action_value) AS average_purchase_value,
    SUM((e.action_json ->> 'amount')::INTEGER) AS diamonds_purchased
FROM events e
WHERE e.action_type = 'purchase'
GROUP BY
    (e.client_ts AT TIME ZONE 'UTC')::DATE;


CREATE OR REPLACE VIEW fact_user_ftu AS
WITH user_ftu AS (
    SELECT
        u.user_id,
        MIN(e.client_ts) FILTER (
            WHERE e.action_type = 'ftu_started'
        ) AS first_started_at,
        MIN(e.client_ts) FILTER (
            WHERE e.action_type = 'ftu_completed'
        ) AS first_completed_at,
        COUNT(e.event_id) FILTER (
            WHERE e.action_type = 'ftu_started'
        ) AS started_count,
        COUNT(e.event_id) FILTER (
            WHERE e.action_type = 'ftu_completed'
        ) AS completed_count
    FROM dim_users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY u.user_id
)

SELECT
    user_id,
    first_started_at,
    first_completed_at,
    started_count,
    completed_count,
    completed_count > 0 AS ftu_completed,
    EXTRACT(
        EPOCH FROM first_completed_at - first_started_at
    ) AS completion_seconds
FROM user_ftu;
