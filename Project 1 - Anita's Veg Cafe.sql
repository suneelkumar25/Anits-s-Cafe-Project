-- Create a database for projects
CREATE DATABASE projects;

-- Create schema for Anita's Veg Café
CREATE SCHEMA anitas_veg_cafe;

-- Orders table (same as sales in original)
CREATE TABLE sales (
  "customer_id" VARCHAR(10),
  "order_date" DATE,
  "product_id" INTEGER
);

-- Insert orders data
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('Aarav', '2021-01-01', 1),
  ('Aarav', '2021-01-01', 2),
  ('Aarav', '2021-01-07', 2),
  ('Aarav', '2021-01-10', 3),
  ('Aarav', '2021-01-11', 3),
  ('Aarav', '2021-01-11', 3),
  ('Meera', '2021-01-01', 2),
  ('Meera', '2021-01-02', 2),
  ('Meera', '2021-01-04', 1),
  ('Meera', '2021-01-11', 1),
  ('Meera', '2021-01-16', 3),
  ('Meera', '2021-02-01', 3),
  ('Rohan', '2021-01-01', 3),
  ('Rohan', '2021-01-01', 3),
  ('Rohan', '2021-01-07', 3);

-- Menu table
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(50),
  "price" INTEGER
);

-- Insert menu data
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  (1, 'Paneer Butter Masala', 180),
  (2, 'Veg Biryani', 150),
  (3, 'Masala Dosa', 120);

-- Members table (loyalty customers)
CREATE TABLE members (
  "customer_id" VARCHAR(10),
  "join_date" DATE
);

-- Insert members data
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('Aarav', '2021-01-07'),
  ('Meera', '2021-01-09');
  


SELECT * FROM SALES;

SELECT * FROM MENU;

SELECT * FROM MEMBERS;

-- 1. What is the total amount each customer has spent at the café?

select
	sum(M.price) as Total_Amount,
	S.customer_id as CustomerName
from
	menu as M
inner join
	sales as S	
	on M.product_id=S.product_id
group by S.customer_id;

-- 2. How many distinct days has each customer placed an order? 

select
	count(distinct order_date) as distinct_days,
	customer_id
From
    sales
group by
	customer_id;

-- 3. What was the first dish ordered by each customer?

SELECT 
    distinct(S.customer_id) as coustomer_name,
    M.product_name AS first_dish,
    S.order_date AS first_order
FROM 
    sales S
INNER JOIN 
    menu M ON S.product_id = M.product_id
WHERE 
    S.order_date = (
        SELECT MIN(order_date)
        FROM sales
    )
ORDER BY 
    S.customer_id, S.order_date;

-- 4. Which menu item is the most popular overall?

SELECT
	M.PRODUCT_NAME,
COUNT
	(S.PRODUCT_ID) AS MOST_SALES_PRODUCT
FROM
	MENU M
INNER JOIN
	SALES S ON M.PRODUCT_ID = S.PRODUCT_ID
GROUP BY
	M.PRODUCT_NAME
ORDER BY
	MOST_SALES_PRODUCT DESC LIMIT 1;

-- 5. What is the most frequently ordered dish for each customer?

SELECT 
    s.customer_id,
    m.product_name,
    COUNT(*) AS times_ordered
FROM sales s
JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id, times_ordered DESC;

-- 6. After joining the loyalty program, what dish did each member first order?

-- Type 1.
SELECT customer_id, product_name
FROM (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) rnk
    FROM sales s
    JOIN members mem ON s.customer_id = mem.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE s.order_date > mem.join_date
) t
WHERE rnk = 1;

-- Type 2.
SELECT 
    s.customer_id,
    m.product_name
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date = (
    SELECT MIN(s2.order_date)
    FROM sales s2
    WHERE s2.customer_id = s.customer_id
      AND s2.order_date > mem.join_date
);


-- 7. Before joining the loyalty program, what dish did each customer order last?

-- Type 1

SELECT
	customer_id, product_name
FROM(
	select
		s.customer_id,
		m.product_name,
		s.order_date,
		rank() over (partition by s.customer_id order by order_date) as rnk
		from sales s
		inner join members mem on s.customer_id = mem.customer_id
		inner join menu m on s.product_id = m.product_id
		where s.order_date < mem.join_date
) t
WHERE rnk = 1;

-- 8. For each member, how many items and how much did they spend before joining?

SELECT 
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_amount
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 9. If each ₹1 = 10 points, and Paneer Butter Masala earns double points, how many points does each customer earn? 

SELECT 
    s.customer_id,
    SUM(
        CASE 
            WHEN m.product_name = 'Paneer Butter Masala'
            THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In their first loyalty week (starting from join_date), members earn double points on all items. How many points do Aarav and Meera have by the end of January?

SELECT
    s.customer_id,
    SUM(
        CASE 
            WHEN s.order_date BETWEEN mem.join_date 
                              AND mem.join_date + INTERVAL '6 days'
            THEN m.price * 20
            ELSE 0
        END
    ) AS total_points
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;
