# Create Table

library(DBI)
library(RPostgres)
library(dotenv)

set.seed(123)

sample_one <- function(values) {
  values[sample.int(length(values), 1)]
}

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

countries <- DBI::dbGetQuery(
  connection,
  "SELECT id, country_code FROM dim_country;"
)

platforms <- DBI::dbGetQuery(
  connection,
  "SELECT id, platform_name FROM dim_platform;"
)

devices <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      d.id,
      p.platform_name
  FROM dim_devices d
  JOIN dim_platform p
      ON d.platform_id = p.id;
  "
)

channels <- DBI::dbGetQuery(
  connection,
  "SELECT id, channel_name FROM dim_acquisition_channel;"
)

campaigns <- DBI::dbGetQuery(
  connection,
  "SELECT id, acquisition_channel_id FROM dim_campaign;"
)

number_of_users <- 124 + 98

platform_name <- sample(
  c(rep("Android", 124), rep("iOS", 98))
)

platform_id <- platforms$id[
  match(platform_name, platforms$platform_name)
]

stopifnot(!any(is.na(platform_id)))

device_id <- vapply(
  platform_name,
  function(selected_platform) {
    sample_one(
      devices$id[devices$platform_name == selected_platform]
    )
  },
  integer(1)
)

organic_channel_id <- channels$id[
  channels$channel_name == "Organic"
]

stopifnot(length(organic_channel_id) == 1)

paid_channel_ids <- unique(campaigns$acquisition_channel_id)

is_paid <- runif(number_of_users) < 0.20

acquisition_channel_id <- rep(
  organic_channel_id,
  number_of_users
)

campaign_id <- rep(
  NA_integer_,
  number_of_users
)

for (user in which(is_paid)) {
  selected_channel <- sample_one(paid_channel_ids)

  acquisition_channel_id[user] <- selected_channel

  campaign_id[user] <- sample_one(
    campaigns$id[
      campaigns$acquisition_channel_id == selected_channel
    ]
  )
}

us_country_id <- countries$id[
  countries$country_code == "US"
]

stopifnot(length(us_country_id) == 1)

non_us_country_ids <- countries$id[
  countries$country_code != "US"
]

country_id <- ifelse(
  runif(number_of_users) < 0.60,
  us_country_id,
  sample(
    non_us_country_ids,
    number_of_users,
    replace = TRUE
  )
)

install_start <- as.POSIXct(
  "2026-01-01 00:00:00",
  tz = "UTC"
)

install_end <- as.POSIXct(
  "2026-08-01 00:00:00",
  tz = "UTC"
)

install_datetime <- as.POSIXct(
  runif(
    number_of_users,
    min = as.numeric(install_start),
    max = as.numeric(install_end)
  ),
  origin = "1970-01-01",
  tz = "UTC"
)

os_version <- ifelse(
  platform_name == "Android",
  sample(
    c("13", "14", "15"),
    number_of_users,
    replace = TRUE
  ),
  sample(
    c("17", "18"),
    number_of_users,
    replace = TRUE
  )
)

dim_users <- data.frame(
  user_id = seq_len(number_of_users),
  country_id = country_id,
  install_datetime = install_datetime,
  platform_id = platform_id,
  device_id = device_id,
  acquisition_channel_id = acquisition_channel_id,
  campaign_id = campaign_id,
  os_version = os_version,
  app_version_at_install = sample(
    c("1.0.1", "2.0.1"),
    number_of_users,
    replace = TRUE,
    prob = c(0.50, 0.50)
  ),
  language = rep("EN", number_of_users),
  is_test_user = sample(
    c(FALSE, TRUE),
    number_of_users,
    replace = TRUE,
    prob = c(0.95, 0.05)
  )
)

head(dim_users)

# Write Table

DBI::dbExecute(
  connection,
  "DELETE FROM dim_users;"
)

DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_users"),
  dim_users,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      u.user_id,
      c.country_code,
      u.install_datetime,
      p.platform_name,
      d.device_model,
      a.channel_name,
      cp.campaign_name,
      u.os_version,
      u.app_version_at_install,
      u.language,
      u.is_test_user
  FROM dim_users u
  JOIN dim_country c
      ON u.country_id = c.id
  JOIN dim_platform p
      ON u.platform_id = p.id
  JOIN dim_devices d
      ON u.device_id = d.id
  JOIN dim_acquisition_channel a
      ON u.acquisition_channel_id = a.id
  LEFT JOIN dim_campaign cp
      ON u.campaign_id = cp.id
  ORDER BY u.user_id;
  "
)

head(result)

# Cleanup

DBI::dbDisconnect(connection)
