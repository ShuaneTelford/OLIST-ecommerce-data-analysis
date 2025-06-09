CREATE PROCEDURE GetOrderVolumes
    @startDate DATE, 
    @endDate DATE, 
    @period VARCHAR(10), -- 'daily', 'monthly'
	@city NVARCHAR(50) = NULL,
	@state NVARCHAR(2) = NULL,
	@option_state INT = 0

AS
BEGIN
    IF @period = 'daily'
    BEGIN
		IF @state IS NOT NULL AND @option_state = 1
		BEGIN
			SELECT CAST(o.order_purchase_timestamp AS DATE) AS order_day, c.customer_state, COUNT(*) AS order_count
			FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
			WHERE o.order_purchase_timestamp BETWEEN @startDate AND @endDate
				AND customer_state=@state
			GROUP BY CAST(o.order_purchase_timestamp AS DATE), c.customer_state;
    END
    ELSE
	BEGIN --default option=0 daily
		IF @state IS NOT NULL AND @option_state=1
		SELECT CAST(o.order_purchase_timestamp AS DATE) AS order_day, c.customer_city, c.customer_state, COUNT(*) AS order_count
		FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
		WHERE o.order_purchase_timestamp BETWEEN @startDate AND @endDate
			AND (@city IS NULL OR c.customer_city = @city)
			AND (@state IS NULL OR c.customer_state = @state)
		GROUP BY CAST(o.order_purchase_timestamp AS DATE), c.customer_city, c.customer_state;
		END
	END
	ELSE
    BEGIN
		IF @state IS NOT NULL AND @option_state =1
		BEGIN
			SELECT FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month, c.customer_state, COUNT(*) AS order_count
			FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
			WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
				AND c.customer_state = @state
			GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM'), c.customer_state;
	END
	ELSE
	BEGIN --default option=1 monthly
		SELECT FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month, c.customer_city, c.customer_state, COUNT(*) AS order_count
			FROM Orders o JOIN Customers c ON o.customer_id=c.customer_id
			WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
				AND (@city IS NULL OR customer_city = @city)
              AND (@state IS NULL OR customer_state = @state)
			GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM'), c.customer_city, c.customer_state;
	END
    END
END;

--E.g.1 daily state order volumes for SP from 4th June to 4th August 2017
EXEC GetOrderVolumes @startDate = '2017-06-04', @state='SP', @endDate = '2017-08-04', @period = 'daily', @option_state=1

--E.g.2 monthly city order volumes for rio de janeiro fom 4th June o 4th August 2017
EXEC GetOrderVolumes @startDate = '2017-06-04',@city='rio de janeiro', @endDate = '2017-08-04', @period = 'monthly', @option_state=1