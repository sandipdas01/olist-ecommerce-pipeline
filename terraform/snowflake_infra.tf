terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
  required_version = ">= 1.5.0"
}

provider "snowflake" {
  account  = var.snowflake_account
  username = var.snowflake_username
  password = var.snowflake_password
  role     = "SYSADMIN"
}

locals {
  db_raw     = upper("OLIST_${var.env}_RAW")
  db_staging = upper("OLIST_${var.env}_STAGING")
  db_core    = upper("OLIST_${var.env}_CORE")
  db_marts   = upper("OLIST_${var.env}_MARTS")
}

resource "snowflake_warehouse" "loader_wh" {
  name                = "OLIST_LOADER_WH"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_warehouse" "transform_wh" {
  name                = "OLIST_TRANSFORM_WH"
  warehouse_size      = "SMALL"
  auto_suspend        = 120
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_warehouse" "reporting_wh" {
  name                = "OLIST_REPORTING_WH"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_database" "raw" {
  name = local.db_raw
}

resource "snowflake_database" "staging" {
  name = local.db_staging
}

resource "snowflake_database" "core" {
  name = local.db_core
}

resource "snowflake_database" "marts" {
  name = local.db_marts
}

resource "snowflake_schema" "raw_olist" {
  database = snowflake_database.raw.name
  name     = "OLIST"
}

resource "snowflake_file_format" "csv_default" {
  name     = "OLIST_CSV_FORMAT"
  database = snowflake_database.raw.name
  schema   = snowflake_schema.raw_olist.name

  format_type = "CSV"

  field_delimiter                = ","
  skip_header                    = 1
  field_optionally_enclosed_by   = "\""
  null_if                        = ["NULL", "null", ""]
  empty_field_as_null            = true
  trim_space                     = true
  error_on_column_count_mismatch = false
}