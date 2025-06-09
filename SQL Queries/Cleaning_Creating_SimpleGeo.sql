--Create CTE where rank providessingle unique city and stateto a unique zip_prefix
--Translate the CTE so there are no accents in the table
--Now standardise city names by removing all accents
--Create newtable to store simplified Geolocation data

CREATE TABLE SimpleGeo (
	zip_prefix NVARCHAR(50) NOT NULL,
	city	NVARCHAR(50),
	state	NVARCHAR(2)
	);

--Insert new data into the SimpleGeo Table
WITH CTE AS (
SELECT zip_prefix, city, state
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY zip_prefix ORDER BY zip_prefix DESC) as rank
FROM Geolocation) AS a
WHERE a.rank=1
)
INSERT INTO SimpleGeo (zip_prefix, city, state)
SELECT * FROM CTE;