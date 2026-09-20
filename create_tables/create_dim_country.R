# install.packages("countrycode")

# Create Table

library(countrycode)

dim_country <- codelist |>
  subset(!is.na(iso2c), select = c(iso2c, country.name.en)) |>
  unique()

names(dim_country) <- c("country_code", "country_name")

dim_country <- dim_country[order(dim_country$country_name), ]
dim_country$id <- seq_len(nrow(dim_country))

dim_country <- dim_country[, c("id", "country_code", "country_name")]
dim_country <- as.data.frame(dim_country)

head(dim_country)

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
  "DELETE FROM dim_country;"
)


DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "dim_country"),
  dim_country,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "SELECT * FROM dim_country;"
)

head(result)

# Cleanup

dbDisconnect(connection)
