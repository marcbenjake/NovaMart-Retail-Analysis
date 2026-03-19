-- PHASE 1 - DATA AUDIT
	-- Objective: Running queries to surface and quantify the problems.
	-- Not changing any data yet, only documenting what is broken.

-- ============================================================
-- Q1: Identify orders with missing campaign attribution

-- Finding: 6830 orders have no campaign attribution (66.63% of total)
-- ============================================================
SELECT
	COUNT(CASE WHEN campaign_id IS NULL THEN 1 ELSE NULL END) AS unattributed_orders,
	COUNT(order_id) AS total_orders,
	ROUND(COUNT(CASE WHEN campaign_id IS NULL THEN 1 ELSE NULL END) * 100.0 / COUNT(order_id),2) AS percentage
FROM novamart_orders

-- ============================================================
-- Q2  Find customers who have never placed an order

-- Finding: 169 customers have never placed an order
-- ============================================================
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	c.signup_date,
	c.acquisition_channel
FROM novamart_customers AS c
LEFT JOIN novamart_orders AS o
ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL

-- ============================================================
-- Q3  Flag Potentially Duplicate Customers

-- Finding: 916 customers may have signed multiple times, each with a different email.
-- ============================================================
SELECT
	COUNT (*) AS duplicate_count,
	first_name,
	last_name
FROM novamart_customers
GROUP BY first_name, last_name
HAVING COUNT(*) > 1

-- ============================================================
-- Q4  Detect Orders Where Discount Exceeds Order Total

-- Finding: 174 records may have accidentally been recorded as having more discounts than the order total.
-- ============================================================
SELECT
	order_id,
	order_total_cad,
	discount_amount_cad
FROM novamart_orders
WHERE discount_amount_cad >= order_total_cad

-- ============================================================
-- Q5 Flag Extreme Outlier Order Totals

-- Finding: 36 orders have suspiciously high order totals, greater than $5000.
-- ============================================================
SELECT 
	order_id,
	order_total_cad,
	order_date,
	category,
	order_status
FROM novamart_orders
WHERE order_total_cad >= 5000

-- ============================================================
-- Q6 Flag Customers with Negative CLV.

-- Finding: 31 customers have negative CLV
-- ============================================================
SELECT
	customer_id,
	first_name,
	last_name,
	customer_segment,
	estimated_clv
FROM novamart_customers
WHERE estimated_clv <= 0

-- ============================================================
-- Q7 Flag Campaigns Where Spend Exceeds Budget.

-- Finding: FOUR campaigns have overspent their budget
-- ============================================================
SELECT
	campaign_id,
	campaign_name,
	campaign_type,
	budget_cad,
	spend_cad,
	spend_cad - budget_cad AS overspend_amount
FROM novamart_campaigns
WHERE spend_cad > budget_cad
