# Sample Superstore — Sales & Profitability Analytics Project

End-to-end data analytics project: data cleaning, SQL database design, exploratory data analysis, an Excel executive dashboard, and business recommendations for a U.S. retail sales dataset.

## Project Overview

This project analyzes 9,994 order line items from the well-known *Sample Superstore* retail dataset, covering sales, profit, discount, and quantity across product categories, customer segments, shipping modes, and U.S. geography. It was built as a portfolio-ready demonstration of the full analytics workflow: data quality assessment → cleaning → normalized SQL schema → EDA → dashboarding → business recommendations.

**A note on scope:** the source extract is a flat transaction export with **no order date, customer ID, seller, or payment fields**. Rather than inventing those fields, every deliverable here (SQL schema, queries, dashboard, notebook) is scoped to what the data actually supports: category, sub-category, region/state/city, segment, ship mode, discount, and profitability analysis.

## Business Problem

A retail analytics team wants to know **where the business makes money and where it loses money** — which categories/regions/segments to invest in, and where discounting is destroying margin — in order to make pricing and merchandising decisions.

## Dataset Description

| Property | Value |
|---|---|
| Rows (raw / cleaned) | 9,994 / 9,977 |
| Columns | 13 raw → 17 after cleaning + feature engineering |
| Grain | One row per order line item |
| Geography | United States, 49 states, 531 cities |

**Raw columns:** Ship Mode, Segment, Country, City, State, Postal Code, Region, Category, Sub-Category, Sales, Quantity, Discount, Profit.

See [`Data/data_dictionary.md`](Data/data_dictionary.md) for full column definitions.

## Project Architecture

```
Raw CSV → Cleaning (pandas) → Cleaned CSV → SQL schema/load/queries
                                          → Excel dashboard (openpyxl)
                                          → Jupyter EDA notebook
                                          → PNG visualizations
```

## Folder Structure

```
Project/
├── Data/
│   ├── Raw/superstore_raw.csv
│   ├── Cleaned/superstore_clean.csv
│   ├── clean_data.py
│   ├── build_dashboard.py
│   ├── data_dictionary.md
│   └── Dashboard_Clean_Data.xlsx
├── SQL/
│   ├── create_tables.sql
│   ├── import_data.sql
│   └── analysis_queries.sql
├── Notebook/
│   └── analysis.ipynb
├── Visualizations/
│   ├── generate_charts.py
│   ├── Sales/  Profit/  Category/  Geography/  Segment/
├── Dashboard/
│   └── Dashboard_Screenshots/
├── README.md
├── requirements.txt
└── LICENSE
```

## Data Cleaning Process

1. Standardized column names to `snake_case`.
2. Removed **17 exact duplicate rows**.
3. Cast `postal_code` to a zero-padded string (raw integer type stripped leading zeros on New England ZIPs).
4. Rounded monetary fields to 2 decimals; trimmed whitespace on text fields.
5. Validated `discount` ∈ [0,1] and `quantity` > 0 — none invalid.
6. Flagged (not removed) statistical outliers in `sales`/`profit` via IQR — they represent real bulk/high-discount transactions, not data errors.
7. Engineered `profit_margin`, `unit_price`, `is_loss_making`.
8. Added a surrogate `record_id` primary key (source has none).

Full logic: [`Data/clean_data.py`](Data/clean_data.py).

## SQL Database Design

A normalized schema built around the dimensions the data supports: `dim_location`, `dim_product`, `dim_ship_mode`, `dim_segment`, and a `fact_sales` fact table (PostgreSQL syntax). See [`SQL/create_tables.sql`](SQL/create_tables.sql), [`SQL/import_data.sql`](SQL/import_data.sql), and 20+ analysis queries in [`SQL/analysis_queries.sql`](SQL/analysis_queries.sql).

## Exploratory Data Analysis

Full EDA — descriptive stats, correlation analysis, category/geography/segment breakdowns, and a discount-vs-profitability study — lives in [`Notebook/analysis.ipynb`](Notebook/analysis.ipynb).

## Excel Dashboard

