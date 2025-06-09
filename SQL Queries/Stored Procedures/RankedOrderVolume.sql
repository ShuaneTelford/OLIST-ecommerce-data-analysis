CREATE PROCEDURE GetOrderVolumesByRank
    @startDate VARCHAR(10), -- Change to VARCHAR to accept input as string
    @endDate VARCHAR(10), -- Change to VARCHAR to accept input as string
    @option BIT, -- 0 for cities, 1 for states
    @rankStart INT = NULL, -- Optional rank range start
    @rankEnd INT = NULL, -- Optional rank range end
    @state NVARCHAR(100) = NULL, -- Optional state parameter
    @city NVARCHAR(100) = NULL, -- Optional city parameter
    @period VARCHAR(10) -- 'daily' or 'monthly'
AS
BEGIN
    -- Check if start date is valid
    IF ISDATE(@startDate) = 0
    BEGIN
        RAISERROR('Start date is not a valid date.', 16, 1);
        RETURN;
    END

    -- Check if end date is valid
    IF ISDATE(@endDate) = 0
    BEGIN
        RAISERROR('End date is not a valid date.', 16, 1);
        RETURN;
    END

    -- Convert input date strings to DATE data type
    DECLARE @startDateConverted DATE = CAST(@startDate AS DATE);
    DECLARE @endDateConverted DATE = CAST(@endDate AS DATE);

    -- Ensure that a start date, end date, and option are provided
    IF @startDateConverted IS NULL OR @endDateConverted IS NULL OR @option IS NULL
    BEGIN
        RAISERROR('You must specify a start date, end date, and option.', 16, 1);
        RETURN;
    END

    -- Ensure that either a state, city, or rank range is provided
    IF @state IS NULL AND @city IS NULL AND (@rankStart IS NULL OR @rankEnd IS NULL)
    BEGIN
        RAISERROR('You must specify either a state, a city, or a rank range.', 16, 1);
        RETURN;
    END

    -- Create a temporary table to hold the order volume results
    IF OBJECT_ID('tempdb..#OrderVolumesResults') IS NOT NULL
        DROP TABLE #OrderVolumesResults;

    CREATE TABLE #OrderVolumesResults
    (
        Period NVARCHAR(20),
        Location NVARCHAR(100),
        OrderVolume INT,
        Rank INT
    );

    -- Determine the period format
    DECLARE @periodFormat NVARCHAR(100);
    IF @period = 'daily'
    BEGIN
        SET @periodFormat = 'yyyy-MM-dd';
    END
    ELSE IF @period = 'monthly'
    BEGIN
        SET @periodFormat = 'yyyy-MM';
    END
    ELSE
    BEGIN
        RAISERROR('Invalid period specified. Use ''daily'' or ''monthly''.', 16, 1);
        RETURN;
    END
    -- Calculate the order volumes based on the specified parameters
    IF @state IS NOT NULL
    BEGIN
        -- Calculate order volumes for the specified state
        INSERT INTO #OrderVolumesResults (Period, Location, OrderVolume, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_state AS Location,
            COUNT(*) AS OrderVolume,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_state = @state
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_state;
    END

    IF @city IS NOT NULL
    BEGIN
        -- Calculate order volumes for the specified city
        INSERT INTO #OrderVolumesResults (Period, Location, OrderVolume, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            c.customer_city AS Location,
            COUNT(*) AS OrderVolume,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_city = @city
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_city;
    END

    IF @rankStart IS NOT NULL AND @rankEnd IS NOT NULL
    BEGIN
        IF @option = 1
        BEGIN
            -- Calculate order volumes for states within the rank range
            INSERT INTO #OrderVolumesResults (Period, Location, OrderVolume, Rank)
            SELECT
                FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
                c.customer_state AS Location,
                COUNT(*) AS OrderVolume,
                RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
            FROM Orders o
            INNER JOIN Customers c ON o.customer_id = c.customer_id
            WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
            GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_state;
        END
        ELSE
        BEGIN
            -- Calculate order volumes for cities within the rank range
            INSERT INTO #OrderVolumesResults (Period, Location, OrderVolume, Rank)
            SELECT
                FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
                c.customer_city AS Location,
                COUNT(*) AS OrderVolume,
                RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(*) DESC) AS Rank
            FROM Orders o
            INNER JOIN Customers c ON o.customer_id = c.customer_id
            WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
            GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), c.customer_city;
        END
    END

    -- Select the results based on rank range if provided
    SELECT
        Period,
        Location,
        OrderVolume,
        Rank
    FROM #OrderVolumesResults
    WHERE (@rankStart IS NULL OR Rank >= @rankStart)
      AND (@rankEnd IS NULL OR Rank <= @rankEnd)
    ORDER BY Period, Rank;

    -- Clean up the temporary table
    DROP TABLE #OrderVolumesResults;
END;


--E.g.1 daily order volume for state SP from 2017-01-01 to 2018-08-31
EXEC GetOrderVolumesByRank @startDate = '2017-01-01', @endDate = '2018-08-31', @option = 1, @state = 'SP', @period = 'daily';

--E.g.2 monthly order volume for city rio de janeiro from 2017-01-01 to 2018-08-31
EXEC GetOrderVolumesByRank @startDate = '2017-01-01', @endDate = '2018-08-31', @option = 0, @city = 'rio de janeiro', @period = 'monthly';

--E.g.3 top 3 monthly order volume by state from 2017-01-01 to 2018-01-31
EXEC GetOrderVolumesByRank @startDate = '2017-01-01', @endDate = '2018-01-31', @option = 1, @rankStart = 1, @rankEnd = 3, @period = 'monthly';

--E.g.4 top 3 daily order volume by city from 2017-01-01 to 2017-03-30
EXEC GetOrderVolumesByRank @startDate = '2017-01-01', @endDate = '2017-03-30', @option = 0, @rankStart = 1, @rankEnd = 3, @period = 'daily';
