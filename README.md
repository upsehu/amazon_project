# Amazon INDIA Sales Analysis project <img width="317" height="159" alt="image" src="https://github.com/user-attachments/assets/e9e77f2f-b2ee-471f-b0f7-fc3d89c9df59" />

## Difficulty Level: Advanced
---
### Project Overview
I have worked on analyzing a dataset of over 20,000 sales records from an Amazon-like e-commerce platform. This project involves extensive querying of customer behavior, product performance, and sales trends using PostgreSQL. Through this project, I have tackled various SQL problems, including revenue analysis, customer segmentation, and inventory management.

The project also focuses on data cleaning, handling null values, and solving real-world business problems using structured queries.

An ERD diagram is included to visually represent the database schema and relationships between tables.

---
### Database setup & design
#### schema Structure

---
```SQL
-- we are creating parent table first 
-- category table 
CREATE TABLE category
(category_id INT PRIMARY KEY,
category_name VARCHAR(25) -- EXCEL =MAX(LEN(C1:Clast))give max character length
);

-- coustomer table 
CREATE TABLE customers
(customer_id int PRIMARY KEY,
first_name varchar(35),
last_name varchar(35),
state varchar(20),
-- lets add address column 
address varchar(5) DEFAULT ('XXX')  -- WHEN no value add this xxx as default address
);

DROP TABLE coustomers;

-- create seller table 
CREATE TABLE sellers(
seller_id int PRIMARY KEY,
seller_name	VARCHAR(35),
origin VARCHAR(10)
);

-- products table
CREATE TABLE products (
product_id int PRIMARY KEY,
product_name VARCHAR(50),
price FLOAT,
cogs	FLOAT,
category_id INT,-- FK
CONSTRAINT products_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- ALTER TABLE products
-- ALTER product_id TYPE VARCHAR(20);
-- TO change primary key data from parent table

-- step 1 unlock 
-- remove lock  1 with child table
ALTER TABLE inventary
DROP CONSTRAINT inventary_fk_products;
-- lock 2 

ALTER TABLE order_items
DROP CONSTRAINT orderitem_fk_products;

-- step 2 change in parent table
ALTER TABLE products
ALTER COLUMN product_id TYPE VARCHAR(10);

-- step 3 
-- child 1 change
ALTER TABLE inventary
ALTER COLUMN product_id TYPE VARCHAR(10);

-- child 2 change
ALTER TABLE order_items
ALTER COLUMN product_id TYPE VARCHAR(10);

-- step 4
-- recreate constraints for all childs
ALTER TABLE inventary
ADD CONSTRAINT inventary_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT orderitem_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id);

-- order table
CREATE TABLE  orders 
(order_id	INT PRIMARY KEY,
order_date	DATE, 
customer_id	INT, -- FK
seller_id	INT, -- FK
order_status VARCHAR(15),
CONSTRAINT  order_fk_costumer FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
CONSTRAINT order_fk_sellers FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);
-- to drop constraint
ALTER TABLE orders
DROP CONSTRAINT order_fk_costumer;

-- to add constraint again
ALTER TABLE orders
ADD CONSTRAINT  order_fk_costumer FOREIGN KEY(customer_id) REFERENCES customers(customer_id);

-- inventary table 
CREATE TABLE inventary(
inventory_id INT PRIMARY KEY,
product_id	INT,--FK
stock INT,
warehouse_id INT,	
last_stock_date DATE,
CONSTRAINT inventary_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ORDER_ITEMS TABLE
CREATE TABLE order_items 
(order_item_id	INT PRIMARY KEY,
order_id	INT, --FK
product_id	INT,--FK
quantity	INT,
price_per_unit FLOAT,
CONSTRAINT orderitem_fk_orders FOREIGN KEY(order_id) references orders(order_id),
CONSTRAINT orderitem_fk_products FOREIGN KEY(product_id) REFERENCES products(product_id)
);


-- payment table 
CREATE TABLE payments(     
payment_id	INT PRIMARY KEY,
order_id	INT,--- FK
payment_date	DATE,
payment_status VARCHAR(20),
CONSTRAINT payments_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- shipping table 
CREATE TABLE shipping(
shipping_id	INT PRIMARY KEY,
order_id	INT,-- FK
shipping_date DATE,
return_date	DATE,
shipping_provider VARCHAR(15),
shipping_status VARCHAR(15),
CONSTRAINT shipping_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

ALTER TABLE shipping
ALTER COLUMN shipping_provider TYPE VARCHAR(20);
```

