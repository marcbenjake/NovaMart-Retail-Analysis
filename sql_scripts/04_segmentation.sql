-- =======================================================================================================================================
-- PHASE 4: CUSTOMER SEGMENTATION AND LIFETIME VALUE
	-- These questions address customer behaviour, segment performance, and lifetime value, which are core skills for any retail or customer insights analyst role.
-- =======================================================================================================================================

-- Q1 Average Order Value and Order Frequency by Customer Segment
	-- The strategy team wants to understand how different customer segments behave. 
	-- Write a query that returns, for each customer segment, the average order value, average number of orders per customer, and total revenue generated. 
	-- Use only completed orders.

SELECT
	c.customer_segment AS customer_segment,
	ROUND(AVG(o.order_total_cad),2) AS avg_order_value,
	ROUND(COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_id), 2) AS avg_orders_per_customer,
	ROUND(SUM(o.order_total_cad),2) AS total_revenue_generated
FROM novamart_customers_clean AS c
JOIN novamart_orders_clean AS o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_segment
ORDER BY total_revenue_generated DESC


-- Q2 Top 20 Customers by Total Lifetime Spend
	-- Identify NovaMart's highest-value customers. 
	-- Write a query returning the top 20 customers ranked by their total spend on completed orders. 
	-- Include their name, segment, province, acquisition channel, and total spend.

SELECT TOP 20
	c.first_name,
	c.last_name,
	c.customer_segment,
	c.province,
	c.acquisition_channel,
	ROUND(SUM(o.order_total_cad),2) AS total_spend
FROM novamart_customers_clean AS c
JOIN novamart_orders_clean AS o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.first_name, c.last_name, c.customer_segment, c.province, c.acquisition_channel
ORDER BY total_spend DESC


-- Q3 Customer Retention: Repeat vs One-Time Buyers
	-- The growth team wants to understand how many customers have come back after their first order.
	-- Write a query that categorizes each customer as either a One-Time Buyer (exactly 1 order) or a Repeat Buyer (2 or more orders), and returns the count and percentage for each group.

WITH customer_order_count AS (
SELECT
	c.customer_id AS customer_id,
	COUNT (o.order_id) AS order_count
FROM novamart_customers_clean AS c
JOIN novamart_orders_clean AS o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id
),
customer_category AS (
SELECT
	customer_id,
	order_count,
	CASE
		WHEN order_count = 1 THEN 'One-Time Buyer'
		WHEN order_count > 1 THEN 'Repeat Buyer'
	END AS customer_type
FROM customer_order_count
)
SELECT
	customer_type,
	COUNT(customer_id) AS customer_count,
	ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 2) AS percentage
FROM customer_category
GROUP BY customer_type

-- NOTE - for the window function used when calculating the percentage, When using GROUP BY, the query splits into separate groups 
	-- one row for One-Time Buyers and one row for Repeat Buyers. Inside each group, any COUNT you write only sees the rows belonging to that group.
-- I need the denominator to be the total across ALL groups combined, not just the current group. 
-- THE OVER() tells SQL Server to step outside the current group and sum the counts across the entire result set. It ignores the GROUP BY boundaries and looks at everything.


-- Q4 New Customer Acquisition by Year and Channel
	-- The marketing team needs to understand which channels are bringing in the most new customers over time.
	-- Write a query that returns the number of new customer signups per year, broken down by acquisition channel.

SELECT 
	COUNT(customer_id) AS new_customers,
	YEAR(signup_date) AS signup_year,
	acquisition_channel
FROM novamart_customers_clean
GROUP BY YEAR(signup_date), acquisition_channel
ORDER BY signup_year, new_customers, acquisition_channel


-- Q5 CLV vs Actual Spend Gap Analysis
	-- The customer data team wants to know how accurate the estimated CLV field is compared to what customers have actually spent. 
	-- Write a query that returns, for each customer segment, the average estimated CLV and the average actual total spend from completed orders, and calculate the gap between the two.

WITH customer_spend AS (
    SELECT
        customer_id,
        SUM(order_total_cad) AS total_spend
    FROM novamart_orders_clean
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT
    c.customer_segment,
    ROUND(AVG(cs.total_spend),2) AS avg_spend_per_customer,
    ROUND(AVG(c.estimated_clv),2) AS avg_estimated_clv,
    ROUND(AVG(c.estimated_clv),2) - ROUND(AVG(cs.total_spend),2) AS gap
FROM customer_spend AS cs
JOIN novamart_customers_clean AS c
ON cs.customer_id = c.customer_id
GROUP BY c.customer_segment
