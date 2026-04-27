import os
import sys
import argparse
import uuid
from pathlib import Path

from dotenv import load_dotenv
from base_loader import get_snowflake_connection, put_and_copy

load_dotenv()

SOURCE_MAP = [
    {
        "file":  "olist_orders_dataset.csv",
        "stage": "OLIST_ORDERS_STAGE",
        "table": "raw_orders",
    },
    {
        "file":  "olist_order_items_dataset.csv",
        "stage": "OLIST_ORDER_ITEMS_STAGE",
        "table": "raw_order_items",
    },
    {
        "file":  "olist_order_payments_dataset.csv",
        "stage": "OLIST_ORDER_PAYMENTS_STAGE",
        "table": "raw_order_payments",
    },
    {
        "file":  "olist_order_reviews_dataset.csv",
        "stage": "OLIST_ORDER_REVIEWS_STAGE",
        "table": "raw_order_reviews",
    },
    {
        "file":  "olist_customers_dataset.csv",
        "stage": "OLIST_CUSTOMERS_STAGE",
        "table": "raw_customers",
    },
    {
        "file":  "olist_products_dataset.csv",
        "stage": "OLIST_PRODUCTS_STAGE",
        "table": "raw_products",
    },
    {
        "file":  "olist_sellers_dataset.csv",
        "stage": "OLIST_SELLERS_STAGE",
        "table": "raw_sellers",
    },
    {
        "file":  "olist_geolocation_dataset.csv",
        "stage": "OLIST_GEOLOCATION_STAGE",
        "table": "raw_geolocation",
    },
    {
        "file":  "product_category_name_translation.csv",
        "stage": "OLIST_CATEGORY_TRANSLATION_STAGE",
        "table": "raw_category_translation",
    },
]


def main():
    parser = argparse.ArgumentParser(
        description="Load all Olist CSV files into Snowflake RAW tables"
    )
    parser.add_argument(
        "--data-dir",
        required=True,
        help="Folder path containing all 9 Olist CSV files"
    )
    parser.add_argument(
        "--run-id",
        default=None,
        help="Optional pipeline run ID. Auto-generated if not provided."
    )
    parser.add_argument(
        "--table",
        default=None,
        help="Load only one specific table. Example: --table raw_orders"
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    run_id = args.run_id or str(uuid.uuid4())[:8]

    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}")
        sys.exit(1)

    sources = SOURCE_MAP

    if args.table:
        sources = [s for s in SOURCE_MAP if s["table"] == args.table]
        if not sources:
            valid = [s["table"] for s in SOURCE_MAP]
            print(f"ERROR: Unknown table '{args.table}'. Valid options: {valid}")
            sys.exit(1)

    missing_files = []
    for source in sources:
        file_path = data_dir / source["file"]
        if not file_path.exists():
            missing_files.append(str(file_path))

    if missing_files:
        print("ERROR: Missing CSV files:")
        for f in missing_files:
            print(f"  {f}")
        sys.exit(1)

    print(f"\nPipeline Run ID : {run_id}")
    print(f"Data directory  : {data_dir}")
    print(f"Tables to load  : {len(sources)}\n")

    conn = get_snowflake_connection()
    summary = []

    try:
        for source in sources:
            local_file = str(data_dir / source["file"])
            print(f"Loading  {source['file']}  ->  {source['table']} ...")

            try:
                result = put_and_copy(
                    conn=conn,
                    local_file=local_file,
                    stage_name=source["stage"],
                    target_table=source["table"],
                    pipeline_run_id=run_id,
                )
                summary.append({
                    "table":         source["table"],
                    "status":        result["status"],
                    "rows_loaded":   result["rows_loaded"],
                    "rows_rejected": result["rows_rejected"],
                })
                print(f"  Done — {result['rows_loaded']:,} loaded, {result['rows_rejected']:,} rejected\n")

            except Exception as e:
                summary.append({
                    "table":         source["table"],
                    "status":        "FAILED",
                    "rows_loaded":   0,
                    "rows_rejected": 0,
                })
                print(f"  FAILED — {e}\n")

    finally:
        conn.close()

    print("=" * 72)
    print(f"{'TABLE':<36} {'STATUS':<10} {'LOADED':>10} {'REJECTED':>10}")
    print("=" * 72)

    total_loaded   = 0
    total_rejected = 0

    for row in summary:
        print(
            f"{row['table']:<36} "
            f"{row['status']:<10} "
            f"{row['rows_loaded']:>10,} "
            f"{row['rows_rejected']:>10,}"
        )
        total_loaded   += row["rows_loaded"]
        total_rejected += row["rows_rejected"]

    print("=" * 72)
    print(f"{'TOTAL':<36} {'':<10} {total_loaded:>10,} {total_rejected:>10,}")
    print("=" * 72)

    failed = [r for r in summary if r["status"] == "FAILED"]
    if failed:
        print(f"\n{len(failed)} table(s) failed. Check load_audit for error details.")
        sys.exit(1)
    else:
        print(f"\nAll tables loaded successfully. Run ID: {run_id}")


if __name__ == "__main__":
    main()# loader placeholder
