CREATE PROCEDURE GetRevenueByLocation
    @startDate DATE,
    @endDate DATE,
    @period VARCHAR(10), -- 'daily' or 'monthly'
    @state NVARCHAR(100) = NULL, -- Optional state parameter
    @city NVARCHAR(100) = NULL -- Optional city parameter
AS
BEGIN
    -- Ensure that either a state or city is provided
    IF @state IS NULL AND @city IS NULL
    BEGIN
        RAISERROR('You must specify either a state or a city.', 16, 1);
        RETURN;
    END

    -- Create a temporary table to hold the revenue results
    IF OBJECT_ID('tempdb..#RevenueResults') IS NOT NULL
        DROP TABLE #RevenueResults;

    CREATE TABLE #RevenueResults
    (
        Period NVARCHAR(20),
        Location NVARCHAR(100),
        NetRevenue DECIMAL(18, 2)
    );

    -- Determine the period format
    DECLARE @periodFormat NVARCHAR(100);
    IF @period = 'daily'
    BEGIN
        SET @periodFormat = 'yyyy-MM-dd';
    END
    ELSE
    BEGIN
        SET @periodFormat = 'yyyy-MM';
    END

    -- Calculate revenue based on the specified parameters
    IF @state IS NOT NULL
    BEGIN
        -- Calculate revenue for the specified state
        INSERT INTO #RevenueResults (Period, Location, NetRevenue)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_state AS Location,
            SUM(oi.price - oi.freight_value) AS TotalRevenue
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        INNER JOIN OrderItems oi ON o.order_id = oi.order_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_state = @state
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_state;
    END

    IF @city IS NOT NULL
    BEGIN
        -- Calculate revenue for the specified city
        INSERT INTO #RevenueResults (Period, Location, NetRevenue)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_city AS Location,
            SUM(oi.price - oi.freight_value) AS TotalRevenue
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        INNER JOIN OrderItems oi ON o.order_id = oi.order_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_city = @city
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_city;
    END

    -- Select the results
    SELECT
        Period,
        Location,
        NetRevenue
    FROM #RevenueResults
    ORDER BY Period, Location;

    -- Clean up the temporary table
    DROP TABLE #RevenueResults;
END;

--E.g.1 daily revenue from 2017-01-01 to 2018-08-31 for state SP 

EXEC GetRevenueByLocation @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'daily', @state = 'SP';

--E.g.2 mothly revenue from 2017-01-01 to 2018-08-31 for city Rio de janeiro

EXEC GetRevenueByLocation @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'monthly', @city = 'Rio de Janeiro';