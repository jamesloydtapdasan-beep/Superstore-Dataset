-- =====================================================================
-- Sample Superstore — Database Schema (PostgreSQL syntax)
-- =====================================================================
-- Design note: the source file is a single flat extract with no
-- order_id, customer_id, order_date, seller, or payment fields — it is
-- a transaction-level export, not a normalized OLTP export. A fully
-- normalized 3NF design is therefore built around the natural
-- dimensions that DO exist (location, product, and order attributes),
-- with the transaction line as the fact table. This still removes
-- repeating groups and supports the SQL analysis in analysis_queries.sql.
-- =====================================================================

DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_ship_mode CASCADE;
DROP TABLE IF EXISTS dim_segment CASCADE;

-- ---------------------------------------------------------------
-- Dimension: Location (city/state/region/postal code)
-- ---------------------------------------------------------------
CREATE TABLE dim_location (
    location_id     SERIAL PRIMARY KEY,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL,
    postal_code     VARCHAR(10)  NOT NULL,
    region          VARCHAR(20)  NOT NULL,
    country         VARCHAR(50)  NOT NULL DEFAULT 'United States',
    UNIQUE (city, state, postal_code)
);

-- ---------------------------------------------------------------
-- Dimension: Product (category / sub-category)
-- ---------------------------------------------------------------
CREATE TABLE dim_product (
    product_id      SERIAL PRIMARY KEY,
    category        VARCHAR(50) NOT NULL,
    sub_category    VARCHAR(50) NOT NULL,
    UNIQUE (category, sub_category)
);

-- ---------------------------------------------------------------
-- Dimension: Ship Mode
-- ---------------------------------------------------------------
CREATE TABLE dim_ship_mode (
    ship_mode_id    SERIAL PRIMARY KEY,
    ship_mode       VARCHAR(30) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------
-- Dimension: Customer Segment
-- ---------------------------------------------------------------
CREATE TABLE dim_segment (
    segment_id      SERIAL PRIMARY KEY,
    segment         VARCHAR(30) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------
-- Fact: Sales (one row per order line item)
-- ---------------------------------------------------------------
CREATE TABLE fact_sales (
    record_id       INTEGER PRIMARY KEY,      -- surrogate key from source extract
    location_id     INTEGER NOT NULL REFERENCES dim_location(location_id),
    product_id      INTEGER NOT NULL REFERENCES dim_product(product_id),
    ship_mode_id    INTEGER NOT NULL REFERENCES dim_ship_mode(ship_mode_id),
    segment_id      INTEGER NOT NULL REFERENCES dim_segment(segment_id),
    sales           NUMERIC(12,2) NOT NULL CHECK (sales >= 0),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    discount        NUMERIC(4,2)  NOT NULL CHECK (discount >= 0 AND discount <= 1),
    profit          NUMERIC(12,2) NOT NULL,
    profit_margin   NUMERIC(6,4),
    unit_price      NUMERIC(12,2)
);

CREATE INDEX idx_fact_sales_location ON fact_sales(location_id);
CREATE INDEX idx_fact_sales_product  ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_region   ON fact_sales(location_id, product_id);