---

### Task: Data Cleaning
#### I cleaned the dataset by:
---
- **Removing duplicates:** Duplicates in the customer and order tables were identified and removed.

- **Handling missing values:** Null values in critical fields (e.g., customer address, payment status) were either filled with default values or handled using appropriate methods.

# Handling Null Values
**Null values were handled based on their context:**

- **Customer addresses:** Missing addresses were assigned default placeholder values.

- **Payment statuses:** Orders with null payment statuses were categorized as "Pending."

- **Shipping information:** Null return dates were left as is, as not all shipments are returned.

---

### Identifying & Solving Business Problems
#### Solutions Implemented:
---

- **Restock Prediction:** Forecasting inventory needs to maintain optimal stock levels.

- **Product Performance:** Analyzing sales data to determine how well specific products are performing.

- **Shipping Optimization:** Improving logistics and delivery efficiency.

- **Customer Segmentation:** Categorizing customers based on purchasing behavior for better targeting.

---
### Solving Business Problems

--------------------------------------------
-- BUSINESS PROBLEMS 
-- ADVANCE ANALYSIS
--------------------------------------------

1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
```sql
SELECT * FROM order_items;

-- creating new column 
ALTER TABLE order_items
ADD COLUMN total_sales FLOAT;

-- updating  price(total_sales)=qty* price per unit
UPDATE order_items
SET total_sales = quantity* price_per_unit;


SELECT 
oi.product_id, 
p.product_name,
SUM(oi.total_sales)  as total_sale,
COUNT(o.order_id) as total_ordercount

FROM orders as o
join
order_items as oi
ON oi.order_id = o.order_id
JOIN
products as p 
ON p.product_id= oi.product_id

GROUP BY 1, 2
-- here what be need top 10 products
ORDER BY 3 DESC
LIMIT 10; 
```

2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
```sql
-- what we need category_id,total revenue, total contribution
-- oi -- products -- cate (joing)
SELECT 
  p.category_id,
  c.category_name,
  SUM(oi.total_sales) as Total_sale, -- NEEDED AS AGGREGATED SUM
  SUM(oi.total_sales)/(SELECT SUM(total_sales) from order_items)*100

FROM order_items as oi
JOIN 
products as p
ON oi.product_id= p.product_id -- we need all prodcts id or names so left join,what happen category aake jud jayega, extra rows mai null fill ho jayega
LEFT JOIN  category as c
On c.category_id = p.category_id

GROUP BY 1,2
ORDER BY 3 DESC;
```

3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
```sql
SELECT 
c.customer_id,
CONCAT(c.first_name,' ', c.last_name) as full_name,
SUM(total_sales)/COUNT(o.order_id) as AOV,
COUNT(o.order_id) as total_orders -- here we need filter

FROM orders as o
JOIN
customers as c
on o.customer_id = c.customer_id
JOIN
order_items as oi
On o.order_id = oi.order_id

GROUP BY 1, 2
HAVING COUNT(o.order_id)>5;
```

4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
```sql
SELECT 
     year,
	 months,
	 total_sale as current_month_sale,
	 LAG(total_sale, 1) over ( ORDER BY year, months) AS last_month_sale
FROM
(SELECT 
 EXTRACT(MONTH FROM o.order_date) as months,
  EXTRACT(YEAR FROM o.order_date) as year,
 -- SUM(oi.total_sales) as total_sale,
  ROUND(
         SUM(oi.total_sales::numeric)
		 ,2) as total_sale

FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
WHERE order_date>= CURRENT_DATE- INTERVAL '2 year'
GROUP BY 1,2
ORDER BY Year, months)
```

5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
```sql
-- APPROCH - 1
SELECT * 
  -- reg-date - current_date
FROM customers
WHERE customer_id NOT IN (SELECT 
                     DISTINCT customer_id
					 FROM orders); 

-- APPROCH - 2
SELECT * 
FROM customers AS c
LEFT JOIN
orders as o 
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;
```

