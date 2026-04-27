import os
from datetime import datetime, timezone
from typing import Optional

import snowflake.connector
from dotenv import load_dotenv

load_dotenv()


def get_snowflake_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "SYSADMIN"),
        warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE", "OLIST_LOADER_WH"),
        database=os.environ.get("SNOWFLAKE_DATABASE", "OLIST_PROD_RAW"),
        schema="OLIST",
    )


def write_audit(
    conn,
    source_table: str,
    source_file: str,
    rows_loaded: int,
    rows_rejected: int,
    status: str,
    start_ts: datetime,
    pipeline_run_id: Optional[str] = None,
    error_message: Optional[str] = None,
):
    end_ts = datetime.now(timezone.utc)

    sql = """
        INSERT INTO load_audit (
            source_table,
            source_file,
            rows_loaded,
            rows_rejected,
            load_status,
            load_start_ts,
            load_end_ts,
            pipeline_run_id,
            error_message
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """

    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                source_table,
                source_file,
                rows_loaded,
                rows_rejected,
                status,
                start_ts,
                end_ts,
                pipeline_run_id,
                error_message,
            ),
        )


def put_and_copy(
    conn,
    local_file: str,
    stage_name: str,
    target_table: str,
    pipeline_run_id: Optional[str] = None,
) -> dict:
    start_ts = datetime.now(timezone.utc)
    file_name = os.path.basename(local_file)

    # Convert Windows backslashes to forward slashes for Snowflake PUT URI
    local_file_uri = local_file.replace("\\", "/")

    result = {
        "rows_loaded": 0,
        "rows_rejected": 0,
        "status": "FAILED",
    }

    try:
        with conn.cursor() as cur:
            # Step 1 — PUT local CSV to Snowflake internal stage
            put_sql = f"PUT 'file://{local_file_uri}' @{stage_name} AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
            cur.execute(put_sql)

            # Step 2 — COPY INTO RAW table from stage
            staged_file = f"{file_name}.gz"
            copy_sql = f"""
                COPY INTO {target_table}
                FROM @{stage_name}/{staged_file}
                FILE_FORMAT = (FORMAT_NAME = 'OLIST_CSV_FORMAT')
                ON_ERROR = 'CONTINUE'
                PURGE = FALSE
            """
            cur.execute(copy_sql)
            copy_results = cur.fetchall()

            # Snowflake COPY INTO result column order (zero-indexed):
            # [0] file  [1] status  [2] rows_parsed  [3] rows_loaded
            # [4] error_limit  [5] errors_seen  [6] first_error ...
            for row in copy_results:
                rows_loaded   = int(row[3]) if len(row) > 3 and row[3] is not None else 0
                rows_rejected = int(row[5]) if len(row) > 5 and row[5] is not None else 0
                result["rows_loaded"]   += rows_loaded
                result["rows_rejected"] += rows_rejected

            result["status"] = "PARTIAL" if result["rows_rejected"] > 0 else "SUCCESS"

            write_audit(
                conn=conn,
                source_table=target_table,
                source_file=file_name,
                rows_loaded=result["rows_loaded"],
                rows_rejected=result["rows_rejected"],
                status=result["status"],
                start_ts=start_ts,
                pipeline_run_id=pipeline_run_id,
                error_message=None,
            )

    except Exception as e:
        try:
            write_audit(
                conn=conn,
                source_table=target_table,
                source_file=file_name,
                rows_loaded=0,
                rows_rejected=0,
                status="FAILED",
                start_ts=start_ts,
                pipeline_run_id=pipeline_run_id,
                error_message=str(e),
            )
        except Exception:
            pass
        raise

    return result
