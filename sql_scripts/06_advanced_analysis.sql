-- =======================================================================================================================================
-- PHASE 6: ADVANCED ANALYTICS
	-- These questions push beyond standard reporting into the kind of analytical depth that differentiates strong junior analysts. 
	-- Each question introduces a specific advanced SQL concept while remaining grounded in a real retail business context.
-- =======================================================================================================================================


-- Q1 Month-over-Month Revenue Growth
	-- Calculate total revenue for each month across all years and show the month-over-month percentage change. 
	-- This tells the business whether revenue is accelerating or decelerating over time. 

WITH cte AS (
SELECT
	MONTH(order_date) AS order_month,
	YEAR(order_date) AS order_year,
	ROUND(SUM(order_total_cad),2) AS total_revenue
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY MONTH(order_date), YEAR(order_date)
)
SELECT
	order_month,
	order_year,
	total_revenue,
	LAG(total_revenue,1) OVER (ORDER BY order_year, order_month) AS previous_month_revenue,
	ROUND((total_revenue - LAG(total_revenue,1) OVER(ORDER BY order_year, order_month)) / NULLIF(LAG(total_revenue, 1) OVER (ORDER BY order_year, order_month), 0) * 100.0,2) AS mom_revenue_pct
FROM cte


-- Q2 Running Cumulative Revenue by Month (2021-2025)
	-- Show how NovaMart's cumulative revenue has grown from the very first month of operation through to December 2025. 

WITH cte AS (
SELECT
	MONTH(order_date) AS order_month,
	YEAR(order_date) AS order_year,
	ROUND(SUM(order_total_cad),2) AS total_revenue
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY MONTH(order_date), YEAR(order_date)
)
SELECT
	order_month,
	order_year,
	total_revenue,
	SUM(total_revenue) OVER(ORDER BY order_year, order_month) AS cumulative_revenue
FROM cte


-- Q3 Customer RFM Scoring
	-- Score every customer on three dimensions: Recency (how recently they purchased), Frequency (how often they purchase), and Monetary (how much they spend). 
	-- Bucket each dimension into quartiles, scored 1 to 4, where 4 is best. 
	-- Combine the three scores into a single concatenated RFM score string (e.g. 4-3-2) and return each customer with their three individual scores and combined RFM score. 
	-- Use only completed orders.

WITH cte1 AS (
SELECT
	customer_id AS customer_id,
	DATEDIFF(day, MAX(order_date), '2025-12-31') AS recency,
	COUNT(order_id) AS frequency,
	ROUND(SUM(order_total_cad),2) AS monetary
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY customer_id
),
cte2 AS (
SELECT 
	customer_id,
	NTILE(4) OVER(ORDER BY recency DESC) AS recency_score,
	NTILE(4) OVER(ORDER BY frequency)AS frequency_score,
	NTILE(4) OVER(ORDER BY monetary)AS monetary_score
FROM cte1
),
cte3 AS (
SELECT
	customer_id,
	recency_score,
	frequency_score,
	monetary_score,
	CONCAT(recency_score, '-', frequency_score, '-', monetary_score) AS rfm_score,
	recency_score + frequency_score + monetary_score AS rfm_total
FROM cte2
)
SELECT
	r.customer_id,
	c.first_name,
    c.last_name,
    r.recency_score,
    r.frequency_score,
    r.monetary_score,
    r.rfm_score,
    r.rfm_total
FROM cte3 AS r
JOIN novamart_customers_clean AS c
ON r.customer_id = c.customer_id
ORDER BY rfm_total DESC


-- Q4 Product Category Revenue Mix by Province
	-- For each province, show each product category's total revenue and its percentage contribution to that province's total revenue. 
	-- This tells the regional team which categories dominate in each market. 
	-- Only include completed orders.

WITH cte AS (
SELECT
	category,
	province,
	ROUND(SUM(order_total_cad),2) AS total_revenue
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY category, province
)
SELECT
	*,
	SUM(total_revenue) OVER(PARTITION BY province) AS province_revenue,
	ROUND(total_revenue / SUM(total_revenue) OVER(PARTITION BY province) * 100.0,2) AS percent_share_for_province
FROM cte


-- Q5 Customer Cohort Retention Analysis
	-- Group customers by their signup year as a cohort.
	-- For each cohort, track how many customers made at least one completed purchase within their first 90 days of signing up, and what percentage of that cohort converted. 

WITH cte1 AS (
SELECT
	c.customer_id AS customer_id,
	c.signup_date AS signup_date,
	MIN(o.order_date) AS first_order_date
FROM novamart_customers_clean AS c
JOIN novamart_orders_clean AS o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id,	c.signup_date
),
cte2 AS (
SELECT
	*,
	DATEDIFF(day, signup_date, first_order_date) AS days_to_first_order
FROM cte1
)
SELECT
    YEAR(signup_date) AS cohort_year,
    COUNT(customer_id) AS total_customers,
    SUM(CASE WHEN days_to_first_order <= 90 THEN 1 ELSE 0 END) AS converted_customers,
    ROUND(SUM(CASE WHEN days_to_first_order <= 90 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(customer_id), 2) AS conversion_pct
FROM cte2
GROUP BY YEAR(signup_date)
ORDER BY cohort_year


-- Q6 Top 3 Products per Category by Revenue
	-- For each product category, return only the top 3 best-selling products by total revenue from completed orders. 

WITH cte AS (
SELECT
	p.product_name AS product_name,
	o.category AS product_category,
	ROUND(SUM(o.order_total_cad),2) AS total_revenue
	FROM novamart_orders_clean AS o
JOIN novamart_products_clean AS p
ON o.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_name, o.category
),
cte2 AS (
SELECT
	*,
	DENSE_RANK() OVER (PARTITION BY product_category ORDER BY total_revenue DESC) AS revenue_rank
FROM cte
)
SELECT 
	* 
FROM cte2
WHERE revenue_rank <= 3
ORDER BY product_category, revenue_rank
