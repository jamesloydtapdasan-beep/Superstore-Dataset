-- =====================================================================
-- SQL Analysis Queries — Sample Superstore
-- Note: source data has no order_date, customer_id, seller, or payment
-- fields, so time-series, customer-retention, seller, and payment
-- analyses (present in generic e-commerce templates) are not applicable
-- here and have been replaced with queries the schema can support:
-- category, sub-category, region, state, city, segment, and
-- ship-mode analysis.
-- =====================================================================

-- ---------------------------------------------------------------
-- SALES ANALYSIS
-- ---------------------------------------------------------------

-- Total revenue and profit
SELECT SUM(sales) AS total_revenue, SUM(profit) AS total_profit
FROM fact_sales;

-- Revenue and profit by category
SELECT p.category,
       SUM(f.sales) AS revenue,
       SUM(f.profit) AS profit,
       ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Revenue and profit by sub-category
SELECT p.category, p.sub_category,
       SUM(f.sales) AS revenue,
       SUM(f.profit) AS profit,
       COUNT(*) AS line_items
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category, p.sub_category
ORDER BY revenue DESC;

-- Revenue by region
SELECT l.region, SUM(f.sales) AS revenue, SUM(f.profit) AS profit
FROM fact_sales f
JOIN dim_location l ON l.location_id = f.location_id
GROUP BY l.region
ORDER BY revenue DESC;

-- Revenue by state (top 10)
SELECT l.state, SUM(f.sales) AS revenue, SUM(f.profit) AS profit
FROM fact_sales f
JOIN dim_location l ON l.location_id = f.location_id
GROUP BY l.state
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by city (top 10)
SELECT l.city, l.state, SUM(f.sales) AS revenue
FROM fact_sales f
JOIN dim_location l ON l.location_id = f.location_id
GROUP BY l.city, l.state
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------
-- PRODUCT ANALYSIS
-- ---------------------------------------------------------------

-- Best-selling sub-categories by revenue
SELECT p.sub_category, SUM(f.sales) AS revenue, SUM(f.quantity) AS units_sold
FROM fact_sales f JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.sub_category
ORDER BY revenue DESC
LIMIT 10;

-- Worst-performing sub-categories by profit (loss leaders)
SELECT p.sub_category, SUM(f.profit) AS total_profit, SUM(f.sales) AS total_sales
FROM fact_sales f JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.sub_category
ORDER BY total_profit ASC
LIMIT 10;

-- Category performance: revenue, profit, margin, avg discount
SELECT p.category,
       SUM(f.sales) AS revenue,
       SUM(f.profit) AS profit,
       ROUND(AVG(f.discount) * 100, 1) AS avg_discount_pct,
       ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category
ORDER BY profit DESC;

-- ---------------------------------------------------------------
-- CUSTOMER SEGMENT ANALYSIS  (proxy for "customer analysis" —
-- no individual customer_id exists in the source data)
-- ---------------------------------------------------------------
SELECT sg.segment,
       COUNT(*) AS orders,
       SUM(f.sales) AS revenue,
       SUM(f.profit) AS profit,
       ROUND(AVG(f.sales), 2) AS avg_order_value
FROM fact_sales f JOIN dim_segment sg ON sg.segment_id = f.segment_id
GROUP BY sg.segment
ORDER BY revenue DESC;

-- ---------------------------------------------------------------
-- SHIPPING ANALYSIS  (proxy for "order/delivery analysis" —
-- no order date or delivery date exists, so only ship-mode mix
-- and its profitability can be measured)
-- ---------------------------------------------------------------
SELECT sm.ship_mode,
       COUNT(*) AS orders,
       SUM(f.sales) AS revenue,
       ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f JOIN dim_ship_mode sm ON sm.ship_mode_id = f.ship_mode_id
GROUP BY sm.ship_mode
ORDER BY orders DESC;

-- ---------------------------------------------------------------
-- DISCOUNT / PROFITABILITY ANALYSIS
-- ---------------------------------------------------------------

-- Discount bands vs. profitability
SELECT
    CASE
        WHEN f.discount = 0 THEN '0% (no discount)'
        WHEN f.discount <= 0.2 THEN '1-20%'
        WHEN f.discount <= 0.4 THEN '21-40%'
        ELSE '41%+'
    END AS discount_band,
    COUNT(*) AS orders,
    SUM(f.sales) AS revenue,
    SUM(f.profit) AS profit,
    ROUND(AVG(f.profit), 2) AS avg_profit_per_order
FROM fact_sales f
GROUP BY discount_band
ORDER BY discount_band;

-- Loss-making orders count and value by category
SELECT p.category, COUNT(*) AS loss_making_orders, SUM(f.profit) AS total_loss
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
WHERE f.profit < 0
GROUP BY p.category
ORDER BY total_loss ASC;

-- ---------------------------------------------------------------
-- ADVANCED / KPI QUERIES
-- ---------------------------------------------------------------

-- Top 10 highest-revenue (state, sub-category) combinations
SELECT l.state, p.sub_category, SUM(f.sales) AS revenue
FROM fact_sales f
JOIN dim_location l ON l.location_id = f.location_id
JOIN dim_product p  ON p.product_id  = f.product_id
GROUP BY l.state, p.sub_category
ORDER BY revenue DESC
LIMIT 10;

-- Core KPIs in one row
SELECT
    COUNT(*) AS total_orders,
    SUM(f.sales) AS total_revenue,
    SUM(f.profit) AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS overall_margin_pct,
    ROUND(AVG(f.sales), 2) AS avg_order_value,
    ROUND(AVG(f.discount) * 100, 1) AS avg_discount_pct,
    SUM(f.quantity) AS total_units_sold
FROM fact_sales f;
