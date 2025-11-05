SELECT * 
FROM customer;
SELECT * 
FROM customer
ORDER BY customer_last_name, customer_first_name
LIMIT 10;
SELECT *
FROM customer_purchases
WHERE product_id IN (4, 9);
SELECT *,
       (quantity * cost_to_customer_per_qty) AS price
FROM customer_purchases
WHERE customer_id BETWEEN 8 AND 10;
SELECT
  product_id,
  product_name,
  CASE
    WHEN product_qty_type = 'unit' THEN 'unit'
    ELSE 'bulk'
  END AS prod_qty_type_condensed,
  CASE
    WHEN LOWER(product_name) LIKE '%pepper%' THEN 1
    ELSE 0
  END AS pepper_flag
FROM product;
SELECT
  v.vendor_id,
  v.vendor_name,
  v.vendor_type,
  v.vendor_owner_first_name,
  v.vendor_owner_last_name,
  vb.booth_number,
  vb.market_date
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vb
  ON v.vendor_id = vb.vendor_id
ORDER BY
  v.vendor_name,
  vb.market_date;
SELECT
  v.vendor_id,
  v.vendor_name,
  COUNT(vb.booth_number) AS booth_rental_count
FROM vendor AS v
INNER JOIN vendor_booth_assignments AS vb
  ON v.vendor_id = vb.vendor_id
GROUP BY v.vendor_id, v.vendor_name
ORDER BY booth_rental_count DESC;
SELECT
  c.customer_id,
  c.customer_first_name,
  c.customer_last_name,
  SUM(cp.quantity * cp.cost_to_customer_per_qty) AS total_spent
FROM customer AS c
INNER JOIN customer_purchases AS cp
  ON c.customer_id = cp.customer_id
GROUP BY c.customer_id, c.customer_first_name, c.customer_last_name
HAVING total_spent > 2000
ORDER BY c.customer_last_name, c.customer_first_name;


CREATE TEMP TABLE new_vendor AS
SELECT *
FROM vendor;


INSERT INTO new_vendor (
  vendor_id,
  vendor_name,
  vendor_type,
  vendor_owner_first_name,
  vendor_owner_last_name
)
VALUES (
  10,
  'Thomass Superfood Store',
  'Fresh Focused store',
  'Thomas',
  'Rosenthal'
);
SELECT
  customer_id,
  STRFTIME('%m', market_date) AS purchase_month,
  STRFTIME('%Y', market_date) AS purchase_year
FROM customer_purchases;
SELECT
  customer_id,
  SUM(quantity * cost_to_customer_per_qty) AS total_spent_april_2022
FROM customer_purchases
WHERE STRFTIME('%m', market_date) = '04'
  AND STRFTIME('%Y', market_date) = '2022'
GROUP BY customer_id
ORDER BY total_spent_april_2022 DESC;
