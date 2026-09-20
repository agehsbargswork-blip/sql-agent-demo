# Create Table

dim_acquisition_channel <- data.frame(
  id = 1:13,
  channel_name = c(
    "Organic",
    "Apple Search Ads",
    "Google Ads",
    "Meta Ads",
    "TikTok Ads",
    "AppLovin",
    "Unity Ads",
    "Cross-promotion",
    "Influencer",
    "Affiliate",
    "Referral",
    "Other",
    "Unknown"
  )
)

head(dim_acquisition_channel)

# Write Table

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


dbExecute(
  connection,
  "DELETE FROM dim_acquisition_channel;"
)


DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_acquisition_channel"),
  dim_acquisition_channel,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "SELECT * FROM dim_acquisition_channel;"
)

head(result)

# Cleanup

dbDisconnect(connection)
