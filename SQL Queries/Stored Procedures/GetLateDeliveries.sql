CREATE PROCEDURE GetLateDeliveries
    @startDate DATE,
    @endDate DATE,
    @period VARCHAR(10), -- 'daily' or 'monthly'
    @state NVARCHAR(100) = NULL, -- Optional state parameter
    @city NVARCHAR(100) = NULL, -- Optional city parameter
    @rankStart INT = NULL, -- Optional rank range start
    @rankEnd INT = NULL, -- Optional rank range end
    @option BIT = NULL -- 1 for states, 0 for cities (used with rank range)
AS
BEGIN
    -- Ensure that a start date and end date are provided
    IF @startDate IS NULL OR @endDate IS NULL
    BEGIN
        RAISERROR('You must specify both a start date and an end date.', 16, 1);
        RETURN;
    END

    -- Ensure that either a state, city, or rank range is provided
    IF @state IS NULL AND @city IS NULL AND (@rankStart IS NULL OR @rankEnd IS NULL OR @option IS NULL)
    BEGIN
        RAISERROR('You must specify either a state, a city, or a rank range with an option.', 16, 1);
        RETURN;
    END

    -- Create a temporary table to hold the late delivery results
    IF OBJECT_ID('tempdb..#LateDeliveriesResults') IS NOT NULL
        DROP TABLE #LateDeliveriesResults;

    CREATE TABLE #LateDeliveriesResults
    (
        Period NVARCHAR(20),
        Location NVARCHAR(100),
        LateDeliveryCount INT,
        Rank INT
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

    -- Calculate the late deliveries based on the specified parameters
    IF @state IS NOT NULL
    BEGIN
        -- Calculate late deliveries for the specified state
        INSERT INTO #LateDeliveriesResults (Period, Location, LateDeliveryCount, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_state AS Location,
            COUNT(*) AS LateDeliveryCount,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_state = @state
          AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_state;
    END

    IF @city IS NOT NULL
    BEGIN
        -- Calculate late deliveries for the specified city
        INSERT INTO #LateDeliveriesResults (Period, Location, LateDeliveryCount, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_city AS Location,
            COUNT(*) AS LateDeliveryCount,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_city = @city
          AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_city;
    END

    IF @rankStart IS NOT NULL AND @rankEnd IS NOT NULL AND @option IS NOT NULL
    BEGIN
        IF @option = 1
        BEGIN
            -- Calculate late deliveries for states within the rank range
            INSERT INTO #LateDeliveriesResults (Period, Location, LateDeliveryCount, Rank)
            SELECT
                FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
                c.customer_state AS Location,
                COUNT(*) AS LateDeliveryCount,
                RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
            FROM Orders o
            INNER JOIN Customers c ON o.customer_id = c.customer_id
            WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
              AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_state;
        END
        ELSE
        BEGIN
            -- Calculate late deliveries for cities within the rank range
            INSERT INTO #LateDeliveriesResults (Period, Location, LateDeliveryCount, Rank)
            SELECT
                FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
                c.customer_city AS Location,
                COUNT(*) AS LateDeliveryCount,
                RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
            FROM Orders o
            INNER JOIN Customers c ON o.customer_id = c.customer_id
            WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
              AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_city;
        END
    END

    -- Select the results based on rank range if provided
    SELECT
        Period,
        Location,
        LateDeliveryCount,
        Rank
    FROM #LateDeliveriesResults
    WHERE (@rankStart IS NULL OR Rank >= @rankStart)
      AND (@rankEnd IS NULL OR Rank <= @rankEnd)
    ORDER BY Period, Rank;

    -- Clean up the temporary table
    DROP TABLE #LateDeliveriesResults;
END;

--E.g.1 daily late deliveries for state SP from 2017-01-01 to 2018-08-31
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'daily', @state = 'SP';

--E.g.2 monthly late deliveries for city rio de jeneiro from 2017-01-01 to 2018-08-31
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'monthly', @city = 'rio de janeiro';

--E.g.3 top 3 monthly late deliveries by state from 2017-01-01 to 2018-08-31
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'monthly', @rankStart = 1, @rankEnd = 3, @option = 1;

--E.g.4 top 3 daily late deliveries by state from 2017-01-01 to 2017-03-01
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2017-03-01', @period = 'daily', @rankStart = 1, @rankEnd = 3, @option = 1;

--E.g.5 top 3 monthly late deliveries by city from 2017-01-01 to 2017-06-01
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2017-06-01', @period = 'monthly', @rankStart = 1, @rankEnd = 3, @option = 0;

--E.g.6 top 3 monthly late deliveries by city from 2017-01-01 to 2017-06-01
EXEC GetLateDeliveries @startDate = '2017-01-01', @endDate = '2017-06-01', @period = 'daily', @rankStart = 1, @rankEnd = 3, @option = 0;