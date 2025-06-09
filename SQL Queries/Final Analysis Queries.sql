--ORDER VOLUME ANALYSIS FORM DAILY TO MONTHLY, CITIES AND STATES

--STATE daily orders

SELECT DISTINCT c.customer_state AS state, pct.english_category, 
	COUNT(o.order_id) OVER(PARTITION BY c.customer_city, c.customer_state, CAST(o.order_purchase_timestamp AS DATE)) AS product_volume, 
	p.product_id, ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) as freight_value,
	ROUND(ROUND(oi.price,2) - ROUND(oi.freight_value,2),2) AS net_value,
	CAST(o.order_purchase_timestamp AS date) AS date
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id JOIN Products p ON oi.product_id=p.product_id JOIN ProductCatgtranslation pct ON p.product_category_name=pct.category_name
WHERE o.order_status IN ('delivered', 'shipped')
ORDER BY date


--CITY daily orders

WITH daily_customer_orders_city AS (
	SELECT c.customer_city AS city, COUNT(o.order_id) AS order_count, CAST(o.order_purchase_timestamp AS Date) AS date
	FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
	WHERE o.order_status IN ('delivered', 'shipped')
	GROUP BY c.customer_city, CAST(o.order_purchase_timestamp AS Date)
),
	daily_customer_orders_city_ranked AS (
	SELECT city, date, order_count
	FROM daily_customer_orders_city
)
SELECT city, order_count, date
FROM daily_customer_orders_city_ranked
ORDER BY date;


--STATE weekly orders

