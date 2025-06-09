--Using missing PK and FK queries to delete assumed incorrectly entered data

DELETE FROM Sellers
WHERE seller_zip IN (
SELECT seller_zip
FROM dbo.Sellers
WHERE seller_zip NOT IN
(SELECT zip_prefix FROM SimpleGeo)
);

DELETE FROM Customers
WHERE customer_zip_prefix IN (
SELECT customer_zip_prefix
FROM dbo.Customers
WHERE customer_zip_prefix NOT IN
(SELECT zip_prefix FROM SimpleGeo));

DELETE FROM OrderItems
WHERE seller_id IN (
SELECT seller_id
FROM OrderItems
WHERE seller_id NOT IN (
	SELECT seller_id FROM SELLERS));

DELETE FROM Orders
WHERE customer_id IN (
SELECT customer_id
FROM Orders WHERE customer_id NOT IN (
SELECT customer_id FROM Customers));

DELETE FROM OrderReviews
WHERE order_id IN (
SELECT order_id 
FROM OrderReviews WHERE order_id NOT IN 
(SELECT order_id FROM Orders))

DELETE FROM OrderPayments
WHERE order_id IN (
	SELECT order_id 
	FROM OrderPayments WHERE order_id NOT IN (SELECT order_id FROM Orders))

DELETE FROM Orderitems
WHERE order_id IN
	(SELECT order_id FROM OrderItems WHERE order_id NOT IN (
	SELECT order_id FROM orders))

ALTER TABLE OrderReviews
DROP CONSTRAINT FK_OrdersRev_orderid

ALTER TABLE OrderPayments
DROP CONSTRAINT FK_OrderPay_orderid

ALTER TABLE OrderItems
DROP CONSTRAINT FK_OrderIt_orderid

ALTER TABLE OrderItems
DROP CONSTRAINT FK_OrderIt_orderid

ALTER TABLE OrderPayments
DROP CONSTRAINT FK_OrderPay_orderid

ALTER TABLE OrderReviews
DROP CONSTRAINT FK_OrdersRev_orderid
-------
