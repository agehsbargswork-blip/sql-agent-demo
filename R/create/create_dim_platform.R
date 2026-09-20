# Create Table

dim_platform <- data.frame(
  id = 1:4,
  platform_name = c("iOS", "Android", "Amazon", "Other")
)

head(dim_platform)

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
  "DELETE FROM dim_platform;"
)


DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_platform"),
  dim_platform,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "SELECT * FROM dim_platform;"
)

head(result)

# Cleanup

dbDisconnect(connection)
