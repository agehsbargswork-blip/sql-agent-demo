library(dotenv)
file.edit(".env")
# 
# File will open
# Put there info from "Session Pooler"
# 
# It can look like this:
# 
# PGHOST=aws-1-eu-west-1.pooler.supabase.com
# PGPORT=XXXX
# PGDATABASE=postgres
# PGUSER=postgres.XXX
# PGPASSWORD=<password>

getwd()
dotenv::load_dot_env()
