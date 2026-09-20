# Database Guide for LLMs

## Purpose

This PostgreSQL database represents synthetic activity from a mobile application. It contains dimension tables, a raw event table and derived fact tables.

## Table relationships

| Table | Grain | Primary key | Purpose |
|---|---|---|---|
| `dim_country` | One country | `id` | Country names and ISO codes |
| `dim_platform` | One platform | `id` | iOS, Android, Amazon or Other |
| `dim_devices` | One device model | `id` | Device models and their platforms |
| `dim_acquisition_channel` | One channel | `id` | Organic and paid acquisition sources |
| `dim_campaign` | One campaign | `id` | Marketing campaigns and their channels |
| `dim_users` | One user | `user_id` | User attributes recorded at installation |
| `events` | One event | `event_id` | Raw mobile-app activity |
| `fact_user_daily_activity` | One user per active day | `(activity_date, user_id)` | Daily activity and payments per user |
| `fact_daily_activity` | One day | `activity_date` | Overall daily activity |
| `fact_daily_purchases` | One day | `purchase_date` | Overall daily purchase metrics |
| `fact_user_ftu` | One user | `user_id` | First-time-user experience activity |

## Dimension tables

### `dim_country`

- `id`: country identifier.
- `country_code`: two-letter country code, such as `US`.
- `country_name`: full country name.

Join with `dim_users.country_id = dim_country.id`.

### `dim_platform`

- `id`: platform identifier.
- `platform_name`: platform name.

Join with `dim_users.platform_id = dim_platform.id` or `events.platform_id = dim_platform.id`.

### `dim_devices`

- `id`: device identifier.
- `device_model`: device model.
- `platform_id`: platform associated with the device.

A composite foreign key validates each device-platform combination. Do not assume that every device is compatible with every platform.

### `dim_acquisition_channel`

- `id`: acquisition-channel identifier.
- `channel_name`: channel name, such as Organic, Meta Ads or Google Ads.

Join with `dim_users.acquisition_channel_id = dim_acquisition_channel.id`.

### `dim_campaign`

- `id`: campaign identifier.
- `campaign_name`: campaign name.
- `acquisition_channel_id`: channel to which the campaign belongs.

Organic users normally have a `NULL` campaign. Use a `LEFT JOIN` unless organic users should be excluded.

## Users

### `dim_users`

`dim_users` contains one row per installed user.

- `user_id`: unique user identifier.
- `country_id`: installation country.
- `install_datetime`: installation timestamp.
- `platform_id`: installation platform.
- `device_id`: installation device.
- `acquisition_channel_id`: acquisition source.
- `campaign_id`: marketing campaign; nullable for organic users.
- `os_version`: operating-system version.
- `app_version_at_install`: app version at installation.
- `language`: two-letter language code.
- `is_test_user`: identifies test users.

Exclude test users when analysing normal customer behaviour unless the question explicitly includes them:

```sql
WHERE u.is_test_user = FALSE
```

## Raw events

### `events`

`events` contains one row per recorded user action.

- `event_id`: unique event UUID.
- `user_id`: user who generated the event.
- `session_id`: groups related events.
- `platform_id`, `device_id`: platform and device recorded for the event.
- `client_ts`: timestamp recorded by the device.
- `server_ts`: timestamp received by the server.
- `app_version`: app version used during the event.
- `event_schema_version`: event-format version.
- `action_type`: event category.
- `action_subtype`: optional subtype.
- `action_json`: optional JSON attributes.
- `action_value`: optional numeric value.

Use `client_ts` for user-behaviour analysis. Convert it to a UTC date with:

```sql
(client_ts AT TIME ZONE 'UTC')::DATE
```

### Event types

| `action_type` | Subtype | JSON | Value |
|---|---|---|---|
| `open_app` | `NULL` | `NULL` | `NULL` |
| `lobby_loaded` | `NULL` | `NULL` | `NULL` |
| `ftu_started` | `standard_ftu` | FTU attributes | `NULL` |
| `ftu_completed` | `standard_ftu` | FTU attributes | `NULL` |
| `purchase` | `diamonds` | Purchase attributes | Payment amount |

For purchases, `action_value` is the monetary payment and `action_json ->> 'amount'` is the number of diamonds.

## Derived fact tables

These are physical tables, not views. They are rebuilt by running `create_tables/create_fact_tables.sql`. They do not update automatically when `events` changes.

### `fact_user_daily_activity`

One row per active user per day:

- `activity_date`
- `user_id`
- `first_event_ts`
- `last_event_ts`
- `event_count`
- `session_count`
- `is_payer`
- `payments`

The existence of a row means the user was active. `is_payer` means the user recorded at least one purchase that day. `payments` is the total purchase `action_value` for that user and day.

### `fact_daily_activity`

One row per day:

- `activity_date`
- `daily_active_users`
- `event_count`
- `session_count`

Use this table for overall DAU trends. It is already aggregated.

### `fact_daily_purchases`

One row per day:

- `purchase_date`
- `purchase_count`
- `purchasing_users`
- `total_revenue`
- `average_purchase_value`
- `diamonds_purchased`

Use this table for overall daily monetisation. Use raw `events` or `fact_user_daily_activity` when user-level segmentation is required.

### `fact_user_ftu`

One row per user:

- `user_id`
- `first_started_at`
- `first_completed_at`
- `started_count`
- `completed_count`
- `ftu_completed`
- `completion_seconds`

The synthetic data is intentionally messy. A user may complete FTU without a recorded start, repeat an FTU event, or have completion recorded before the first start. Therefore, `completion_seconds` may be `NULL` or negative.

## Choosing the correct table

- Overall DAU by date: `fact_daily_activity`.
- User-level daily activity: `fact_user_daily_activity`.
- Overall purchases by date: `fact_daily_purchases`.
- FTU status per user: `fact_user_ftu`.
- Individual actions or JSON attributes: `events`.
- Segmentation by country, platform or acquisition: join a user-level fact or `events` to `dim_users` and the relevant dimension.

## Querying rules

1. Respect each table's grain.
2. Use `COUNT(DISTINCT user_id)` when calculating users from `events`.
3. Do not sum pre-aggregated daily metrics after one-to-many joins.
4. Use `LEFT JOIN` for nullable campaigns.
5. Filter `action_type = 'purchase'` before interpreting `action_value` as revenue.
6. Use event `app_version` for behaviour at event time and `app_version_at_install` for installation cohorts.
7. Use UTC when grouping timestamps by date.
8. Expect deliberate data-quality problems in FTU events.
9. Exclude test users through `dim_users.is_test_user` when appropriate.
10. Prefer derived facts when they answer the question; use `events` when event-level detail is required.

## Creation order

1. Run `create_tables/create_database.sql`.
2. Run `create_dim_country.R`.
3. Run `create_dim_platform.R`.
4. Run `create_dim_acquisition_channel.R`.
5. Run `create_dim_devices.R`.
6. Run `create_dim_campaign.R`.
7. Run `create_dim_users.R`.
8. Run `create_events.R`.
9. Run `create_tables/create_fact_tables.sql`.

`set_env.R` configures local connection variables and `test_connection.R` verifies the database connection.
