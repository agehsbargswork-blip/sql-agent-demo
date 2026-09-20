# install.packages(c("DBI", "RPostgres", "dotenv", "uuid", "jsonlite"))

# Create Table

library(DBI)
library(RPostgres)
library(dotenv)
library(uuid)
library(jsonlite)

set.seed(123)

dotenv::load_dot_env()

connection <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("PGHOST"),
  port = as.integer(Sys.getenv("PGPORT")),
  dbname = Sys.getenv("PGDATABASE"),
  user = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD"),
  sslmode = "require"
)

users <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      user_id,
      platform_id,
      device_id,
      install_datetime,
      app_version_at_install
  FROM dim_users
  ORDER BY user_id;
  "
)

events_per_user <- sample(
  1:5,
  nrow(users),
  replace = TRUE
)

user_rows <- rep(
  seq_len(nrow(users)),
  times = events_per_user
)

event_users <- users[user_rows, ]

number_of_events <- nrow(event_users)

session_ids <- uuid::UUIDgenerate(n = nrow(users))

session_id <- rep(
  session_ids,
  times = events_per_user
)

action_type <- sample(
  c(
    "open_app",
    "lobby_loaded",
    "ftu_started",
    "ftu_completed",
    "purchase"
  ),
  number_of_events,
  replace = TRUE
)

action_subtype <- rep(NA_character_, number_of_events)
action_json <- rep(NA_character_, number_of_events)
action_value <- rep(NA_real_, number_of_events)

for (event in seq_len(number_of_events)) {

  if (action_type[event] %in% c("ftu_started", "ftu_completed")) {

    action_subtype[event] <- "standard_ftu"

    action_json[event] <- as.character(
      jsonlite::toJSON(
        list(
          type = "standard",
          progress = sample(c("simple", "complex"), 1),
          theme = sample(c("sea", "creatures"), 1)
        ),
        auto_unbox = TRUE
      )
    )
  }

  if (action_type[event] == "purchase") {

    action_subtype[event] <- "diamonds"

    action_json[event] <- as.character(
      jsonlite::toJSON(
        list(
          type = "diamonds",
          location = "shop",
          amount = sample(c(100, 200, 1000), 1)
        ),
        auto_unbox = TRUE
      )
    )

    action_value[event] <- sample(c(5, 10, 15), 1)
  }
}

event_end <- as.POSIXct(
  "2026-08-31 23:59:59",
  tz = "UTC"
)

client_ts <- as.POSIXct(
  runif(
    number_of_events,
    min = as.numeric(event_users$install_datetime),
    max = as.numeric(event_end)
  ),
  origin = "1970-01-01",
  tz = "UTC"
)

events <- data.frame(
  event_id = uuid::UUIDgenerate(n = number_of_events),
  user_id = event_users$user_id,
  session_id = session_id,
  platform_id = event_users$platform_id,
  device_id = event_users$device_id,
  client_ts = client_ts,
  server_ts = client_ts,
  app_version = event_users$app_version_at_install,
  event_schema_version = 1L,
  action_type = action_type,
  action_subtype = action_subtype,
  action_json = action_json,
  action_value = action_value
)

head(events)

# Write Table

DBI::dbExecute(
  connection,
  "DELETE FROM events;"
)

DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "events"),
  events,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "
  SELECT *
  FROM events
  ORDER BY client_ts
  LIMIT 20;
  "
)

result

# Cleanup

DBI::dbDisconnect(connection)
