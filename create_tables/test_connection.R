# install.packages(c("DBI", "RPostgres", "dotenv"))

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

result <- DBI::dbGetQuery(
  connection,
  "SELECT * FROM dim_country;"
)

result
