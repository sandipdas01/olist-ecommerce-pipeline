# olist-ecommerce-pipeline
This project builds an end-to-end data pipeline for the Olist e-commerce dataset, automating raw data ingestion from source files into Snowflake, followed by data transformation using dbt, and final visualization in Power BI. Also included Airflow for Orchestration.

Key Tech Stack ---

Orchestration: Apache Airflow
Warehouse: Snowflake
Transformation: dbt
Visualization: Power BI
Language: Python/SQL

Pipeline Architecture:

Ingestion: Python-based pipeline (via Airflow) to truncate raw tables and ingest CSVs into Snowflake stages.
Transformation: dbt models (Staging → Core → Marts) for clean, business-ready data.
Quality: Automated quality checks in Airflow and dbt tests to ensure data integrity.

How to run:
"Clone this repository."
"Set your environment variables (Snowflake credentials)."
"Run docker compose up to start the Airflow environment."
