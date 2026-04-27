output "raw_database_name" { value = snowflake_database.raw.name }
output "staging_database_name" { value = snowflake_database.staging.name }
output "core_database_name" { value = snowflake_database.core.name }
output "marts_database_name" { value = snowflake_database.marts.name }
