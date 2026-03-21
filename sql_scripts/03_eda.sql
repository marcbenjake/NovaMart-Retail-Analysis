-- =======================================================================================================================================
-- PHASE 3: EXPLORATORY DATA ANALYSIS
	-- These questions help the business understand overall performance, trends, and patterns across sales, products, and geography.
-- =======================================================================================================================================


-- Q1 Total Revenue, Orders, and Average Order Value by Year
	-- The executive team wants a high-level view of NovaMart's growth over time. 
	-- Write a query that returns total revenue, total number of completed orders, and average order value for each year from 2021 to 2025. 
	-- Only include orders with a status of Completed.

SELECT
	YEAR(order_date) as order_year,
	COUNT(order_id) AS completed_order,
	ROUND(SUM(order_total_cad), 2) AS total_revenue,
	ROUND(SUM(order_total_cad) / COUNT(order_id), 2) AS avg_order_value
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY YEAR(order_date)
ORDER BY order_year


-- Q2 Monthly Sales Trend for 2024
	-- The operations team wants to understand seasonality within a single year. 
	-- Write a query that returns total revenue and total number of orders for each month in 2024. Order results by month.

SELECT
	MONTH(order_date) as order_month,
	DATENAME(MONTH, order_date) AS month_name,
	COUNT(order_id) AS completed_order,
	ROUND(SUM(order_total_cad), 2) AS total_revenue,
	ROUND(SUM(order_total_cad) / COUNT(order_id), 2) AS avg_order_value
FROM novamart_orders_clean
WHERE YEAR(order_date) = 2024
GROUP BY MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY order_month


-- Q3 Top 10 Best-Selling Product Categories by Revenue
	-- The merchandising team wants to know which categories are driving the most revenue.
	-- Write a query returning the top 10 categories ranked by total revenue from completed orders, including total quantity sold and average order value per category.

SELECT TOP 10
	category,
	SUM(quantity) AS total_quantity_sold,
	SUM(order_total_cad) AS order_total,
	AVG(order_total_cad) AS avg_order_total
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY category
ORDER BY order_total DESC
	

-- Q4 Revenue and Order Volume by Province
	-- The regional expansion team needs to understand which provinces are NovaMart's strongest markets. 
	-- Return total revenue and order count by province for completed orders, sorted from highest to lowest revenue.

SELECT
	province,
	COUNT(order_id) AS order_count,
	SUM(order_total_cad) AS order_total,
	AVG(order_total_cad) AS avg_order_total
FROM novamart_orders_clean
WHERE order_status = 'Completed'
GROUP BY province
ORDER BY order_total DESC


-- Q5 Order Status Breakdown
	-- Before any deeper analysis, your manager wants to know the overall health of orders in the system. 
	-- Write a query that returns the count and percentage of orders for each order status (Completed, Returned, Cancelled, Processing).

SELECT
	COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) AS completed_orders,
	ROUND(COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / COUNT(order_id),2) AS completed_orders_percentage,
	COUNT(CASE WHEN order_status = 'Returned' THEN 1 END) AS returned_orders,
	ROUND(COUNT(CASE WHEN order_status = 'Returned' THEN 1 END) * 100.0 / COUNT(order_id),2) AS returned_orders_percentage,
	COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
	ROUND(COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(order_id),2) AS cancelled_orders_percentage,
	COUNT(CASE WHEN order_status = 'Processing' THEN 1 END) AS processing_orders,
	ROUND(COUNT(CASE WHEN order_status = 'Processing' THEN 1 END) * 100.0 / COUNT(order_id),2) AS processing_orders_percentage		
FROM novamart_orders_clean

-- Alternative approach using GROUP BY, scales better with more status values
SELECT
    order_status,
    COUNT(order_id) AS order_count,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2) AS percentage
FROM novamart_orders_clean
GROUP BY order_status
ORDER BY order_count DESC


-- Q6 Most Common Return Reasons
	-- The customer experience team wants to reduce returns. 
	-- Write a query showing the count of returned orders grouped by return reason, sorted by most frequent first. Exclude null return reasons.

SELECT
	COUNT(order_id) AS return_count,
	return_reason
FROM novamart_orders_clean
WHERE order_status = 'Returned' 
AND return_reason IS NOT NULL
GROUP BY return_reason
ORDER BY return_count DESC