6. Least-Selling Categories by State
Identify the best-selling product category for each state.
Challenge: Include the total sales for that category within each state.
```sql
WITH ranking_table
AS
(SELECT 
c.state,
ct.category_name,
SUM(oi.total_sales) as total_sale,
RANK() OVER (PARTITION BY c.state ORDER BY  SUM(oi.total_sales) DESC) as rank

FROM orders as o
JOIN 
customers as c 
ON o.customer_id = c.customer_id
JOIN
order_items as oi 
ON  o.order_id = oi.order_id
JOIN
products as p 
ON oi.product_id = p.product_id
JOIN
category as ct
on ct.category_id = p.category_id

GROUP BY 1,2 
ORDER BY 1,3 DESC)

SELECT  *
FROM ranking_table
WHERE rank = 1;
```

7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
```sql
SELECT 
c.customer_id,
CONCAT(c.first_name,' ', c.last_name) as full_name,
SUM(total_sales) as CLTV,
DENSE_RANK() OVER(ORDER BY SUM(total_sales) DESC) as c_ranking


FROM orders as o
JOIN
customers as c
on o.customer_id = c.customer_id
JOIN
order_items as oi
On o.order_id = oi.order_id

GROUP BY 1, 2
ORDER BY 3 DESC;
```

8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
```sql
SELECT 
i.inventory_id,
p.product_name,
i.stock as current_stock_left,
i.last_stock_date,
i.warehouse_id

FROM 
inventary as i
JOIN
products as p 
On p.product_id = i.product_id
WHERE stock < 10
```

9. Shipping Delays
Identify orders where the shipping date is later than 7 days after the order date.
Challenge: Include customer, order details, and delivery provider.
```sql
SELECT 
c.*,
o.*,
s.shipping_provider


FROM orders as o 
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN
shipping as s 
on o.order_id = s.order_id
WHERE s.shipping_date - o.order_date >4
```

10. Payment Success Rate
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
```sql
SELECT 
p.payment_status,
COUNT(*) AS total_cnt,
COUNT(*)/(SELECT COUNT(*) FROM payments ):: numeric *100

FROM 
orders as o
JOIN 
payments as p
ON o.order_id = p.payment_id

GROUP BY 1
```

11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
```sql
WITH top_seller
AS
 (SELECT 
 s.seller_id,
 s.seller_name,
 SUM(oi.total_sales) as total_sale
 
 FROM orders as o 
 Join 
 sellers as s 
 On o.seller_id = s.seller_id
JOIN 
order_items as oi 
On oi.order_id = o.order_id
GROUP BY 1,2 
ORDER BY 3 DESC
LIMIT 5),

seller_report
AS 
(SELECT 
o.seller_id,
ts. seller_name,
o.order_status,
COUNT(*) as total_orders
FROM orders as o
JOIN
top_seller as ts
On o.seller_id = ts.seller_id
WHERE 
o.order_status NOT IN ('Cancelled','Pending', 'Returned','Shipped')

GROUP BY 1,2,3)

SELECT 
seller_id,
seller_name,
SUM(CASE WHEN order_status ='Delivered'THEN total_orders ELSE 0 END) as completed_orders,
SUM(CASE WHEN order_status= 'Cancelled' THEN total_orders ELSE 0 END) as cancelled_orders,
SUM( total_orders) AS total_orders,
ROUND((SUM(CASE WHEN order_status ='Delivered'THEN total_orders ELSE 0 END)::numeric/
SUM(total_orders)::numeric *100 ), 2)as successfull_order_percentage

-- ROUND ((successfull_order_percentage::numeric) ,2) as successorderpercentage


FROM seller_report

GROUP BY 1,2;
```

12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
```sql
SELECT 
p.product_id,
p.product_name,
SUM(total_sales - (p.cogs *oi.quantity)) as profit,
SUM(total_sales - (p.cogs *oi.quantity)) / SUM (total_sales)*100 as profit_margin,

DENSE_RANK() OVER(ORDER BY SUM(total_sales - (p.cogs *oi.quantity)) DESC) AS product_ranking

FROM 
orders as o
JOIN 
order_items as oi
ON o.order_id = oi.order_id
JOIN
products as p
ON oi.product_id = p.product_id
GROUP BY 1,2
```

