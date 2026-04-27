# olist-ecommerce-pipeline

This project builds an end-to-end data pipeline for the Olist e-commerce dataset. It automates raw data ingestion into Snowflake with Apache Airflow, transforms the data with dbt into staging, core, and mart layers, and supports analytics in Power BI.

## Key Tech Stack
- Orchestration: Apache Airflow
- Warehouse: Snowflake
- Transformation: dbt
- Visualization: Power BI
- Language: Python, SQL

## Pipeline Architecture
- Ingestion: Python-based Airflow tasks truncate raw tables and ingest CSV files into Snowflake stages.
- Transformation: dbt models organize the data into staging, core, and mart layers.
- Quality: Airflow checks and dbt tests validate data integrity.

## How to Run
1. Clone this repository.
2. Set your environment variables for Snowflake credentials.
3. Start the Airflow environment with:
   ```bash
   docker compose up
   ```