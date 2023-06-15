--OLIST DATA EXPLORATION

-- How are payments being made?
WITH order_count AS 
(
SELECT payment_type, COUNT(payment_type) AS number_of_orders
FROM payments 
GROUP BY payment_type
)
SELECT RANK () OVER(ORDER BY number_of_orders DESC) AS order_rank, 
*
FROM order_count;

-- Total orders?
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM payments; 

-- What is the composition of installments being made? (only applicable to credit cards)
SELECT payment_installments, COUNT(payment_installments) AS count_installs
FROM payments
WHERE payment_type = 'credit_card' AND payment_installments > 1
GROUP BY payment_installments;

-- What is the breakdown of repeat customers?
SELECT COUNT(*) AS total_customers, COUNT(DISTINCT customer_unique_id) AS unique_customers, COUNT(*) - COUNT(DISTINCT customer_unique_id) AS repeat_customers
FROM customers;

-- With installments 2016-2018?
SELECT COUNT(*) AS total_orders_with_installments
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE p.payment_type = 'credit_card'
AND DATE(o.order_purchase_timestamp) BETWEEN '2016-01-01' AND '2018-12-31';

-- Total daily purchases made with installments in 2017? (since 2017 is the only full year of data available)
SELECT DATE(order_purchase_timestamp) AS purchase_date, COUNT(*) AS total_orders_with_installments
FROM orders o
JOIN payments p ON o.order_id = p.order_id 
WHERE p.payment_type = 'credit_card' AND p.payment_installments > 1
AND DATE(order_purchase_timestamp) BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY DATE(order_purchase_timestamp);

-- Total daily purchases made in 2017?
SELECT DATE(order_purchase_timestamp) AS purchase_date, COUNT(*) AS total_orders_with_installments
FROM orders o
JOIN payments p ON o.order_id = p.order_id 
WHERE DATE(order_purchase_timestamp) BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY DATE(order_purchase_timestamp);

-- part 2: combine.
SELECT t1.purchase_date, t1.total_orders, t2.total_orders_with_installments
FROM
(
    SELECT DATE(order_purchase_timestamp) AS purchase_date, COUNT(*) AS total_orders
    FROM orders o
    WHERE DATE(order_purchase_timestamp) BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY DATE(order_purchase_timestamp)
) AS t1
JOIN
(
    SELECT DATE(order_purchase_timestamp) AS purchase_date, COUNT(*) AS total_orders_with_installments
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id 
    WHERE p.payment_type = 'credit_card' AND p.payment_installments > 1
    AND DATE(order_purchase_timestamp) BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY DATE(order_purchase_timestamp)
) AS t2
ON t1.purchase_date = t2.purchase_date;

-- part 3: top 15 days of installments.
SELECT DATE(order_purchase_timestamp) AS purchase_date, COUNT(*) AS total_orders_with_installments
FROM orders o
JOIN payments p ON o.order_id = p.order_id 
WHERE p.payment_type = 'credit_card' AND p.payment_installments > 1
AND DATE(order_purchase_timestamp) BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY DATE(order_purchase_timestamp)
ORDER BY 2 DESC
LIMIT 15;

-- Top 10 categories purchased? (count) 
SELECT cnt.product_category_name_english, COUNT(*) AS total_purchases
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON cnt.product_category_name = p.product_category_name 
GROUP BY p.product_category_name
ORDER BY total_purchases DESC
LIMIT 10;

-- Categories making the most revenue?
SELECT cnt.product_category_name_english, ROUND(SUM(oi.price),2) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON p.product_category_name = cnt.product_category_name 
GROUP BY 1
ORDER BY total_revenue DESC;

-- Categories selling the least? (count)
SELECT cnt.product_category_name_english, COUNT(*) AS total_purchases
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON cnt.product_category_name = p.product_category_name 
GROUP BY p.product_category_name
ORDER BY total_purchases 
LIMIT 10;

-- Categories making the least revenue?
SELECT cnt.product_category_name_english, ROUND(SUM(oi.price),2) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON p.product_category_name = cnt.product_category_name 
GROUP BY 1
ORDER BY total_revenue;

-- Top 10 categories purchased on Black Friday? (count)
SELECT cnt.product_category_name_english, COUNT(*) AS total_purchases
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON p.product_category_name = cnt.product_category_name 
JOIN orders o ON o.order_id = oi.order_id 
WHERE DATE(o.order_purchase_timestamp) = '2017-11-24'
GROUP BY 1
ORDER BY total_purchases DESC
LIMIT 10;

-- Top order destination? State? City? Zip code?
SELECT customer_state AS state, customer_city AS city, customer_zip_code_prefix AS zip_code, COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id 
GROUP BY state, city, zip_code
ORDER BY total_orders DESC
LIMIT 10;

-- How many sellers are there on the site?
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;

-- Where are the sellers located?
SELECT seller_state AS state, COUNT(*) AS seller_count
FROM sellers
GROUP BY state
ORDER BY seller_count DESC;

-- Review ratings on Black Friday? Were people happy with their purchases?
SELECT review_score, COUNT(*) AS review_count
FROM order_reviews orev
JOIN orders o ON o.order_id = orev.order_id
WHERE DATE(o.order_purchase_timestamp) = '2017-11-24'
GROUP BY review_score;

-- Calculate CSAT (customer satisfaction score).
SELECT AVG(review_score) AS average_csat
FROM order_reviews or2 
WHERE review_score IS NOT NULL;

-- Rating per category. 
SELECT cnt.product_category_name_english, AVG(review_score) AS average_csat
FROM order_reviews or2 
JOIN order_items oi ON oi.order_id = or2.order_id 
JOIN  products p ON p.product_id = oi.product_id 
JOIN category_name_translation cnt ON cnt.product_category_name = p.product_category_name 
GROUP BY 1
ORDER BY average_csat DESC;

-- AVG rating per state.
SELECT customer_state, AVG(review_score) AS average_csat
FROM order_reviews or2 
JOIN orders o ON o.order_id = or2.order_id 
JOIN customers c ON c.customer_id = o.customer_id 
GROUP BY customer_state
ORDER BY average_csat DESC;


