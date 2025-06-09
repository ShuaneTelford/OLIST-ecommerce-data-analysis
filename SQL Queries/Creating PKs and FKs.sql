--Setting up primary key for tables
ALTER TABLE Customers
ADD PRIMARY KEY (customer_id);

ALTER TABLE SimpleGeo
ADD PRIMARY KEY (zip_prefix);

ALTER TABLE Orders
ADD PRIMARY KEY (order_id);

ALTER TABLE Sellers
ADD PRIMARY KEY (seller_id);

ALTER TABLE Products
ADD PRIMARY KEY (product_id);

ALTER TABLE ProductCatgtranslation
ADD PRIMARY KEY (category_name);

--Setting up foreign key relationships

ALTER TABLE Customers
ADD CONSTRAINT FK_Customers_zip FOREIGN KEY (customer_zip_prefix) REFERENCES
SimpleGeo (zip_prefix);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_customer_id FOREIGN KEY (customer_id) REFERENCES
Customers (customer_id);

ALTER TABLE OrderReviews
ADD CONSTRAINT FK_OrdersRev_orderid FOREIGN KEY (order_id) REFERENCES
Orders (order_id);

ALTER TABLE OrderPayments
ADD CONSTRAINT FK_OrderPay_orderid FOREIGN KEY (order_id) REFERENCES
Orders (order_id);

ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderIt_orderid FOREIGN KEY (order_id) REFERENCES
Orders (order_id);

ALTER TABLE Sellers
ADD CONSTRAINT FK_Sellers_sellerzip FOREIGN KEY (seller_zip) REFERENCES
SimpleGeo (zip_prefix);

ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderItems_sellerid FOREIGN KEY (seller_id) REFERENCES
Sellers (seller_id)

ALTER TABLE OrderItems
ADD CONSTRAINT FK_OrderItems_productid FOREIGN KEY (product_id) REFERENCES
Products (product_id);

ALTER TABLE Products
ADD CONSTRAINT FK_Products_catg FOREIGN KEY (product_category_name) REFERENCES
ProductCatgtranslation (category_name);




