from __future__ import annotations

import os
import logging
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator

log = logging.getLogger(__name__)

SNOWFLAKE_CONN_ID = "snowflake_olist"
OLIST_CSV_DIR     = os.getenv("OLIST_CSV_DIR", "/opt/airflow/data")
DBT_PROJECT_DIR   = os.getenv("DBT_PROJECT_DIR", "/opt/airflow/dbt")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")


def notify_slack(context):
    import urllib.request, json
    if not SLACK_WEBHOOK_URL:
        return
    task_id = context["task_instance"].task_id
    dag_id  = context["dag"].dag_id
    log_url = context["task_instance"].log_url
    payload = {"text": f":red_circle: *OLIST PIPELINE FAILED*\n>DAG: `{dag_id}`\n>Task: `{task_id}`\n>Logs: {log_url}"}
    req = urllib.request.Request(SLACK_WEBHOOK_URL, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req)


def notify_sla_miss(dag, task_list, blocking_task_list, slas, blocking_tis):
    import urllib.request, json
    if not SLACK_WEBHOOK_URL:
        return
    missed = [s.task_id for s in slas]
    payload = {"text": f":warning: *SLA MISSED* in `{dag.dag_id}` — Tasks: {missed}"}
    req = urllib.request.Request(SLACK_WEBHOOK_URL, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req)


TRUNCATE_RAW_SQL = [
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_orders",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_customers",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_order_items",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_order_payments",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_order_reviews",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_products",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_sellers",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_geolocation",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.raw_category_translation",
    "TRUNCATE TABLE OLIST_PROD_RAW.OLIST.load_audit",
]


def run_ingestion(**context):
    import sys, uuid
    dag_folder = Path(__file__).parent
    if str(dag_folder) not in sys.path:
        sys.path.insert(0, str(dag_folder))
    from base_loader import get_snowflake_connection, put_and_copy
    SOURCE_MAP = [
        {"file": "olist_orders_dataset.csv",              "stage": "OLIST_ORDERS_STAGE",               "table": "raw_orders"},
        {"file": "olist_order_items_dataset.csv",         "stage": "OLIST_ORDER_ITEMS_STAGE",          "table": "raw_order_items"},
        {"file": "olist_order_payments_dataset.csv",      "stage": "OLIST_ORDER_PAYMENTS_STAGE",       "table": "raw_order_payments"},
        {"file": "olist_order_reviews_dataset.csv",       "stage": "OLIST_ORDER_REVIEWS_STAGE",        "table": "raw_order_reviews"},
        {"file": "olist_customers_dataset.csv",           "stage": "OLIST_CUSTOMERS_STAGE",            "table": "raw_customers"},
        {"file": "olist_products_dataset.csv",            "stage": "OLIST_PRODUCTS_STAGE",             "table": "raw_products"},
        {"file": "olist_sellers_dataset.csv",             "stage": "OLIST_SELLERS_STAGE",              "table": "raw_sellers"},
        {"file": "olist_geolocation_dataset.csv",         "stage": "OLIST_GEOLOCATION_STAGE",          "table": "raw_geolocation"},
        {"file": "product_category_name_translation.csv", "stage": "OLIST_CATEGORY_TRANSLATION_STAGE", "table": "raw_category_translation"},
    ]
    run_id  = str(uuid.uuid4())
    conn    = get_snowflake_connection()
    csv_dir = Path(OLIST_CSV_DIR)
    failed  = []
    for item in SOURCE_MAP:
        csv_path = csv_dir / item["file"]
        if not csv_path.exists():
            raise FileNotFoundError(f"CSV not found: {csv_path}")
        result = put_and_copy(conn, str(csv_path), item["stage"], item["table"], run_id)
        log.info(f"{item['table']:<35} {result['status']:<10} {result['rows_loaded']:>12,}")
        if result["status"] == "FAILED":
            failed.append(item["table"])
    conn.close()
    if failed:
        raise RuntimeError(f"Ingestion failed for: {failed}")


QUALITY_CHECK_SQL = [
    "SELECT IFF(COUNT(*) < 20, 'ERROR: mart_monthly_revenue has too few months', 'OK') AS result FROM OLIST_PROD_MARTS.OLIST.mart_monthly_revenue HAVING COUNT(*) < 20",
    "SELECT IFF(COUNT(*) = 0, 'ERROR: mart_customer_cohorts is empty', 'OK') AS result FROM OLIST_PROD_MARTS.OLIST.mart_customer_cohorts HAVING COUNT(*) = 0",
]

DEFAULT_ARGS = {
    "owner": "olist_pipeline",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": notify_slack,
    "email_on_failure": False,
    "email_on_retry": False,
}

with DAG(
    dag_id="olist_daily_pipeline",
    description="Olist: Truncate RAW → Ingest CSVs → dbt build → quality check",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 4, 27),
    schedule_interval="0 2 * * *",
    catchup=False,
    sla_miss_callback=notify_sla_miss,
    tags=["olist", "snowflake", "dbt", "production"],
) as dag:

    start = EmptyOperator(task_id="start")
    end   = EmptyOperator(task_id="end")

    truncate_raw = SnowflakeOperator(
        task_id="truncate_raw",
        sql=TRUNCATE_RAW_SQL,
        snowflake_conn_id=SNOWFLAKE_CONN_ID,
        sla=timedelta(minutes=10),
    )

    load_raw = PythonOperator(
        task_id="load_raw",
        python_callable=run_ingestion,
        sla=timedelta(hours=1),
    )

    dbt_staging = BashOperator(
        task_id="dbt_staging",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select staging --profiles-dir . --no-use-colors --no-partial-parse",
        sla=timedelta(hours=1),
    )

    dbt_test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select staging --profiles-dir . --no-use-colors",
    )

    dbt_core = BashOperator(
        task_id="dbt_core",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select core --profiles-dir . --no-use-colors",
        sla=timedelta(hours=2),
    )

    dbt_test_core = BashOperator(
        task_id="dbt_test_core",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select core --profiles-dir . --no-use-colors",
    )

    dbt_marts = BashOperator(
        task_id="dbt_marts",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select marts --profiles-dir . --no-use-colors",
        sla=timedelta(hours=3),
    )

    dbt_test_marts = BashOperator(
        task_id="dbt_test_marts",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select marts --profiles-dir . --no-use-colors",
    )

    quality_check = SnowflakeOperator(
        task_id="quality_check",
        sql=QUALITY_CHECK_SQL,
        snowflake_conn_id=SNOWFLAKE_CONN_ID,
    )

    (
        start
        >> truncate_raw
        >> load_raw
        >> dbt_staging
        >> dbt_test_staging
        >> dbt_core
        >> dbt_test_core
        >> dbt_marts
        >> dbt_test_marts
        >> quality_check
        >> end
    )