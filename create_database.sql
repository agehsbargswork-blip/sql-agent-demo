/*
Schema description for LLMs:

dim_users contains one row per mobile-app user and records attributes at
installation.

dim_country maps countries to their ISO codes and names.

dim_platform maps mobile platforms such as iOS and Android.

dim_devices maps device models to their associated platforms.

dim_acquisition_channel contains user-acquisition sources.

dim_campaign contains marketing campaigns and their acquisition channels.

events contains mobile-app activity. Each row represents one user action.
client_ts is when the device recorded the event; server_ts is when the server
received it. session_id groups related events. action_json contains optional
action-specific attributes, while action_value contains an optional numeric value.

IDs are supplied explicitly when importing CSV files.

Composite foreign keys ensure that:
- A device and platform combination is valid.
- A campaign belongs to the specified acquisition channel.
*/

CREATE TABLE dim_country (
    id INTEGER PRIMARY KEY,
    country_code CHAR(2) NOT NULL UNIQUE,
    country_name TEXT NOT NULL
);

CREATE TABLE dim_platform (
    id INTEGER PRIMARY KEY,
    platform_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_acquisition_channel (
    id INTEGER PRIMARY KEY,
    channel_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dim_campaign (
    id INTEGER PRIMARY KEY,
    campaign_name TEXT NOT NULL,
    acquisition_channel_id INTEGER NOT NULL
        REFERENCES dim_acquisition_channel(id),

    UNIQUE (id, acquisition_channel_id)
);

CREATE TABLE dim_devices (
    id INTEGER PRIMARY KEY,
    device_model TEXT NOT NULL,
    platform_id INTEGER NOT NULL
        REFERENCES dim_platform(id),

    UNIQUE (device_model, platform_id),
    UNIQUE (id, platform_id)
);

CREATE TABLE dim_users (
    user_id BIGINT PRIMARY KEY,
    country_id INTEGER NOT NULL
        REFERENCES dim_country(id),
    install_datetime TIMESTAMPTZ NOT NULL,
    platform_id INTEGER NOT NULL
        REFERENCES dim_platform(id),
    device_id INTEGER NOT NULL,
    acquisition_channel_id INTEGER NOT NULL
        REFERENCES dim_acquisition_channel(id),
    campaign_id INTEGER,
    os_version TEXT NOT NULL,
    app_version_at_install TEXT NOT NULL,
    language CHAR(2),
    is_test_user BOOLEAN NOT NULL DEFAULT FALSE,

    FOREIGN KEY (device_id, platform_id)
        REFERENCES dim_devices(id, platform_id),

    FOREIGN KEY (campaign_id, acquisition_channel_id)
        REFERENCES dim_campaign(id, acquisition_channel_id)
);

CREATE TABLE events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL
        REFERENCES dim_users(user_id),
    session_id UUID NOT NULL,
    platform_id INTEGER NOT NULL
        REFERENCES dim_platform(id),
    device_id INTEGER NOT NULL,
    client_ts TIMESTAMPTZ NOT NULL,
    server_ts TIMESTAMPTZ NOT NULL,
    app_version TEXT NOT NULL,
    event_schema_version INTEGER NOT NULL DEFAULT 1,
    action_type TEXT NOT NULL,
    action_subtype TEXT,
    action_json JSONB,
    action_value NUMERIC,

    FOREIGN KEY (device_id, platform_id)
        REFERENCES dim_devices(id, platform_id)
);

CREATE INDEX idx_events_user_client_ts
    ON events (user_id, client_ts);

CREATE INDEX idx_events_action_type
    ON events (action_type);

CREATE INDEX idx_events_server_ts
    ON events (server_ts);
