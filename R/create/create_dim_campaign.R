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

channels <- DBI::dbGetQuery(
  connection,
  "SELECT id, channel_name FROM dim_acquisition_channel;"
)

campaigns <- data.frame(
  campaign_name = c(
    "Brand Keywords",
    "Competitor Keywords",
    "Global App Campaign",
    "US High-Value Users",
    "Broad Acquisition",
    "Payer Lookalikes",
    "Gameplay Creatives",
    "Creator Ads",
    "Video Campaign",
    "Playable Ads",
    "Rewarded Video Campaign",
    "Portfolio Cross-Promotion",
    "Creator Launch Campaign",
    "Partner Network Campaign",
    "Invite Friends Campaign",
    "Experimental Campaign"
  ),
  channel_name = c(
    "Apple Search Ads",
    "Apple Search Ads",
    "Google Ads",
    "Google Ads",
    "Meta Ads",
    "Meta Ads",
    "TikTok Ads",
    "TikTok Ads",
    "AppLovin",
    "AppLovin",
    "Unity Ads",
    "Cross-promotion",
    "Influencer",
    "Affiliate",
    "Referral",
    "Other"
  )
)

campaigns$acquisition_channel_id <- channels$id[
  match(campaigns$channel_name, channels$channel_name)
]

stopifnot(!any(is.na(campaigns$acquisition_channel_id)))

dim_campaign <- data.frame(
  id = seq_len(nrow(campaigns)),
  campaign_name = campaigns$campaign_name,
  acquisition_channel_id = campaigns$acquisition_channel_id
)

head(dim_campaign)

# Write Table

DBI::dbExecute(
  connection,
  "DELETE FROM dim_campaign;"
)

DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_campaign"),
  dim_campaign,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      c.id,
      c.campaign_name,
      a.channel_name
  FROM dim_campaign c
  JOIN dim_acquisition_channel a
      ON c.acquisition_channel_id = a.id
  ORDER BY c.id;
  "
)

head(result)

# Cleanup

DBI::dbDisconnect(connection)