13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
```sql
SELECT 
p.product_id,
p.product_name,
COUNT(*) as total_unit_sold,
SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END ) as total_returned,
ROUND((SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END )::numeric/ COUNT(*) *100 ),2) AS returned_percentage
FROM 
products as p
JOIN 
order_items as oi
ON p.product_id = oi.product_id
join
orders as o
ON o.order_id = oi.order_id
GROUP By 1,2
ORDER BY 5  DESC
```

15. Inactive Sellers
Identify sellers who haven't made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
```sql
WITH ctel 
AS-- as these sellers has not done any sale in last 6 months 
(
SELECT * FROM sellers
WHERE seller_id NOT IN (SELECT seller_id FROM orders WHERE order_date >=CURRENT_DATE-INTERVAL '6 month')
)

SELECT 
o.seller_id,
MAX(o.order_date)as last_sales_date,
MAX(oi.total_sales) as last_sale_amount

FROM orders as o
JOIN
ctel
ON ctel.seller_id = o.seller_id
join
order_items as oi
ON o.order_id = oi.order_id
GROUP BY 1
```

16. Identify Customers into Returning or New
If the customer has done more than 5 returns, categorize them as returning, otherwise new.
Challenge: List customer id, name, total orders, total returns.
```sql
SELECT 
full_name as customers,
total_order,
total_return,
CASE WHEN  total_return >5 THEN 'Returning_customer' ELSE'New'END as cx_category


FROM
(SELECT
 CONCAT(c.first_name, ' ', c.last_name) AS full_name,
 COUNT (o.order_id) AS total_order,
 SUM(CASE WHEN  o.order_status = 'Returned'THEN 1 ELSE 0 END) AS total_return
 
FROM orders as o 
JOIN 
customers as c 
ON c.customer_id = o.customer_id
JOIN 
 order_items as oi 
ON oi.order_id = o.order_id
GROUP BY 1
 )
```

17. Cross-Sell Opportunities
Find customers who purchased product A but not product B (e.g., customers who bought AirPods but not AirPods Max).
Challenge: Suggest cross-sell opportunities by displaying matching product categories.
```sql
SELECT 
c.state,
CONCAT(c.first_name, ' ', c.last_name) AS full_name,
COUNT(o.order_id) as total_orders,
SUM(total_sales) as total_sale,
DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id)DESC) as rank

FROM 
orders as o 
JOIN 
order_items as oi 
ON oi.order_id = o.order_id
JOIN 
customers as c 
ON  c.customer_id= o.customer_id
GROUP BY 1,2
```

18. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
```sql
SELECT * FROM

(SELECT 
c.state,
CONCAT(c.first_name, ' ', c.last_name) AS full_name,
COUNT(o.order_id) as total_orders,
SUM(total_sales) as total_sale,
DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id)DESC) as rank

FROM 
orders as o 
JOIN 
order_items as oi 
ON oi.order_id = o.order_id
JOIN 
customers as c 
ON  c.customer_id= o.customer_id
GROUP BY 1,2
)
WHERE RANK >=5
```

19. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
```sql
SELECT 
s.shipping_provider,
COUNT(o.order_id) as order_handle,
SUM(oi.total_sales) as total_sale,
--AVG(s.return_date - s.shipping_date) as avg_days
COALESCE(AVG(s.return_date-s.shipping_date),0) as average_days

FROM 
orders as o 
JOIN 
 order_items as oi 
ON oi.order_id = o.order_id
JOIN 
shipping as s 
ON s.order_id = o.order_id
GROUP BY 1
```

