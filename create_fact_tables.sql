/*
Derived fact tables for the mobile-app event data.

Run this script after loading or changing events. It clears and rebuilds all
four fact tables. All dates use UTC.
*/

BEGIN;

CREATE TABLE IF NOT EXISTS fact_user_daily_activity (
    activity_date DATE NOT NULL,
    user_id BIGINT NOT NULL
        REFERENCES dim_users(user_id),
    first_event_ts TIMESTAMPTZ NOT NULL,
    last_event_ts TIMESTAMPTZ NOT NULL,
    event_count BIGINT NOT NULL,
    session_count BIGINT NOT NULL,
    is_payer BOOLEAN NOT NULL,
    payments NUMERIC NOT NULL,

    PRIMARY KEY (activity_date, user_id)
);

CREATE TABLE IF NOT EXISTS fact_daily_activity (
    activity_date DATE PRIMARY KEY,
    daily_active_users BIGINT NOT NULL,
    event_count BIGINT NOT NULL,
    session_count BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_daily_purchases (
    purchase_date DATE PRIMARY KEY,
    purchase_count BIGINT NOT NULL,
    purchasing_users BIGINT NOT NULL,
    total_revenue NUMERIC NOT NULL,
    average_purchase_value NUMERIC NOT NULL,
    diamonds_purchased BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_user_ftu (
    user_id BIGINT PRIMARY KEY
        REFERENCES dim_users(user_id),
    first_started_at TIMESTAMPTZ,
    first_completed_at TIMESTAMPTZ,
    started_count BIGINT NOT NULL,
    completed_count BIGINT NOT NULL,
    ftu_completed BOOLEAN NOT NULL,
    completion_seconds NUMERIC
);

TRUNCATE TABLE
    fact_daily_activity,
    fact_daily_purchases,
    fact_user_ftu,
    fact_user_daily_activity;


INSERT INTO fact_user_daily_activity (
    activity_date,
    user_id,
    first_event_ts,
    last_event_ts,
    event_count,
    session_count,
    is_payer,
    payments
)
SELECT
    (e.client_ts AT TIME ZONE 'UTC')::DATE,
    e.user_id,
    MIN(e.client_ts),
    MAX(e.client_ts),
    COUNT(*),
    COUNT(DISTINCT e.session_id),
    BOOL_OR(e.action_type = 'purchase'),
    COALESCE(
        SUM(e.action_value) FILTER (
            WHERE e.action_type = 'purchase'
        ),
        0
    )
FROM events e
GROUP BY
    (e.client_ts AT TIME ZONE 'UTC')::DATE,
    e.user_id;


INSERT INTO fact_daily_activity (
    activity_date,
    daily_active_users,
    event_count,
    session_count
)
SELECT
    activity_date,
    COUNT(*),
    SUM(event_count)::BIGINT,
    SUM(session_count)::BIGINT
FROM fact_user_daily_activity
GROUP BY activity_date;


INSERT INTO fact_daily_purchases (
    purchase_date,
    purchase_count,
    purchasing_users,
    total_revenue,
    average_purchase_value,
    diamonds_purchased
)
SELECT
    (e.client_ts AT TIME ZONE 'UTC')::DATE,
    COUNT(*),
    COUNT(DISTINCT e.user_id),
    SUM(e.action_value),
    AVG(e.action_value),
    SUM((e.action_json ->> 'amount')::INTEGER)
FROM events e
WHERE e.action_type = 'purchase'
GROUP BY
    (e.client_ts AT TIME ZONE 'UTC')::DATE;


INSERT INTO fact_user_ftu (
    user_id,
    first_started_at,
    first_completed_at,
    started_count,
    completed_count,
    ftu_completed,
    completion_seconds
)
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
    completed_count > 0,
    EXTRACT(
        EPOCH FROM first_completed_at - first_started_at
    )
FROM user_ftu;

COMMIT;