[`Data/Dashboard_Clean_Data.xlsx`](Data/Dashboard_Clean_Data.xlsx) — 8 sheets, fully formula-driven (SUMIF/COUNTIF/AVERAGEIF off the Clean Data table, zero hardcoded results):

- **Executive Dashboard** — 6 KPI cards + category, region, sub-category, and ship-mode charts
- **Revenue Analysis** — top 15 states by revenue/profit
- **Segment Analysis** — Consumer/Corporate/Home Office performance
- **Product Analysis** — sub-category revenue, profit, margin
- **Shipping Analysis** — ship-mode revenue and margin
- **Discount Analysis** — discount-band profitability
- **Raw Data** / **Clean Data** — full source and cleaned datasets (Clean Data is an Excel Table for filtering)

> Note: openpyxl cannot create true interactive native Excel PivotTables/Slicers programmatically (Excel itself builds the pivot cache). Formula-driven summary tables + native charts were used instead — functionally equivalent and fully live/recalculating, per best practice of never hardcoding computed results.

## Visualizations

10 charts (category, profit, geography, segment, correlation) generated via `Visualizations/generate_charts.py`, saved under `Visualizations/*/`.

## Key Findings

1. Overall margin is **12.5%** on **$2.30M** revenue across 9,977 order lines.
2. **Technology** has the strongest profit margin; **Furniture** the weakest despite strong revenue.
3. **Tables and Bookcases** are net loss-making sub-categories overall.
4. Average profit per order turns negative once discount exceeds **~20%**.
5. Discount level has almost no correlation with sales volume (r≈-0.03).
6. **Consumer** segment leads revenue but has a slightly lower margin than Home Office.
7. **West and East** regions outperform South and Central.
8. Revenue is geographically concentrated in a handful of top states.
9. **Standard Class** dominates shipping mode by order count.
10. ~19% of order lines are loss-making, concentrated in high-discount Furniture.

## Business Recommendations

1. Cap Furniture discounts around 20% pending a pricing review.
2. Re-price or discontinue chronically loss-making Tables/Bookcases SKUs.
3. Shift promotional budget toward Technology and Office Supplies.
4. Test bundling instead of blanket discounting to lift volume without killing margin.
5. Increase marketing investment in top-performing states/regions.
6. Run a targeted campaign to close the South/Central revenue gap.
7. Evaluate growing the higher-margin Home Office segment.
8. Require manager approval for discounts above ~30%.
9. Collect shipping-cost data to evaluate ship-mode profitability, not just order count.
10. Prioritize collecting timestamped transaction data to enable future trend/seasonality/retention analysis.

## Technologies Used

- **Python**: pandas, numpy, matplotlib, seaborn
- **Excel**: openpyxl (formulas, native charts, tables)
- **SQL**: PostgreSQL syntax
- **Jupyter Notebook**

## Installation Guide

```bash
git clone <repo-url>
cd Project
pip install -r requirements.txt
```

## How to Run

```bash
# 1. Clean the data
cd Data && python clean_data.py

# 2. Build the Excel dashboard
python build_dashboard.py

# 3. Generate visualizations
cd ../Visualizations && python generate_charts.py

# 4. Open the notebook
jupyter notebook ../Notebook/analysis.ipynb

# 5. Load into PostgreSQL (optional)
psql -f ../SQL/create_tables.sql
psql -f ../SQL/import_data.sql
psql -f ../SQL/analysis_queries.sql
```

## Future Improvements

- Add timestamped order data to enable trend/seasonality analysis.
- Add customer-level IDs to support retention and CLV analysis.
- Add cost/shipping data to properly evaluate ship-mode profitability.
- Convert formula-driven Excel summaries to true native PivotTables via an Excel/VBA post-processing step.
- Build a live Power BI / Tableau dashboard on top of the normalized SQL schema.

## Dashboard Screenshots

_Add exported screenshots of the Excel dashboard here: `Dashboard/Dashboard_Screenshots/`._

## Author

JL — CS student, Cebu Technological University Naga Extension Campus. Capstone/portfolio project.
