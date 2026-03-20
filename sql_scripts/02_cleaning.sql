-- =======================================================================================================================================
-- PHASE 2: DATA CLEANING
-- For each table, I will write a SELECT INTO statement that creates a new clean table, with all transformations built directly into the SELECT.
-- The raw tables stay untouched. The clean tables are what I use for all analysis.
-- I first identify the misspelt variants in columns
-- After identifying, I use CASE WHEN to make all the corrections
-- After corrections, I wrap them in a CTE and use ROW_NUMBER () to keep only the first row as a unique row and eliminate the rest
-- =======================================================================================================================================



-- =====================================
-- novamart_customers (CUSTOMERS TABLE)
-- =====================================

-- The following are the data quality issues addressed for the customers table

	-- Standardize province -- fix variants like 'Ontario', 'on', 'Ont.' all to 'ON'
	-- Standardize gender -- fix variants like 'male', 'M', 'MALE' all to 'Male.'
	-- Standardize acquisition_channel -- fix variants like 'organic', 'PPC', 'ORGANIC SEARCH' all to 'Organic Search.'
	-- Remove duplicate rows
	-- Flag or NULL out impossible age values (0, -1, 150, 999)
	-- Flag or NULL out negative estimated_clv values
-- =======================================================================================================================================

-- =======================================================================================================================================
-- Audit query to identify different variants of misspelt terms
-- =======================================================================================================================================

-- See all province variants
SELECT DISTINCT province, COUNT(*) AS count
FROM novamart_customers
GROUP BY province
ORDER BY province

-- See all gender variants
SELECT DISTINCT gender, COUNT(*) AS count
FROM novamart_customers
GROUP BY gender
ORDER BY gender

-- See all acquisition_channel variants
SELECT DISTINCT acquisition_channel, COUNT(*) AS count
FROM novamart_customers
GROUP BY acquisition_channel
ORDER BY acquisition_channel

-- =======================================================================================================================================
-- The query for data transformation, removing duplicates and creating a new table
-- =======================================================================================================================================

WITH deduplicated AS (															 -- CTE created for data cleaning
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date) AS row_num -- Partitioning rows by customer_id to find the duplicates
FROM novamart_customers
)
SELECT
	customer_id,
	TRIM(first_name) AS first_name,
	TRIM(last_name) AS last_name,
	TRIM(email) AS email,
	signup_date,
	CASE																		-- Data cleaning starts
		WHEN TRIM(province) IN ('Alberta', 'Alta.', 'ab') THEN 'AB'
		WHEN TRIM(province) IN ('British Columbia', 'bc', 'B.C.') THEN 'BC'
		WHEN TRIM(province) IN ('mb', 'Manitoba') THEN 'MB'
		WHEN TRIM(province) IN ('New Brunswick') THEN 'NB'
		WHEN TRIM(province) IN ('Newfoundland') THEN 'NL'
		WHEN TRIM(province) IN ('Nova Scotia') THEN 'NS'
		WHEN TRIM(province) IN ('Ontario', 'on', 'Ont.', 'ontario') THEN 'ON'
		WHEN TRIM(province) IN ('Que.', 'Quebec', 'québec') THEN 'QC'
		WHEN TRIM(province) IN ('Saskatchewan') THEN 'SK'
		ELSE TRIM(province)
	END AS province,
	CASE
		WHEN TRIM(gender) IN ('-', 'n/a', 'N/A') THEN NULL
		WHEN TRIM(gender) IN ('F', 'Woman') THEN 'Female'
		WHEN TRIM(gender) IN ('M', 'Man') THEN 'Male'
		WHEN TRIM(gender) IN ('NB', 'Non Binary', 'Non-binary') THEN 'Non-Binary'
		ELSE TRIM(gender)
	END AS gender,
	CASE
		WHEN TRIM(acquisition_channel) IN ('Aff.') THEN 'Affiliate'
		WHEN TRIM(acquisition_channel) IN ('direct', 'Direct Traffic') THEN 'Direct'
		WHEN TRIM(acquisition_channel) IN ('E-mail') THEN 'Email'
		WHEN TRIM(acquisition_channel) IN ('organic') THEN 'Organic Search'
		WHEN TRIM(acquisition_channel) IN ('Paid', 'PPC') THEN 'Paid Search'
		WHEN TRIM(acquisition_channel) IN ('Ref') THEN 'Referral'
		WHEN TRIM(acquisition_channel) IN ('Social') THEN 'Social Media'
		ELSE TRIM(acquisition_channel)
	END AS acquisition_channel,
	CASE
		WHEN age < 0 OR age > 100 THEN NULL
		ELSE age
	END AS age,
	loyalty_member,
	CASE
		WHEN estimated_clv < 0 THEN NULL
		ELSE estimated_clv
	END AS estimated_clv
