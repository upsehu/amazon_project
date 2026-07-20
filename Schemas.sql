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