WITH weekly_customer_orders_state AS (
SELECT DISTINCT c.customer_state AS state,
	COUNT(o.order_id) OVER(PARTITION BY c.customer_state, DATEPART(WEEK, (CAST(o.order_purchase_timestamp AS DATE)))) AS order_count,
	DATEPART(WEEK, (CAST(o.order_purchase_timestamp AS DATE))) AS week, YEAR(o.order_purchase_timestamp) as year
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	weekly_customer_orders_state_ranked AS (
	SELECT state, order_count, week, year
	FROM weekly_customer_orders_state
	)
SELECT state, order_count, week, year, CONCAT(year,week) AS sorting_column
FROM weekly_customer_orders_state_ranked
ORDER BY sorting_column;


--CITY weekly orders

WITH weekly_customer_orders_city AS (
SELECT DISTINCT c.customer_city AS city,
	COUNT(o.order_id) OVER(PARTITION BY c.customer_city, DATEPART(WEEK, (CAST(o.order_purchase_timestamp AS DATE)))) AS order_count,
	DATEPART(WEEK, (CAST(o.order_purchase_timestamp AS DATE))) AS week, YEAR(o.order_purchase_timestamp) as year
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	weekly_customer_orders_state_ranked AS (
	SELECT city, order_count, week, year
	FROM weekly_customer_orders_city
	)
SELECT city, order_count, week, year, CONCAT(year,week) AS sorting_column
FROM weekly_customer_orders_state_ranked
ORDER BY sorting_column;


--STATE monthly orders
WITH monthly_customer_orders_state AS (
	SELECT c.customer_state AS state, COUNT(o.order_id) AS order_count, MONTH(o.order_purchase_timestamp) AS month_num,YEAR(o.order_purchase_timestamp) AS year_num
	FROM Orders o JOIN Customers c ON (o.customer_id=c.customer_id)
	WHERE o.order_status IN ('delivered', 'shipped')
	GROUP BY c.customer_state, MONTH(o.order_purchase_timestamp), YEAR(o.order_purchase_timestamp)
),
	monthly_customer_orders_state_ranked AS (
	SELECT state, month_num, year_num, order_count
	FROM monthly_customer_orders_state
)
SELECT state, order_count, month_num, year_num, CONCAT(month_num,'-',year_num) AS month_year
FROM monthly_customer_orders_state_ranked
ORDER BY year_num, month_num;


--CITY monthly orders

WITH monthly_customer_orders_city AS (
	SELECT c.customer_city AS city, COUNT(o.order_id) AS order_count, MONTH(o.order_purchase_timestamp) AS month_num,YEAR(o.order_purchase_timestamp) AS year_num
	FROM Orders o JOIN Customers c ON (o.customer_id=c.customer_id)
	WHERE o.order_status IN ('delivered', 'shipped')
	GROUP BY c.customer_city, MONTH(o.order_purchase_timestamp),YEAR(o.order_purchase_timestamp)
),
	monthly_customer_orders_city_ranked AS (
	SELECT city, month_num, year_num, order_count
	FROM monthly_customer_orders_city
)
SELECT city, order_count, month_num, year_num, CONCAT(month_num,'-',year_num) AS month_year
FROM monthly_customer_orders_city_ranked
ORDER BY year_num, month_num;


--STATE+CITY monthly orders

WITH monthly_customer_orders AS (
SELECT c.customer_city AS city, c.customer_state AS state, COUNT(o.order_id) AS order_count, 
	MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Orders o JOIN Customers c ON (o.customer_id=c.customer_id)
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY c.customer_city, c.customer_state, MONTH(o.order_purchase_timestamp), YEAR(o.order_purchase_timestamp)
),
	monthly_customer_orders_ranked AS (
	SELECT city, state, month_num, year_num, order_count
	FROM monthly_customer_orders
)
SELECT city, state, order_count, month_num, year_num, CONCAT(month_num,'-',year_num) AS month_year
FROM monthly_customer_orders_ranked
ORDER BY year_num, month_num;

------------------------------
--SELLER-CUSTOMER MATCHING ANALYSIS

--MATCHED customer-seller CITIES

SELECT DISTINCT s.seller_city AS city, s.seller_state, COUNT(o.order_id) OVER(PARTITION BY s.seller_city) AS total_matched_city_orders
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id JOIN Sellers s ON oi.seller_id=s.seller_id
	JOIN Customers c ON c.customer_id=o.customer_id
WHERE c.customer_city=s.seller_city AND order_status IN ('delivered', 'shipped')
ORDER BY total_matched_city_orders DESC;



--MATCHED customer-seller STATES

SELECT DISTINCT s.seller_state AS state, COUNT(o.order_id) OVER(PARTITION BY s.seller_state) AS total_matched_state_orders
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id JOIN Sellers s ON oi.seller_id=s.seller_id
	JOIN Customers c ON c.customer_id=o.customer_id
WHERE c.customer_state=s.seller_state AND order_status IN ('delivered', 'shipped')
ORDER BY total_matched_state_orders DESC;


--MATCHED customer-seller CITY+STATE

SELECT DISTINCT s.seller_city, c.customer_city, s.seller_state, c.customer_state, SUM(CASE WHEN c.customer_city=s.seller_city AND c.customer_state=s.seller_state THEN 1 ELSE 0 END) AS total_matched_orders
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id JOIN Sellers s ON oi.seller_id=s.seller_id
	JOIN Customers c ON c.customer_id=o.customer_id
WHERE order_status IN ('delivered', 'shipped')
GROUP BY s.seller_city, c.customer_city, s.seller_state, c.customer_state
ORDER BY total_matched_orders DESC;



------------------------------
--REVENUE ANALYSIS


--STATE monthly gross revenue

WITH monthly_price_table_state AS (
SELECT DISTINCT c.customer_state, o.order_id, oi.product_id,
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_cost, COUNT(oi.product_id) OVER (PARTITION BY o.order_id, oi.product_id) AS order_volume,
	MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	 ranked_gross_revenue_state AS (
	SELECT customer_state AS state, ROUND(SUM(price*order_volume),2) AS monthly_gross, month_num, year_num
	FROM monthly_price_table_state
	GROUP BY customer_state, month_num, year_num
)
SELECT state, monthly_gross, month_num,year_num, CONCAT(month_num,'-',year_num) AS month_year
FROM ranked_gross_revenue_state
ORDER BY year_num, month_num;


--STATE monthly COGS

WITH monthly_price_table_state AS (
SELECT DISTINCT c.customer_state, o.order_id, oi.product_id,
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_cost, COUNT(oi.product_id) OVER (PARTITION BY o.order_id, oi.product_id) AS order_volume,
	 MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	ranked_cogs_state AS (
	SELECT customer_state AS state, ROUND(SUM(freight_cost*order_volume),2) AS monthly_cogs, month_num, year_num
	FROM monthly_price_table_state
	GROUP BY customer_state, month_num, year_num
)
SELECT state, monthly_cogs, month_num, year_num, CONCAT(month_num,'-',year_num) AS month_year
FROM ranked_cogs_state
ORDER BY year_num, month_num;


--STATE monthly NET revenue

WITH monthly_price_table_state AS (
SELECT DISTINCT c.customer_state, o.order_id, oi.product_id,
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_cost, COUNT(oi.product_id) OVER (PARTITION BY o.order_id, oi.product_id) AS order_volume, CAST(o.order_purchase_timestamp AS DATE) AS order_date
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	ranked_net_revenue AS (
	SELECT customer_state AS state, ROUND(SUM(price*order_volume)-SUM(freight_cost*order_volume),2) AS monthly_net_revenue, order_date
	FROM monthly_price_table_state
	GROUP BY customer_state, order_date
)
SELECT state, monthly_net_revenue, order_date
FROM ranked_net_revenue
ORDER BY order_date;


--STATE monthly NET revenue share

WITH monthly_price_table_state AS (
SELECT DISTINCT c.customer_state, o.order_id, oi.product_id,
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_cost, COUNT(oi.product_id) OVER (PARTITION BY o.order_id, oi.product_id) AS order_volume,
	 MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Customers c ON o.customer_id=c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
),
	ranked_net_revenue AS (
	SELECT customer_state AS state, ROUND(SUM(price*order_volume)-SUM(freight_cost*order_volume),2) AS monthly_net_revenue_state, 
	SUM(ROUND(SUM(price*order_volume),2)-ROUND(SUM(freight_cost*order_volume),2)) OVER(PARTITION BY month_num, year_num) AS total_monthly_net_revenue,month_num, year_num
	FROM monthly_price_table_state
	GROUP BY customer_state, month_num, year_num
)
SELECT state, ROUND(monthly_net_revenue_state/total_monthly_net_revenue,3)*100.0 AS percent_share_of_monthly_net_revenue, month_num, year_num
FROM ranked_net_revenue
ORDER BY year_num, month_num;


------------------------------
--LATE DELIVERY & LOGISTICS

--RAW TABLE for late deliveries

SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, p.product_id, pct.english_category, ROUND(oi.price,2) AS price, (CAST(p.product_length_cm AS int)*p.product_height_cm*p.product_width_cm) AS product_volume_cubed, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
ORDER BY days_late ASC;


--RAW STATE deliveries and dates

SELECT c.customer_state AS state, CAST(o.order_estimated_delivery_date AS DATE) AS estimated_delivery_date,
	CAST(o.order_delivered_customer_date AS DATE) AS delivered_date, 
	DATEDIFF(DAY, CAST(o.order_estimated_delivery_date AS DATE), CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
WHERE order_delivered_customer_date > order_estimated_delivery_date AND
	DATEDIFF(DAY, CAST(o.order_estimated_delivery_date AS DATE), CAST(o.order_delivered_customer_date AS DATE))!=0

--SUMMARY CARD late deliveries by location matching

WITH general_info_late_products AS (
SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, p.product_id, pct.english_category, ROUND(oi.price,2) AS price, (p.product_length_cm*p.product_height_cm) AS product_size, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
)
SELECT SUM(CASE WHEN customer_city=seller_city AND customer_state=seller_state THEN 1 ELSE 0 END) AS same_city_and_state_late_deliveries,
	SUM(CASE WHEN customer_city!=seller_city AND customer_state=seller_state THEN 1 ELSE 0 END) AS not_same_city_same_state_late_deliveries,
	SUM(CASE WHEN customer_city!=seller_city AND customer_state!=seller_state THEN 1 ELSE 0 END) AS not_same_city_or_state_late_deliveries,
	COUNT(*) AS total_late_deliveries
FROM general_info_late_products;


--MONTHLY late order distribution

WITH general_info_late_products_date AS (
SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, o.order_approved_at AS date_order_confirmed,
	p.product_id, pct.english_category, ROUND(oi.price,2) AS price, 
		(p.product_length_cm*p.product_height_cm) AS product_size, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
)
SELECT DISTINCT customer_state, DATEFROMPARTS(YEAR(date_order_confirmed), MONTH(date_order_confirmed), 1) AS order_date, COUNT(*) OVER(PARTITION BY MONTH(date_order_confirmed), YEAR(date_order_confirmed), customer_state) AS count_late_orders
FROM general_info_late_products_date
ORDER BY order_date;


--SUMMARY CARD of monthly late orders

WITH general_info_late_products_date AS (
SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, o.order_approved_at AS date_order_confirmed,
	p.product_id, pct.english_category, ROUND(oi.price,2) AS price, 
		(p.product_length_cm*p.product_height_cm) AS product_size, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
),
	month_and_count_late AS (
SELECT DISTINCT MONTH(date_order_confirmed) AS month_of_order, COUNT(*) OVER(PARTITION BY MONTH(date_order_confirmed)) AS count_late_orders
FROM general_info_late_products_date
),
	count_of_total_orders AS (
SELECT DISTINCT MONTH(order_approved_at) AS month_of_order, COUNT(order_id) AS count_total_orders
FROM Orders
WHERE MONTH(order_approved_at) IS NOT NULL
GROUP BY MONTH(order_approved_at)
)
SELECT cto.month_of_order, mcl.count_late_orders, cto.count_total_orders, ROUND(100*CAST(mcl.count_late_orders AS float)/cto.count_total_orders, 2) AS month_share_of_late_orders
FROM count_of_total_orders cto JOIN month_and_count_late mcl ON cto.month_of_order=mcl.month_of_order
ORDER BY month_of_order;

--RAW product, weight, size, late table

WITH general_info_late_products AS (
SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, o.order_approved_at AS date_order_confirmed,
	p.product_id, pct.english_category, ROUND(oi.price,2) AS price, 
		(p.product_length_cm*p.product_height_cm) AS product_size, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
),
	categories_weight_size_late_deliveries AS (
	SELECT DISTINCT product_id, english_category, product_weight_g, product_size AS product_size_cm2, days_late
	FROM general_info_late_products
)
SELECT *
FROM categories_weight_size_late_deliveries;


--SUMMARY CARD for product weight, size, and days late

WITH general_info_late_products AS (
SELECT c.customer_city, s.seller_city, c.customer_state, s.seller_state, o.order_approved_at AS date_order_confirmed,
	p.product_id, pct.english_category, ROUND(oi.price,2) AS price, 
		(CAST(p.product_length_cm AS INT)*p.product_height_cm*p.product_width_cm) AS product_size, product_weight_g, DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) AS days_late
FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p ON p.product_id=oi.product_id JOIN Sellers s ON s.seller_id=oi.seller_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
WHERE DATEDIFF(DAY, o.order_estimated_delivery_date, CAST(o.order_delivered_customer_date AS DATE)) > 0
),
	categories_weight_size_late_deliveries AS (
	SELECT DISTINCT product_id, english_category, product_weight_g, product_size AS product_size_cm2, days_late
	FROM general_info_late_products
)
SELECT DISTINCT english_category, 
	AVG(product_weight_g) OVER(PARTITION BY english_category) AS avg_product_weight_g, 
	CEILING(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g) OVER (PARTITION BY english_category)) AS median_product_weight_g, 
	AVG(product_size_cm2) OVER(PARTITION BY english_category) AS avg_product_size_cm3, 
	CEILING(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_size_cm2) OVER (PARTITION BY english_category)) AS median_product_size_cm3, 
	AVG(days_late) OVER(PARTITION BY english_category) AS avg_days_late,
	CEILING(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_late) OVER (PARTITION BY english_category)) AS median_days_late
FROM categories_weight_size_late_deliveries
ORDER BY median_days_late DESC;


------------------------------
--PRODUCT ANALYSIS


--STATE monthly popular product categories

WITH product_category_popularity AS (
SELECT DISTINCT c.customer_state, pct.english_category, COUNT(o.order_id) OVER(PARTITION BY c.customer_state, pct.english_category) AS count_product_type,
	MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Customers c JOIN Orders o ON c.customer_id=o.customer_id JOIN OrderItems oi ON oi.order_id=o.order_id
JOIN Products p ON p.product_id=oi.product_id JOIN ProductCatgtranslation pct ON p.product_category_name=pct.category_name
),
	ranked_product_categories_state AS (
	SELECT DISTINCT customer_state, english_category, count_product_type, month_num, year_num
	FROM product_category_popularity
	GROUP BY customer_state, english_category, count_product_type, month_num, year_num
)
SELECT customer_state, english_category, count_product_type AS ordered_volume, month_num, year_num, DATEFROMPARTS(year_num,month_num, 1) AS full_date
FROM ranked_product_categories_state
ORDER BY full_date, customer_state;


--STATE profitable products

WITH price_freight_profit_table AS (
SELECT c.customer_state, s.seller_state,
		c.customer_city, s.seller_city, oi.order_item_id,
		o.order_id, oi.product_id, 
		pct.english_category, COUNT(oi.product_id) OVER(PARTITION BY c.customer_state, oi.product_id) AS product_count_state, 
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_value, 
	ROUND(oi.price,2)-ROUND(oi.freight_value,2) AS profit_from_unit
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id JOIN Customers c ON o.customer_id=c.customer_id JOIN Sellers s ON oi.seller_id=s.seller_id
	JOIN Products p ON p.product_id=oi.product_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
),
 	ranked_price_freight_profit_table AS (
	SELECT customer_state, product_id, english_category, ROUND(SUM(profit_from_unit),2) AS total_profit_per_product_id
	FROM price_freight_profit_table
	GROUP BY customer_state, product_id, english_category
)
SELECT customer_state, english_category, product_id, total_profit_per_product_id
FROM ranked_price_freight_profit_table
ORDER BY customer_state, total_profit_per_product_id DESC;


--STATE monthly profitable product categories

WITH monthly_price_table_state AS (
SELECT DISTINCT c.customer_state, o.order_id, oi.product_id, pct.english_category,
	ROUND(oi.price,2) AS price, ROUND(oi.freight_value,2) AS freight_cost, COUNT(oi.product_id) OVER (PARTITION BY o.order_id, oi.product_id) AS order_volume,
	MONTH(o.order_purchase_timestamp) AS month_num, YEAR(o.order_purchase_timestamp) AS year_num
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Customers c ON o.customer_id=c.customer_id JOIN Products p ON oi.product_id=p.product_id JOIN ProductCatgtranslation pct ON p.product_category_name=pct.category_name
WHERE o.order_status IN ('delivered', 'shipped')
),
	ranked_net_revenue AS (
	SELECT customer_state AS state, english_category, ROUND(SUM(price*order_volume)-SUM(freight_cost*order_volume),2) AS monthly_net_revenue, month_num, year_num
	FROM monthly_price_table_state
	GROUP BY customer_state, month_num, year_num, english_category
)
SELECT state, english_category, monthly_net_revenue, month_num, year_num, DATEFROMPARTS(year_num, month_num, 1) AS full_date 
FROM ranked_net_revenue
ORDER BY year_num, month_num;


--OVERALL ranked product categories

WITH ranked_total_volume_catg AS (
SELECT pct.english_category, COUNT(pct.english_category) AS volume_of_product_catg,
	DENSE_RANK() OVER(ORDER BY COUNT(pct.english_category) DESC) AS catg_rank
FROM Orders o JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p on oi.product_id=p.product_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
GROUP BY pct.english_category
)
SELECT english_category, volume_of_product_catg, catg_rank
FROM ranked_total_volume_catg
ORDER BY volume_of_product_catg DESC, catg_rank DESC;


--STATE popular product categories ranked by volume

WITH ranked_total_volume_catg AS (
SELECT c.customer_state, pct.english_category, COUNT(pct.english_category) AS volume_of_product_catg,
	DENSE_RANK() OVER(PARTITION BY c.customer_state ORDER BY COUNT(pct.english_category) DESC) AS catg_rank
FROM Customers c JOIN Orders o ON c.customer_id=o.customer_id JOIN OrderItems oi ON o.order_id=oi.order_id
	JOIN Products p on oi.product_id=p.product_id JOIN ProductCatgtranslation pct ON pct.category_name=p.product_category_name
GROUP BY c.customer_state, pct.english_category
)
SELECT customer_state, english_category, volume_of_product_catg, catg_rank
FROM ranked_total_volume_catg
ORDER BY customer_state, volume_of_product_catg DESC, catg_rank DESC;

--STATE ranked payment methods

WITH counts_payment_type_state AS (
SELECT DISTINCT c.customer_state, op.payment_type, COUNT(*) OVER(PARTITION BY c.customer_state, op.payment_type, CAST(o.order_purchase_timestamp AS DATE)) AS count_payment_type, CAST(o.order_purchase_timestamp AS DATE) AS order_date
FROM Customers c JOIN Orders o ON c.customer_id=o.customer_id JOIN OrderPayments op ON o.order_id=op.order_id
),
	ranked_payment_type_state AS (
	SELECT customer_state, payment_type, SUM(count_payment_type) AS total_count
	FROM counts_payment_type_state
	GROUP BY customer_state, payment_type
)
SELECT customer_state, payment_type, total_count, ROW_NUMBER() OVER(PARTITION BY customer_state ORDER BY total_count DESC) AS payment_type_rank
FROM ranked_payment_type_state
ORDER BY customer_state, total_count DESC;