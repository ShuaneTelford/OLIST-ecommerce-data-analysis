--These queries identify missing values from PK and FK tables

SELECT seller_zip
FROM dbo.Sellers
WHERE seller_zip NOT IN
(SELECT zip_prefix FROM SimpleGeo)
ORDER BY seller_zip;

SELECT customer_zip_prefix
FROM dbo.Customers
WHERE customer_zip_prefix NOT IN
(SELECT zip_prefix FROM SimpleGeo)
ORDER BY customer_zip_prefix;

--Total of 285 rows with unverifiable geolocation data. Remove them

SELECT product_category_name
FROM Products
WHERE product_category_name NOT IN
(SELECT category_name FROM ProductCatgtranslation)
ORDER BY product_category_name;

--Identified two category_name's missing, use google translate to find appropriate name add add to translation table

INSERT INTO ProductCatgtranslation (category_name, english_category)
VALUES 
	('pc_gamer', 'pc_gamer'),
	('portateis_cozinha_e_preparadores_de_alimentos', 'portable kitchen food appliances')