INTO novamart_customers_clean											-- Cleaned and transformed table inserted into new table
FROM deduplicated
WHERE row_num = 1;														-- Filtered to keep unique customer_id and eliminated duplicates

-- =======================================================================================================================================
-- Verification checks for the cleaned data
-- =======================================================================================================================================

-- Check row count (should be lower than original 3060 due to deduplication)
SELECT COUNT(*) FROM novamart_customers_clean

-- Spot check the standardized columns look correct
SELECT DISTINCT province FROM novamart_customers_clean ORDER BY province
SELECT DISTINCT gender FROM novamart_customers_clean ORDER BY gender
SELECT DISTINCT acquisition_channel FROM novamart_customers_clean ORDER BY acquisition_channel


-- =======================================================================================================================================


-- =====================================
-- novamart_orders (ORDERS TABLE)
-- =====================================

-- The following are the data quality issues addressed for the orders table

	-- This one has more row-level exclusions, meaning the WHERE clause does more heavy lifting here.
	-- Some rows should be completely removed from the table as they are invalid and do not exist in the table at all
		-- Repeating order numbers
		-- Orders where the discount is more than the total price
		-- Orders with zero or negative order total
		-- Orders above $5000
		-- Orders with quantity as 0
		-- Standardizing order_status column
		-- Standardizing payment_method column
-- =======================================================================================================================================

-- =======================================================================================================================================
-- Audit query to identify different variants of misspelt terms
-- =======================================================================================================================================

-- See all order_status variants
SELECT DISTINCT order_status, COUNT(*) AS count
FROM novamart_orders
GROUP BY order_status
ORDER BY order_status

-- See all payment_method variants
SELECT DISTINCT payment_method, COUNT(*) AS count
FROM novamart_orders
GROUP BY payment_method
ORDER BY payment_method

-- =======================================================================================================================================
-- The query for data transformation, removing duplicates and creating a new table
-- =======================================================================================================================================

WITH deduplicated AS (																	-- CTE created for data cleaning
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date) AS row_num			-- Partitioning rows by order_id to find the duplicates 
	FROM novamart_orders
)
SELECT
	order_id,
	customer_id,
	product_id,
	campaign_id,
	order_date,
	order_total_cad,
	discount_amount_cad,
	quantity,
	category,
	CASE																				-- data cleaning starts
		WHEN TRIM(order_status) IN ('Canceled') THEN 'Cancelled'
		WHEN TRIM(order_status) IN ('complete', 'completed', 'COMPLETED', 'Complete') THEN 'Completed'
		WHEN TRIM(order_status) IN ('in process') THEN 'Processing'
		WHEN TRIM(order_status) IN ('return') THEN 'Returned'
		ELSE TRIM(order_status)
	END AS order_status,
	CASE
		WHEN TRIM(payment_method) IN ('ApplePay') THEN 'Apple Pay'
		WHEN TRIM(payment_method) IN ('CC', 'cc', 'credit') THEN 'Credit Card'
		WHEN TRIM(payment_method) IN ('debit', 'debit card') THEN 'Debit Card'
		WHEN TRIM(payment_method) IN ('GooglePay', 'Gpay') THEN 'Google Pay'
		WHEN TRIM(payment_method) IN ('interac', 'Interac', 'etransfer', 'e-transfer') THEN 'Interac e-Transfer'
		WHEN TRIM(payment_method) IN ('Pay Pal') THEN 'PayPal'
		ELSE TRIM(payment_method)
	END AS payment_method,
	province,
	TRIM(city) AS city,
	session_duration_minutes,
	is_repeat_customer,
	delivery_days,
	return_reason
