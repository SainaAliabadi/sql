Write SQL
COALESCE
#Our favourite manager wants a detailed long list of products, but is afraid of tables! We tell them, no problem! 
#We can produce a list with all of the appropriate details.
#Using the following syntax you create our super cool and not at all needy manager a list:
SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product
#But wait! The product table has some bad data (a few NULL values). 
#Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with nulls, 
and 'unit' for the second column with nulls.

SELECT
  product_name
  || ', '
  || COALESCE(product_size, '')                -- first NULL -> blank
  || ' ('
  || COALESCE(product_qty_type, 'unit')        -- second NULL -> 'unit'
  || ')' AS product_display
FROM product;

#Windowed Functions
-- 1) build distinct visits per customer then number them
WITH visits AS (
  SELECT DISTINCT customer_id, market_date
  FROM customer_purchases
)
SELECT
  customer_id,
  market_date,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number
FROM visits
ORDER BY customer_id, market_date;

SELECT
  customer_id,
  market_date,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS rn_desc
FROM (
  SELECT DISTINCT customer_id, market_date
  FROM customer_purchases
) AS distinct_visits
ORDER BY customer_id, market_date DESC;

WITH numbered_visits AS (
  SELECT
    customer_id,
    market_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS rn_desc
  FROM (
    SELECT DISTINCT customer_id, market_date
    FROM customer_purchases
  )
)
SELECT *
FROM numbered_visits
WHERE rn_desc = 1
ORDER BY customer_id;


#Using a COUNT() window function, include a value along with each row of the customer_purchases 
table that indicates how many different times that customer has purchased that product_id.

WITH distinct_customer_product_dates AS (
  SELECT
    customer_id,
    product_id,
    market_date
  FROM customer_purchases
  GROUP BY customer_id, product_id, market_date
),


counts AS (
  SELECT
    customer_id,
    product_id,
    COUNT(*) AS times_purchased_distinct_dates
  FROM distinct_customer_product_dates
  GROUP BY customer_id, product_id
)


SELECT
  cp.*,
  c.times_purchased_distinct_dates
FROM customer_purchases cp
LEFT JOIN counts c
  ON cp.customer_id = c.customer_id
  AND cp.product_id = c.product_id
ORDER BY cp.customer_id, cp.product_id, cp.market_date;


#String manipulations
SELECT
  product_name,
  CASE
    WHEN INSTR(product_name, '-') > 0 THEN
      TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
    ELSE
      NULL
  END AS description_after_hyphen
FROM product
WHERE INSTR(product_name, '-') > 0;  -- optionally filter only rows that have a hyphen

#Filter the query to show any product_size value that contain a number with REGEXP.
SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';

#UNION
Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

WITH totals AS (
  SELECT
    market_date,
    SUM(cost_to_customer_per_qty) AS total_sales
  FROM customer_purchases
  GROUP BY market_date
),
ranked AS (
  SELECT
    market_date,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS rank_desc,   -- 1 = highest
    RANK() OVER (ORDER BY total_sales ASC) AS rank_asc       -- 1 = lowest
  FROM totals
)
-- pick highest total_sales days (rank_desc = 1) union lowest (rank_asc = 1)
SELECT 'best_day' AS which, market_date, total_sales
FROM ranked
WHERE rank_desc = 1

UNION

SELECT 'worst_day' AS which, market_date, total_sales
FROM ranked
WHERE rank_asc = 1
ORDER BY which;


Section 3:

#Cross Join

WITH vp AS (
  SELECT
    v.vendor_id,
    v.vendor_name,
    p.product_id,
    p.product_name,
    v.original_price
  FROM vendor_inventory vi
  JOIN vendor v ON vi.vendor_id = v.vendor_id
  JOIN product p ON vi.product_id = p.product_id
  GROUP BY v.vendor_id, v.vendor_name, p.product_id, p.product_name, v.original_price
),
cust AS (
  SELECT customer_id FROM customer
)
-- Cross join vp with every customer and sum 5 * price for each cross row
SELECT
  vp.vendor_name,
  vp.product_name,
  SUM(5 * vp.original_price) AS projected_revenue     -- each cross-row contributes 5*price
FROM vp
CROSS JOIN cust
GROUP BY vp.vendor_id, vp.product_id, vp.vendor_name, vp.product_name
ORDER BY vp.vendor_name, vp.product_name;

#INSERT
Create a new table "product_units".
DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS
SELECT
  p.*,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product p
WHERE product_qty_type = 'unit';


PRAGMA table_info(product_units);
SELECT * FROM product_units LIMIT 10;

#Using INSERT, add a new row to the product_unit 
INSERT INTO product_units
SELECT
  p.*,
  CURRENT_TIMESTAMP
FROM product p
WHERE p.product_name = 'Apple Pie'   -- change product name if needed
LIMIT 1;

#DELETE
DELETE FROM product_units
WHERE product_name = 'Apple Pie'
  AND snapshot_timestamp < (
    SELECT MAX(snapshot_timestamp)
    FROM product_units pu2
    WHERE pu2.product_name = product_units.product_name
  );
  
  #UPDATE
  ALTER TABLE product_units
ADD current_quantity INT;


SELECT
  product_id,
  quantity,
  market_date
FROM vendor_inventory
WHERE (product_id, market_date) IN (
  SELECT product_id, MAX(market_date)
  FROM vendor_inventory
  GROUP BY product_id
);
UPDATE product_units
SET current_quantity = COALESCE(
  (
    SELECT vi.quantity
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
    ORDER BY vi.market_date DESC
    LIMIT 1
  ),
  0
);

