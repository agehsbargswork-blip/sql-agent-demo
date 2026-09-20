# Create a SQL training set for the mobile-app database.
# The output contains exactly three columns: prompt, tags and sql_text.

# install.packages(c("DBI", "RPostgres", "dotenv"))

library(DBI)
library(RPostgres)
library(dotenv)

make_examples <- function(prompts, tags, sql_text, expected_n) {
  stopifnot(length(prompts) == expected_n)
  stopifnot(length(sql_text) == expected_n)

  data.frame(
    prompt = prompts,
    tags = rep(tags, expected_n),
    sql_text = sql_text,
    stringsAsFactors = FALSE
  )
}

training_set <- rbind(

  # 1. SELECT: 10 examples
  make_examples(
    prompts = c(
      "Show all countries and their country codes.",
      "Show all available mobile platforms.",
      "Show all device models and their platform IDs.",
      "Show all acquisition channels.",
      "Show all marketing campaigns.",
      "Show the installation details for every user.",
      "Show the main fields for every recorded event.",
      "Show daily activity records for every active user.",
      "Show the overall activity metrics for each day.",
      "Show the purchase metrics for each day."
    ),
    tags = "select",
    sql_text = c(
      "SELECT id, country_code, country_name FROM dim_country;",
      "SELECT id, platform_name FROM dim_platform;",
      "SELECT id, device_model, platform_id FROM dim_devices;",
      "SELECT id, channel_name FROM dim_acquisition_channel;",
      "SELECT id, campaign_name, acquisition_channel_id FROM dim_campaign;",
      "SELECT user_id, country_id, install_datetime, platform_id, device_id FROM dim_users;",
      "SELECT event_id, user_id, client_ts, action_type, action_value FROM events;",
      "SELECT activity_date, user_id, event_count, session_count, is_payer, payments FROM fact_user_daily_activity;",
      "SELECT activity_date, daily_active_users, event_count, session_count FROM fact_daily_activity;",
      "SELECT purchase_date, purchase_count, purchasing_users, total_revenue FROM fact_daily_purchases;"
    ),
    expected_n = 10
  ),

  # 2. SELECT and DISTINCT: 10 examples
  make_examples(
    prompts = c(
      "List the distinct countries represented by installed users.",
      "List the distinct platforms used by installed users.",
      "List the distinct devices used by installed users.",
      "List the distinct acquisition channels assigned to users.",
      "List the distinct campaign IDs assigned to users.",
      "List the distinct operating-system versions recorded for users.",
      "List the distinct app versions present at installation.",
      "List the distinct user languages.",
      "List the distinct event action types.",
      "List the distinct app versions recorded in events."
    ),
    tags = "select,distinct",
    sql_text = c(
      "SELECT DISTINCT country_id FROM dim_users;",
      "SELECT DISTINCT platform_id FROM dim_users;",
      "SELECT DISTINCT device_id FROM dim_users;",
      "SELECT DISTINCT acquisition_channel_id FROM dim_users;",
      "SELECT DISTINCT campaign_id FROM dim_users;",
      "SELECT DISTINCT os_version FROM dim_users;",
      "SELECT DISTINCT app_version_at_install FROM dim_users;",
      "SELECT DISTINCT language FROM dim_users;",
      "SELECT DISTINCT action_type FROM events;",
      "SELECT DISTINCT app_version FROM events;"
    ),
    expected_n = 10
  ),

  # 3. SELECT and WHERE: 10 examples
  make_examples(
    prompts = c(
      "Show the country record for the United States.",
      "Show the platform record for iOS.",
      "Show device models whose names start with iPhone.",
      "Show the Organic acquisition channel.",
      "Show campaigns whose names contain the word Campaign.",
      "Show users who are not test users.",
      "Show all purchase events.",
      "Show user-day records where the user was a payer.",
      "Show purchase days with more than 25 in total revenue.",
      "Show users who completed FTU."
    ),
    tags = "select,where",
    sql_text = c(
      "SELECT id, country_code, country_name FROM dim_country WHERE country_code = 'US';",
      "SELECT id, platform_name FROM dim_platform WHERE platform_name = 'iOS';",
      "SELECT id, device_model, platform_id FROM dim_devices WHERE device_model LIKE 'iPhone%';",
      "SELECT id, channel_name FROM dim_acquisition_channel WHERE channel_name = 'Organic';",
      "SELECT id, campaign_name, acquisition_channel_id FROM dim_campaign WHERE campaign_name LIKE '%Campaign%';",
      "SELECT user_id, install_datetime, platform_id FROM dim_users WHERE is_test_user = FALSE;",
      "SELECT event_id, user_id, client_ts, action_value FROM events WHERE action_type = 'purchase';",
      "SELECT activity_date, user_id, payments FROM fact_user_daily_activity WHERE is_payer = TRUE;",
      "SELECT purchase_date, total_revenue FROM fact_daily_purchases WHERE total_revenue > 25;",
      "SELECT user_id, first_completed_at, completion_seconds FROM fact_user_ftu WHERE ftu_completed = TRUE;"
    ),
    expected_n = 10
  ),

  # 4. SELECT and GROUP BY: 10 examples
  make_examples(
    prompts = c(
      "Count installed users by country ID.",
      "Count installed users by platform ID.",
      "Count installed users by device ID.",
      "Count installed users by acquisition channel ID.",
      "Count installed users by campaign ID.",
      "Count installed users by app version at installation.",
      "Count installed users by operating-system version.",
      "Count events by action type.",
      "Count events by app version.",
      "Count active users represented in the user daily activity table by date."
    ),
    tags = "select,groupby",
    sql_text = c(
      "SELECT country_id, COUNT(*) AS users FROM dim_users GROUP BY country_id;",
      "SELECT platform_id, COUNT(*) AS users FROM dim_users GROUP BY platform_id;",
      "SELECT device_id, COUNT(*) AS users FROM dim_users GROUP BY device_id;",
      "SELECT acquisition_channel_id, COUNT(*) AS users FROM dim_users GROUP BY acquisition_channel_id;",
      "SELECT campaign_id, COUNT(*) AS users FROM dim_users GROUP BY campaign_id;",
      "SELECT app_version_at_install, COUNT(*) AS users FROM dim_users GROUP BY app_version_at_install;",
      "SELECT os_version, COUNT(*) AS users FROM dim_users GROUP BY os_version;",
      "SELECT action_type, COUNT(*) AS events FROM events GROUP BY action_type;",
      "SELECT app_version, COUNT(*) AS events FROM events GROUP BY app_version;",
      "SELECT activity_date, COUNT(*) AS active_users FROM fact_user_daily_activity GROUP BY activity_date;"
    ),
    expected_n = 10
  ),

  # 5. SELECT, WHERE and GROUP BY: 10 examples
  make_examples(
    prompts = c(
      "Count non-test users by platform ID.",
      "Count users installed from April 2026 onward by country ID.",
      "Count paid-acquisition users by acquisition channel ID.",
      "Count purchase events by app version.",
      "Count schema-version-one events by action type.",
      "Calculate payer revenue by activity date.",
      "Count active days with more than one event for each user.",
      "Count completed FTU users by their number of FTU starts.",
      "Calculate monthly revenue for months containing purchases.",
      "Count events by UTC date from June 2026 onward."
    ),
    tags = "select,where,groupby",
    sql_text = c(
      "SELECT platform_id, COUNT(*) AS users FROM dim_users WHERE is_test_user = FALSE GROUP BY platform_id;",
      "SELECT country_id, COUNT(*) AS users FROM dim_users WHERE install_datetime >= '2026-04-01' GROUP BY country_id;",
      "SELECT acquisition_channel_id, COUNT(*) AS users FROM dim_users WHERE campaign_id IS NOT NULL GROUP BY acquisition_channel_id;",
      "SELECT app_version, COUNT(*) AS purchases FROM events WHERE action_type = 'purchase' GROUP BY app_version;",
      "SELECT action_type, COUNT(*) AS events FROM events WHERE event_schema_version = 1 GROUP BY action_type;",
      "SELECT activity_date, SUM(payments) AS revenue FROM fact_user_daily_activity WHERE is_payer = TRUE GROUP BY activity_date;",
      "SELECT user_id, COUNT(*) AS active_days FROM fact_user_daily_activity WHERE event_count > 1 GROUP BY user_id;",
      "SELECT started_count, COUNT(*) AS users FROM fact_user_ftu WHERE ftu_completed = TRUE GROUP BY started_count;",
      "SELECT DATE_TRUNC('month', purchase_date) AS purchase_month, SUM(total_revenue) AS revenue FROM fact_daily_purchases WHERE purchase_count > 0 GROUP BY DATE_TRUNC('month', purchase_date);",
      "SELECT (client_ts AT TIME ZONE 'UTC')::DATE AS event_date, COUNT(*) AS events FROM events WHERE client_ts >= '2026-06-01' GROUP BY (client_ts AT TIME ZONE 'UTC')::DATE;"
    ),
    expected_n = 10
  ),

  # 6. SELECT, GROUP BY and HAVING: 10 examples
  make_examples(
    prompts = c(
      "Show country IDs having more than one installed user.",
      "Show platform IDs having more than ten installed users.",
      "Show device IDs used by more than one user.",
      "Show acquisition channel IDs assigned to more than one user.",
      "Show action types having more than five events.",
      "Show users having more than two events.",
      "Show sessions containing more than one event.",
      "Show activity dates having positive total payments.",
      "Show purchase months having positive total revenue.",
      "Show FTU completion statuses represented by more than ten users."
    ),
    tags = "select,groupby,having",
    sql_text = c(
      "SELECT country_id, COUNT(*) AS users FROM dim_users GROUP BY country_id HAVING COUNT(*) > 1;",
      "SELECT platform_id, COUNT(*) AS users FROM dim_users GROUP BY platform_id HAVING COUNT(*) > 10;",
      "SELECT device_id, COUNT(*) AS users FROM dim_users GROUP BY device_id HAVING COUNT(*) > 1;",
      "SELECT acquisition_channel_id, COUNT(*) AS users FROM dim_users GROUP BY acquisition_channel_id HAVING COUNT(*) > 1;",
      "SELECT action_type, COUNT(*) AS events FROM events GROUP BY action_type HAVING COUNT(*) > 5;",
      "SELECT user_id, COUNT(*) AS events FROM events GROUP BY user_id HAVING COUNT(*) > 2;",
      "SELECT session_id, COUNT(*) AS events FROM events GROUP BY session_id HAVING COUNT(*) > 1;",
      "SELECT activity_date, SUM(payments) AS revenue FROM fact_user_daily_activity GROUP BY activity_date HAVING SUM(payments) > 0;",
      "SELECT DATE_TRUNC('month', purchase_date) AS purchase_month, SUM(total_revenue) AS revenue FROM fact_daily_purchases GROUP BY DATE_TRUNC('month', purchase_date) HAVING SUM(total_revenue) > 0;",
      "SELECT ftu_completed, COUNT(*) AS users FROM fact_user_ftu GROUP BY ftu_completed HAVING COUNT(*) > 10;"
    ),
    expected_n = 10
  ),

  # 7. SELECT and JOIN: 10 examples
  make_examples(
    prompts = c(
      "Show every user with the name of their installation country.",
      "Show every user with their platform name.",
      "Show every user with their device model.",
      "Show every user with their acquisition channel name.",
      "Show every user with their campaign name, including organic users.",
      "Show every device with its platform name.",
      "Show every campaign with its acquisition channel name.",
      "Show every event with the user's installation timestamp.",
      "Show every user daily activity record with the user's installation country ID.",
      "Show every user's FTU record with their app version at installation."
    ),
    tags = "select,join",
    sql_text = c(
      "SELECT u.user_id, c.country_name FROM dim_users u JOIN dim_country c ON u.country_id = c.id;",
      "SELECT u.user_id, p.platform_name FROM dim_users u JOIN dim_platform p ON u.platform_id = p.id;",
      "SELECT u.user_id, d.device_model FROM dim_users u JOIN dim_devices d ON u.device_id = d.id AND u.platform_id = d.platform_id;",
      "SELECT u.user_id, a.channel_name FROM dim_users u JOIN dim_acquisition_channel a ON u.acquisition_channel_id = a.id;",
      "SELECT u.user_id, c.campaign_name FROM dim_users u LEFT JOIN dim_campaign c ON u.campaign_id = c.id;",
      "SELECT d.device_model, p.platform_name FROM dim_devices d JOIN dim_platform p ON d.platform_id = p.id;",
      "SELECT c.campaign_name, a.channel_name FROM dim_campaign c JOIN dim_acquisition_channel a ON c.acquisition_channel_id = a.id;",
      "SELECT e.event_id, e.action_type, u.install_datetime FROM events e JOIN dim_users u ON e.user_id = u.user_id;",
      "SELECT f.activity_date, f.user_id, f.event_count, u.country_id FROM fact_user_daily_activity f JOIN dim_users u ON f.user_id = u.user_id;",
      "SELECT f.user_id, f.ftu_completed, u.app_version_at_install FROM fact_user_ftu f JOIN dim_users u ON f.user_id = u.user_id;"
    ),
    expected_n = 10
  ),

  # 8. SELECT, JOIN and WHERE: 10 examples
  make_examples(
    prompts = c(
      "Show users installed in the United States.",
      "Show users installed on Android.",
      "Show users installed on an iPhone.",
      "Show organically acquired users.",
      "Show users acquired through the Brand Keywords campaign.",
      "Show purchase events generated by non-test users.",
      "Show events recorded on iOS.",
      "Show non-test payer activity records.",
      "Show non-test users who completed FTU.",
      "Show campaigns belonging to Google Ads."
    ),
    tags = "select,join,where",
    sql_text = c(
      "SELECT u.user_id, c.country_name FROM dim_users u JOIN dim_country c ON u.country_id = c.id WHERE c.country_code = 'US';",
      "SELECT u.user_id, p.platform_name FROM dim_users u JOIN dim_platform p ON u.platform_id = p.id WHERE p.platform_name = 'Android';",
      "SELECT u.user_id, d.device_model FROM dim_users u JOIN dim_devices d ON u.device_id = d.id AND u.platform_id = d.platform_id WHERE d.device_model LIKE 'iPhone%';",
      "SELECT u.user_id, a.channel_name FROM dim_users u JOIN dim_acquisition_channel a ON u.acquisition_channel_id = a.id WHERE a.channel_name = 'Organic';",
      "SELECT u.user_id, c.campaign_name FROM dim_users u JOIN dim_campaign c ON u.campaign_id = c.id WHERE c.campaign_name = 'Brand Keywords';",
      "SELECT e.event_id, e.user_id, e.action_value FROM events e JOIN dim_users u ON e.user_id = u.user_id WHERE e.action_type = 'purchase' AND u.is_test_user = FALSE;",
      "SELECT e.event_id, e.action_type, p.platform_name FROM events e JOIN dim_platform p ON e.platform_id = p.id WHERE p.platform_name = 'iOS';",
      "SELECT f.activity_date, f.user_id, f.payments FROM fact_user_daily_activity f JOIN dim_users u ON f.user_id = u.user_id WHERE f.is_payer = TRUE AND u.is_test_user = FALSE;",
      "SELECT f.user_id, f.first_completed_at FROM fact_user_ftu f JOIN dim_users u ON f.user_id = u.user_id WHERE f.ftu_completed = TRUE AND u.is_test_user = FALSE;",
      "SELECT c.campaign_name, a.channel_name FROM dim_campaign c JOIN dim_acquisition_channel a ON c.acquisition_channel_id = a.id WHERE a.channel_name = 'Google Ads';"
    ),
    expected_n = 10
  ),

  # 9. SELECT, JOIN and WHERE using more than two tables: 10 examples
  make_examples(
    prompts = c(
      "Show Android users installed in the United States.",
      "Show Android users with their device models.",
      "Show users acquired through a named paid campaign.",
      "Show purchase events with the user's country.",
      "Show FTU-start events with the user's platform.",
      "Show purchase events with their device and platform names.",
      "Show payer activity records for users in the United States.",
      "Show completed FTU users with their country.",
      "Show non-test users with their country and acquisition channel.",
      "Show campaign-attributed purchase events with campaign names."
    ),
    tags = "select,join,where,multi_table",
    sql_text = c(
      "SELECT u.user_id, c.country_name, p.platform_name FROM dim_users u JOIN dim_country c ON u.country_id = c.id JOIN dim_platform p ON u.platform_id = p.id WHERE c.country_code = 'US' AND p.platform_name = 'Android';",
      "SELECT u.user_id, d.device_model, p.platform_name FROM dim_users u JOIN dim_devices d ON u.device_id = d.id AND u.platform_id = d.platform_id JOIN dim_platform p ON d.platform_id = p.id WHERE p.platform_name = 'Android';",
      "SELECT u.user_id, a.channel_name, c.campaign_name FROM dim_users u JOIN dim_acquisition_channel a ON u.acquisition_channel_id = a.id JOIN dim_campaign c ON u.campaign_id = c.id WHERE c.campaign_name = 'Global App Campaign';",
      "SELECT e.event_id, e.action_value, c.country_name FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE e.action_type = 'purchase';",
      "SELECT e.event_id, e.client_ts, p.platform_name FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_platform p ON u.platform_id = p.id WHERE e.action_type = 'ftu_started';",
      "SELECT e.event_id, d.device_model, p.platform_name FROM events e JOIN dim_devices d ON e.device_id = d.id AND e.platform_id = d.platform_id JOIN dim_platform p ON d.platform_id = p.id WHERE e.action_type = 'purchase';",
      "SELECT f.activity_date, f.user_id, f.payments, c.country_name FROM fact_user_daily_activity f JOIN dim_users u ON f.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE f.is_payer = TRUE AND c.country_code = 'US';",
      "SELECT f.user_id, f.first_completed_at, c.country_name FROM fact_user_ftu f JOIN dim_users u ON f.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE f.ftu_completed = TRUE;",
      "SELECT u.user_id, c.country_name, a.channel_name FROM dim_users u JOIN dim_country c ON u.country_id = c.id JOIN dim_acquisition_channel a ON u.acquisition_channel_id = a.id WHERE u.is_test_user = FALSE;",
      "SELECT e.event_id, e.action_value, c.campaign_name FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_campaign c ON u.campaign_id = c.id WHERE e.action_type = 'purchase' AND u.campaign_id IS NOT NULL;"
    ),
    expected_n = 10
  ),

  # 10. SELECT, JOIN, WHERE and GROUP BY using more than two tables: 10 examples
  make_examples(
    prompts = c(
      "Calculate purchase revenue by user country.",
      "Count non-test-user events by platform.",
      "Calculate DAU by date and country for non-test users.",
      "Calculate purchase revenue by acquisition channel.",
      "Calculate purchase revenue by campaign.",
      "Count non-test installations by country and platform.",
      "Count purchases by device model and platform.",
      "Count FTU completers by country.",
      "Calculate payer revenue by date and platform.",
      "Count distinct users opening the app by date, country and platform."
    ),
    tags = "select,join,where,groupby,multi_table",
    sql_text = c(
      "SELECT c.country_name, SUM(e.action_value) AS revenue FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE e.action_type = 'purchase' GROUP BY c.country_name;",
      "SELECT p.platform_name, COUNT(*) AS events FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_platform p ON u.platform_id = p.id WHERE u.is_test_user = FALSE GROUP BY p.platform_name;",
      "SELECT f.activity_date, c.country_name, COUNT(*) AS daily_active_users FROM fact_user_daily_activity f JOIN dim_users u ON f.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE u.is_test_user = FALSE GROUP BY f.activity_date, c.country_name;",
      "SELECT a.channel_name, SUM(e.action_value) AS revenue FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_acquisition_channel a ON u.acquisition_channel_id = a.id WHERE e.action_type = 'purchase' GROUP BY a.channel_name;",
      "SELECT c.campaign_name, SUM(e.action_value) AS revenue FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_campaign c ON u.campaign_id = c.id WHERE e.action_type = 'purchase' GROUP BY c.campaign_name;",
      "SELECT c.country_name, p.platform_name, COUNT(*) AS installs FROM dim_users u JOIN dim_country c ON u.country_id = c.id JOIN dim_platform p ON u.platform_id = p.id WHERE u.is_test_user = FALSE GROUP BY c.country_name, p.platform_name;",
      "SELECT p.platform_name, d.device_model, COUNT(*) AS purchases FROM events e JOIN dim_devices d ON e.device_id = d.id AND e.platform_id = d.platform_id JOIN dim_platform p ON d.platform_id = p.id WHERE e.action_type = 'purchase' GROUP BY p.platform_name, d.device_model;",
      "SELECT c.country_name, COUNT(*) AS completed_users FROM fact_user_ftu f JOIN dim_users u ON f.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id WHERE f.ftu_completed = TRUE GROUP BY c.country_name;",
      "SELECT f.activity_date, p.platform_name, SUM(f.payments) AS revenue FROM fact_user_daily_activity f JOIN dim_users u ON f.user_id = u.user_id JOIN dim_platform p ON u.platform_id = p.id WHERE f.is_payer = TRUE GROUP BY f.activity_date, p.platform_name;",
      "SELECT (e.client_ts AT TIME ZONE 'UTC')::DATE AS activity_date, c.country_name, p.platform_name, COUNT(DISTINCT e.user_id) AS users FROM events e JOIN dim_users u ON e.user_id = u.user_id JOIN dim_country c ON u.country_id = c.id JOIN dim_platform p ON u.platform_id = p.id WHERE e.action_type = 'open_app' GROUP BY (e.client_ts AT TIME ZONE 'UTC')::DATE, c.country_name, p.platform_name;"
    ),
    expected_n = 10
  ),

  # 11. ROW_NUMBER(): 5 examples
  make_examples(
    prompts = c(
      "Number users in installation order.",
      "Number each user's events chronologically.",
      "Number each user's purchases chronologically.",
      "Number device models alphabetically within each platform.",
      "Show the latest event for each user."
    ),
    tags = "select,windowing,row_number",
    sql_text = c(
      "SELECT user_id, install_datetime, ROW_NUMBER() OVER (ORDER BY install_datetime, user_id) AS install_number FROM dim_users;",
      "SELECT user_id, event_id, client_ts, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY client_ts, event_id) AS event_number FROM events;",
      "SELECT user_id, event_id, client_ts, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY client_ts, event_id) AS purchase_number FROM events WHERE action_type = 'purchase';",
      "SELECT platform_id, device_model, ROW_NUMBER() OVER (PARTITION BY platform_id ORDER BY device_model) AS device_number FROM dim_devices;",
      "SELECT user_id, event_id, client_ts, action_type FROM (SELECT e.*, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY client_ts DESC, event_id DESC) AS row_number FROM events e) ranked_events WHERE row_number = 1;"
    ),
    expected_n = 5
  ),

  # 12. SUM() OVER: 5 examples
  make_examples(
    prompts = c(
      "Calculate cumulative purchase revenue by date.",
      "Calculate the running sum of daily active-user counts.",
      "Calculate each user's running payment total by activity date.",
      "Show every event with the total number of events generated by its user.",
      "Calculate cumulative installations by installation date."
    ),
    tags = "select,windowing,sum_over",
    sql_text = c(
      "SELECT purchase_date, total_revenue, SUM(total_revenue) OVER (ORDER BY purchase_date) AS cumulative_revenue FROM fact_daily_purchases;",
      "SELECT activity_date, daily_active_users, SUM(daily_active_users) OVER (ORDER BY activity_date) AS running_dau_total FROM fact_daily_activity;",
      "SELECT user_id, activity_date, payments, SUM(payments) OVER (PARTITION BY user_id ORDER BY activity_date) AS cumulative_payments FROM fact_user_daily_activity;",
      "SELECT event_id, user_id, action_type, SUM(1) OVER (PARTITION BY user_id) AS user_event_count FROM events;",
      "SELECT install_date, installs, SUM(installs) OVER (ORDER BY install_date) AS cumulative_installs FROM (SELECT (install_datetime AT TIME ZONE 'UTC')::DATE AS install_date, COUNT(*) AS installs FROM dim_users GROUP BY (install_datetime AT TIME ZONE 'UTC')::DATE) daily_installs;"
    ),
    expected_n = 5
  ),

  # 13. RANK() OVER: 5 examples
  make_examples(
    prompts = c(
      "Rank activity dates from highest to lowest DAU.",
      "Rank purchase dates from highest to lowest revenue.",
      "Rank countries by number of installed users.",
      "Rank device models by number of installed users.",
      "Rank users by their total payments."
    ),
    tags = "select,windowing,rank",
    sql_text = c(
      "SELECT activity_date, daily_active_users, RANK() OVER (ORDER BY daily_active_users DESC) AS dau_rank FROM fact_daily_activity;",
      "SELECT purchase_date, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank FROM fact_daily_purchases;",
      "SELECT country_id, users, RANK() OVER (ORDER BY users DESC) AS country_rank FROM (SELECT country_id, COUNT(*) AS users FROM dim_users GROUP BY country_id) country_counts;",
      "SELECT device_id, users, RANK() OVER (ORDER BY users DESC) AS device_rank FROM (SELECT device_id, COUNT(*) AS users FROM dim_users GROUP BY device_id) device_counts;",
      "SELECT user_id, total_payments, RANK() OVER (ORDER BY total_payments DESC) AS payer_rank FROM (SELECT user_id, SUM(payments) AS total_payments FROM fact_user_daily_activity GROUP BY user_id) user_payments;"
    ),
    expected_n = 5
  )
)

stopifnot(nrow(training_set) == 115)
stopifnot(
  identical(
    names(training_set),
    c("prompt", "tags", "sql_text")
  )
)

# Write Table

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

DBI::dbExecute(
  connection,
  "
  CREATE TABLE IF NOT EXISTS training_set (
      prompt TEXT NOT NULL,
      tags TEXT NOT NULL,
      sql_text TEXT NOT NULL
  );
  "
)

DBI::dbExecute(
  connection,
  "DELETE FROM training_set;"
)

DBI::dbWriteTable(
  connection,
  DBI::Id(schema = "public", table = "training_set"),
  training_set,
  append = TRUE,
  row.names = FALSE
)

# Test

result <- DBI::dbGetQuery(
  connection,
  "
  SELECT
      tags,
      COUNT(*) AS examples
  FROM training_set
  GROUP BY tags
  ORDER BY tags;
  "
)

print(result)
cat("Created", nrow(training_set), "training examples.\n")

# Cleanup

DBI::dbDisconnect(connection)
