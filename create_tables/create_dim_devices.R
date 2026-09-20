# Create Table

library(DBI)
library(RPostgres)
library(dotenv)

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

platforms <- DBI::dbGetQuery(
  connection,
  "SELECT id, platform_name FROM dim_platform;"
)

devices <- data.frame(
  device_model = c(
    "iPhone SE",
    "iPhone 11",
    "iPhone 12",
    "iPhone 13",
    "iPhone 14",
    "iPhone 15",
    "iPhone 16",
    "iPad",
    "Samsung Galaxy A54",
    "Samsung Galaxy S21",
    "Samsung Galaxy S22",
    "Samsung Galaxy S23",
    "Samsung Galaxy S24",
    "Google Pixel 7",
    "Google Pixel 8",
    "Google Pixel 9",
    "Xiaomi Redmi Note 12",
    "OnePlus 12",
    "Fire 7",
    "Fire HD 8",
    "Fire HD 10",
    "Fire Max 11",
    "Other Device",
    "Unknown Device"
  ),
  platform_name = c(
    rep("iOS", 8),
    rep("Android", 10),
    rep("Amazon", 4),
    rep("Other", 2)
  )
)

devices$platform_id <- platforms$id[
  match(devices$platform_name, platforms$platform_name)
]

stopifnot(!any(is.na(devices$platform_id)))

dim_devices <- data.frame(
  id = seq_len(nrow(devices)),
  device_model = devices$device_model,
  platform_id = devices$platform_id
)

head(dim_devices)

# Write Table

DBI::dbExecute(
  connection,
  "DELETE FROM dim_devices;"
)

DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_devices"),
  dim_devices,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      d.id,
      d.device_model,
      p.platform_name
  FROM dim_devices d
  JOIN dim_platform p
      ON d.platform_id = p.id
  ORDER BY d.id;
  "
)

head(result)

# Cleanup

DBI::dbDisconnect(connection)
