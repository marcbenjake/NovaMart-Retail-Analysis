-- =======================================================================================================================================
-- PHASE 5: MARKETING AND FUNNEL PERFORMANCE
	-- These questions evaluate how well NovaMart's campaigns are performing and how marketing spend translates to revenue.
-- =======================================================================================================================================

-- Q1 Campaign ROI by Campaign Type
	-- The marketing team wants to know which campaign types deliver the best return on investment. 
	-- Write a query that returns each campaign type with its total spend, total revenue generated, and ROI calculated as (revenue - spend) / spend * 100.

WITH cte AS (
SELECT
	campaign_type,
	ROUND(SUM(spend_cad),2) AS total_campaign_spend,
	ROUND(SUM(revenue_generated_cad),2) AS campaign_revenue_generated
FROM novamart_campaigns_clean
GROUP BY campaign_type
)
SELECT
	campaign_type,
	total_campaign_spend,
	campaign_revenue_generated,
	ROUND((campaign_revenue_generated - total_campaign_spend) / total_campaign_spend * 100.0,2) AS ROI
FROM cte
ORDER BY ROI DESC

-- Note: includes 4 campaigns where spend exceeded budget (is_overspent = 1)
-- These are retained as they represent real spend and revenue data


-- Q2 Click-Through Rate and Conversion Rate by Channel
	-- The digital marketing team needs to evaluate channel efficiency. 
	-- Write a query returning each channel's total impressions, total clicks, total conversions, click-through rate (clicks/impressions), and conversion rate (conversions/clicks).

SELECT
	channel,
	SUM(impressions) AS total_impressions,
	SUM(clicks) AS total_clicks,
	SUM(conversions) AS total_conversions,
	ROUND(SUM(clicks) * 1.0 / SUM(impressions),4) AS click_through_rate,
	ROUND(SUM(conversions) * 1.0 / SUM(clicks),4) AS conversion_rate
FROM novamart_campaigns_clean
GROUP BY channel
ORDER BY channel


-- Q3 Orders and Revenue Attributed to Campaigns vs Organic
	-- The leadership team wants to understand how much of NovaMart's revenue can be attributed to paid marketing efforts versus organic or unattributed orders. 
	-- Write a query that returns total orders, total revenue, and average order value for two groups: Campaign-Attributed orders and Organic (no campaign) orders.

SELECT
	CASE
		WHEN campaign_id IS NULL THEN 'Organic Orders'
		ELSE 'Campaign-Attributed Orders'
	END AS order_group,
	COUNT(order_id) AS order_count,
	ROUND(SUM(order_total_cad),2) AS total_revenue,
	ROUND(AVG(order_total_cad),2) AS avg_order_value	
FROM novamart_orders_clean
GROUP BY CASE
		WHEN campaign_id IS NULL THEN 'Organic Orders'
		ELSE 'Campaign-Attributed Orders'
		END

-- During initial audit, 6830 orders were from organic or unattributed efforts
-- after data cleaning, 6497 orders were organic
-- this must be because I removed the duplicate orders from the original dataset


-- Q4 Top 5 Campaigns by Revenue Generated
	-- The campaign performance team wants to identify their best-performing campaigns. 
	-- Return the top 5 campaigns ranked by revenue generated, including their campaign name, type, channel, budget, spend, and revenue. 
	-- Calculate the cost per conversion as spend / conversions.

SELECT TOP 5
	campaign_name,
	campaign_type,
	channel,
	ROUND(budget_cad,2) AS campaign_budget,
	ROUND(spend_cad,2) AS campaign_spend,
	ROUND(revenue_generated_cad,2) AS revenue_generated,
	ROUND(spend_cad / NULLIF(conversions, 0), 2) AS cost_per_conversion				-- to prevent divide by zero error - returns NULL if coversions = 0 and dividing by NULL returns NULL
FROM novamart_campaigns_clean
ORDER BY revenue_generated_cad DESC


-- Q5 Monthly Campaign Spend vs Revenue Trend (2023-2025)
	-- The CFO wants to see whether marketing spend is translating proportionally to revenue over time. 
	-- Write a query that returns, for each month from 2023 to 2025, the total campaign spend and total campaign revenue generated. Order results chronologically.

SELECT
	YEAR(end_date) AS campaign_year,
	MONTH(end_date) AS campaign_month,
	ROUND(SUM(spend_cad),2) AS campaign_spend,
	ROUND(SUM(revenue_generated_cad),2) AS campaign_revenue_generated
FROM novamart_campaigns_clean
WHERE YEAR(end_date) BETWEEN 2023 AND 2025
GROUP BY YEAR(end_date), MONTH(end_date)
ORDER BY campaign_year, campaign_month

-- Using end_date as the reference point since it represents when campaign results were fully realized