INTO novamart_orders_clean																-- cleaned and transformed table inserted into new table
FROM deduplicated
WHERE row_num = 1																		-- Filtered to keep unique order_id and eliminate duplicates	
AND (discount_amount_cad <= order_total_cad OR discount_amount_cad IS NULL)
AND order_total_cad > 0
AND order_total_cad < 5000
AND quantity <> 0;

-- =======================================================================================================================================
-- Verification checks for the cleaned data
-- =======================================================================================================================================

-- Check row count (should be noticeably lower than original 10,250)
SELECT COUNT(*) FROM novamart_orders_clean

-- Verify no bad rows slipped through
SELECT COUNT(*) FROM novamart_orders_clean WHERE order_total_cad <= 0
SELECT COUNT(*) FROM novamart_orders_clean WHERE order_total_cad >= 5000
SELECT COUNT(*) FROM novamart_orders_clean WHERE quantity = 0

-- Spot check standardized columns
SELECT DISTINCT order_status FROM novamart_orders_clean ORDER BY order_status
SELECT DISTINCT payment_method FROM novamart_orders_clean ORDER BY payment_method


-- =======================================================================================================================================


-- =====================================
-- novamart_PRODUCTS (ORDERS PRODUCTS)
-- =====================================

-- The following are the data quality issues addressed for the orders table

	-- Negative cost_price values -- set to NULL
	-- NULL values in avg_rating and review_count -- leave as NULL, they are unknown, not invalid
	-- Duplicate rows -- handle with ROW_NUMBER()

-- =======================================================================================================================================
-- The query for data transformation, removing duplicates and creating a new table
-- =======================================================================================================================================

WITH deduplicated AS (															-- CTE created for data cleaning
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY category) AS row_num	-- Partitioning rows by product_id to identify duplicates		 
	FROM novamart_products
)
SELECT
	product_id,
	TRIM(product_name) AS product_name,
	TRIM(category) AS category,
	unit_price,
	CASE WHEN cost_price <= 0 THEN NULL ELSE cost_price END AS cost_price,
	TRIM(brand) AS brand,
	is_private_label,
	in_stock,
	avg_rating,
	review_count
INTO novamart_products_clean													-- Inserting clean data to new table	
FROM deduplicated
WHERE row_num = 1;																-- Filtering for unique product_id and eliminating the duplicates

-- =======================================================================================================================================
-- Verification checks for the cleaned data
-- =======================================================================================================================================

-- Check row count
SELECT COUNT(*) FROM novamart_products_clean

-- Verify no negative cost prices slipped through
SELECT COUNT(*) FROM novamart_products_clean WHERE cost_price <= 0


-- =======================================================================================================================================


-- =======================================
-- novamart_campaigns (CAMPAIGNS PRODUCTS)
-- =======================================

-- The following are the data quality issues addressed for the campaigns table

	-- Duplicate rows
	-- Campaigns where spend exceeds budget -- flag them rather than remove them

-- =======================================================================================================================================
-- The query for data transformation, removing duplicates and creating a new table
-- =======================================================================================================================================

WITH deduplicated AS (															-- CTE created for data cleaning
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY campaign_type) AS row_num	-- Partitioning rows by campaign_id to identify duplicates		 
	FROM novamart_campaigns
)
SELECT
	campaign_id,
	campaign_name,
	campaign_type,
	channel,
	start_date,
	end_date,
	budget_cad,
	spend_cad,
	CASE WHEN spend_cad > budget_cad THEN 1 ELSE 0 END AS is_overspent,			-- Flagged for when campaign spend exeeds campaign budget
	impressions,
	clicks,
	conversions,
	revenue_generated_cad,
	target_segment,
	promo_code
INTO novamart_campaigns_clean													-- Inserting clean data to new table	
FROM deduplicated
WHERE row_num = 1;																-- Filtering for unique product_id and eliminating the duplicates

-- =======================================================================================================================================
-- Verification checks for the cleaned data
-- =======================================================================================================================================

-- Check row count
SELECT COUNT(*) FROM novamart_campaigns_clean

-- Check how many campaigns were flagged as overspent
SELECT COUNT(*) FROM novamart_campaigns_clean WHERE is_overspent = 1
