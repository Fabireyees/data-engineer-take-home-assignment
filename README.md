# Data Engineering Take-Home Assessment

## Overview

You've been asked to build a data pipeline that unifies sales data from three different retail sources into a single analytical fact table.

**Time expectation:** This task is designed to take approximately 1 hour of focused work.

## The Challenge

Your company has sales data from three different retail channels:
- **Costco** - Warehouse club sales (CSV)
- **Amazon** - Marketplace orders (Parquet)
- **Shopify** - E-commerce store (JSON)

Each source has a different schema, date format, and data characteristics. Your task is to:

1. **Ingest** the data from GCS (or use local samples for development)
2. **Transform** the data using dbt
3. **Produce** a unified `fct_sales` fact table

## Data Sources

### GCS Location
```
gs://irestore-data-eng-assignment/data-engineer-interview/
├── costco/costco_sales.csv
├── amazon/amazon_orders.parquet
└── shopify/shopify_orders.json
```

### Local Samples
Small sample files are included in `data/samples/` for local development and testing.

### Source Schemas

**Costco (CSV)**
- Date format: `MM/DD/YYYY`
- Amounts formatted as strings with `$` symbol (e.g., `$24.99`)
- Multi-row transactions (one row per item in transaction)

**Amazon (Parquet)**
- ISO timestamp format
- Nested product attributes
- Contains order statuses: Shipped, Cancelled, Returned, Pending

**Shopify (JSON/NDJSON)**
- ISO8601 timestamps with timezone
- Nested customer object
- Line items as array (multiple products per order)
- Discount codes included

## Expected Output

Create a `fct_sales` table that unifies all sources with a common schema including:
- Unique sale identifier
- Source system identification
- Normalized dates and timestamps
- Product information
- Financial amounts (gross, discount, tax, shipping, net)
- Geographic information
- Order status (normalized across sources)

See `dbt_project/models/marts/_marts.yml` for the full expected schema.

## Getting Started

### Prerequisites
- Docker and Docker Compose
- (Optional) Python 3.11+ for local development

### Quick Start

1. Start the development environment:
   ```bash
   docker-compose up -d
   ```

2. Access Jupyter Lab at http://localhost:8888 (token: `interview`)

3. Run dbt:
   ```bash
   docker-compose exec dbt bash
   dbt debug  # Verify connection
   dbt run    # Run models
   ```

### Local Development (without Docker)

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install dbt-duckdb pandas pyarrow

# Run dbt
cd dbt_project
dbt run
```

## Deliverables

1. **Working dbt models** - Staging, intermediate (if needed), and mart layers
2. **README updates** - Document your approach, assumptions, and how to run

### Bonus (Optional)
- Add dbt tests (generic and/or custom)

## Evaluation Criteria

You will be evaluated on:
- **Correctness** - Does the pipeline work? Is the data accurate?
- **Code quality** - Readable, maintainable, well-organized
- **Design decisions** - How you handle edge cases, schema choices
- **Documentation** - Clear explanation of your approach

## Hints

- Start with staging models that handle source-specific quirks
- Consider how to handle: cancelled orders, refunds, multi-line orders
- Think about data type consistency across sources
- The data has some quality issues (by design) - handle them appropriately

## Questions?

If you have questions about the requirements, please reach out to your interviewer.

Good luck!
