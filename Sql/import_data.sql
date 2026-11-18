-- =====================================================================
-- Data Loading Script — loads Data/Cleaned/superstore_clean.csv into a
-- PostgreSQL staging table, then populates the normalized schema.
-- =====================================================================

-- 1) Staging table mirrors the flat cleaned CSV exactly
DROP TABLE IF EXISTS staging_superstore;
CREATE TABLE staging_superstore (
    record_id       INTEGER,
    ship_mode       VARCHAR(30),
    segment         VARCHAR(30),
    country         VARCHAR(50),
    city            VARCHAR(100),
    state           VARCHAR(100),
    postal_code     VARCHAR(10),
    region          VARCHAR(20),
    category        VARCHAR(50),
    sub_category    VARCHAR(50),
    sales           NUMERIC(12,2),
    quantity        INTEGER,
    discount        NUMERIC(4,2),
    profit          NUMERIC(12,2),
    profit_margin   NUMERIC(6,4),
    is_loss_making  BOOLEAN,
    unit_price      NUMERIC(12,2)
);

\copy staging_superstore FROM 'Data/Cleaned/superstore_clean.csv' WITH (FORMAT csv, HEADER true);

-- 2) Populate dimension tables (de-duplicated from staging)
INSERT INTO dim_location (city, state, postal_code, region, country)
SELECT DISTINCT city, state, postal_code, region, country
FROM staging_superstore
ON CONFLICT (city, state, postal_code) DO NOTHING;

INSERT INTO dim_product (category, sub_category)
SELECT DISTINCT category, sub_category
FROM staging_superstore
ON CONFLICT (category, sub_category) DO NOTHING;

INSERT INTO dim_ship_mode (ship_mode)
SELECT DISTINCT ship_mode FROM staging_superstore
ON CONFLICT (ship_mode) DO NOTHING;

INSERT INTO dim_segment (segment)
SELECT DISTINCT segment FROM staging_superstore
ON CONFLICT (segment) DO NOTHING;

-- 3) Populate the fact table with resolved foreign keys
INSERT INTO fact_sales (record_id, location_id, product_id, ship_mode_id,
                         segment_id, sales, quantity, discount, profit,
                         profit_margin, unit_price)
SELECT
    s.record_id,
    l.location_id,
    p.product_id,
    sm.ship_mode_id,
    sg.segment_id,
    s.sales,
    s.quantity,
    s.discount,
    s.profit,
    s.profit_margin,
    s.unit_price
FROM staging_superstore s
JOIN dim_location  l  ON l.city = s.city AND l.state = s.state AND l.postal_code = s.postal_code
JOIN dim_product   p  ON p.category = s.category AND p.sub_category = s.sub_category
JOIN dim_ship_mode sm ON sm.ship_mode = s.ship_mode
JOIN dim_segment   sg ON sg.segment = s.segment;

-- 4) Drop staging table once loaded
DROP TABLE staging_superstore;