20. Top 10 Products with Highest Decreasing Revenue Ratio (2022 vs 2023)
Compare current year revenue against last year revenue for each product.
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio, rounded at the end.
Note: Decrease ratio = (cr - ls) / ls * 100 (cr = current_year, ls = last_year)
```sql
WITH last_year_sale
AS
(SELECT 
p.product_id,
p.product_name,
SUM(oi.total_sales) as revenue

FROM 
orders as o 
JOIN 
order_items as oi 
ON oi.order_id = o.order_id
JOIN 
products as p 
ON oi.product_id = p.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1,2
),
current_year_sale
AS
(SELECT 
p.product_id,
p.product_name,
SUM(oi.total_sales) as revenue

FROM 
orders as o 
JOIN 
order_items as oi 
ON oi.order_id = o.order_id
JOIN 
products as p 
ON oi.product_id = p.product_id
WHERE EXTRACT  (YEAR FROM o.order_date) = 2024
GROUP BY 1,2)

SELECT 
cs.product_id,
ls.revenue as last_year_revenue,
cs.revenue as current_year_revenue,
cs.revenue -ls.revenue as rev_diff,
(cs.revenue - ls.revenue)::numeric/ ls.revenue::numeric *100 as revenue_dec_ratio
FROM 
last_year_sale as ls
JOIN
current_year_sale as cs
ON ls.product_id = cs.product_id
WHERE ls.revenue >cs.revenue
ORDER BY 5 DESC
LIMIT 10
```

Final Task — Stored Procedure
Create a function so that as soon as a product is sold, the same quantity is reduced from the inventory table. After adding any sales record, it should update the stock in the inventory table based on the product and quantity purchased.
```sql
SELECT * FROM products
-- product_id B07JW9H4J1--wayona nylon
-- Ambrane Unbreakable
SELECT * FROM inventary

-- if we want record in sales table 
SELECT * FROM orders
SELECT * FROM order_items
SELECT * FROM inventary
-- order_id,
-- order_date,
-- customer_id,
-- seller_id,
-- order_item_id,
-- product_id,
-- quantity,


CREATE OR REPLACE PROCEDURE add_sales
(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id VARCHAR(10),
p_quantity INT
)
LANGUAGE plpgsql

AS $$ 

DECLARE 
-- ALL variable declared here
v_count INT;
v_price FLOAT;
v_product VARCHAR(500);

BEGIN
-- all your code an logic


-- fetching product name and price based p_id entered
SELECT price, product_name INTO v_price,v_product FROM products WHERE product_id = p_product_id;

-- checking stock and product availiabiklity in inventary
SELECT COUNT(*) INTO v_count
FROM inventary
WHERE product_id  = p_product_id
AND stock>=p_quantity;


IF v_count>0 THEN
-- add into orders and order_items table
-- update inventary

INSERT INTO orders(order_id, order_date, customer_id, seller_id)
VALUES
(p_order_id, CURRENT_DATE,p_customer_id,p_seller_id);

-- adding into order list
INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
VALUES 
(p_order_item_id,p_order_id, p_product_id,p_quantity, v_price, v_price*p_quantity);

-- updating inventary
UPDATE inventary
SET stock = stock - p_quantity
where product_id = p_product_id;


   RAISE NOTICE 'thank you product: % sale has been added also inventary stock updates', v_product;

ELSE 
   RAISE NOTICE  'Thank you for your info the product: % is not availale ',v_product;

END IF;



END ;
$$
```
---
**Testing Store Procedure** call add_sales( 4007, 2, 5, 8002, 'B07JW9H4J1', 50 );

---
### Learning Outcomes  
**This project enabled me to:**  

---

- Design and implement a normalized database schema.  

- Clean and preprocess real-world datasets for analysis.  

- Use advanced SQL techniques, including window functions, subqueries, and joins.  

- Conduct in-depth business analysis using SQL.  

- Optimize query performance and handle large datasets efficiently.

---

### Conclusion  

---
This advanced SQL project successfully demonstrates my ability to solve real-world e-commerce problems using structured queries. From improving customer retention to optimizing inventory and logistics, the project provides valuable insights into operational challenges and solutions.  

By completing this project, I have gained a deeper understanding of how SQL can be used to tackle complex data problems and drive business decision-making.

---



# Entity relationdhip Diagram(ERD)
<img width="1644" height="771" alt="image" src="https://github.com/user-attachments/assets/5938d596-4f71-4eb1-9ffb-6b4fc09712e9" />

