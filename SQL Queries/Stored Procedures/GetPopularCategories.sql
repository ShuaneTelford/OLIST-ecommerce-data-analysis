CREATE PROCEDURE GetPopularCategories
    @startDate DATE,
    @endDate DATE,
    @period VARCHAR(10), -- 'daily' or 'monthly'
    @state NVARCHAR(100) = NULL, -- Optional state parameter
    @city NVARCHAR(100) = NULL, -- Optional city parameter
    @rankStart INT = NULL, -- Optional rank range start
    @rankEnd INT = NULL -- Optional rank range end
AS
BEGIN
    -- Ensure that a start date and end date are provided
    IF @startDate IS NULL OR @endDate IS NULL
    BEGIN
        RAISERROR('You must specify both a start date and an end date.', 16, 1);
        RETURN;
    END

    -- Create a temporary table to hold the category results
    IF OBJECT_ID('tempdb..#CategoryResults') IS NOT NULL
        DROP TABLE #CategoryResults;

    CREATE TABLE #CategoryResults
    (
        Period NVARCHAR(20),
        Category NVARCHAR(100),
        OrderCount INT,
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

    -- Calculate the most popular categories based on the specified parameters
    IF @state IS NOT NULL
    BEGIN
        -- Calculate category popularity for the specified state
        INSERT INTO #CategoryResults (Period, Category, OrderCount, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            pct.english_category AS Category,
            COUNT(oi.product_id) AS OrderCount,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(oi.product_id) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        INNER JOIN OrderItems oi ON o.order_id = oi.order_id
        INNER JOIN Products p ON oi.product_id = p.product_id
        INNER JOIN ProductCatgTranslation pct ON p.product_category_name = pct.category_name
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_state = @state
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), pct.english_category;
    END

    IF @city IS NOT NULL
    BEGIN
        -- Calculate category popularity for the specified city
        INSERT INTO #CategoryResults (Period, Category, OrderCount, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            pct.english_category AS Category,
            COUNT(oi.product_id) AS OrderCount,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(oi.product_id) DESC) AS Rank
        FROM Orders o
        INNER JOIN Customers c ON o.customer_id = c.customer_id
        INNER JOIN OrderItems oi ON o.order_id = oi.order_id
        INNER JOIN Products p ON oi.product_id = p.product_id
        INNER JOIN ProductCatgTranslation pct ON p.product_category_name = pct.category_name
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
          AND c.customer_city = @city
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), pct.english_category;
    END

    IF @state IS NULL AND @city IS NULL
    BEGIN
        -- Calculate category popularity for all states/cities within rank range
        INSERT INTO #CategoryResults (Period, Category, OrderCount, Rank)
        SELECT
            FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) AS Period,
            pct.english_category AS Category,
            COUNT(oi.product_id) AS OrderCount,
            RANK() OVER (PARTITION BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat) ORDER BY COUNT(oi.product_id) DESC) AS Rank
        FROM Orders o
        INNER JOIN OrderItems oi ON o.order_id = oi.order_id
        INNER JOIN Products p ON oi.product_id = p.product_id
        INNER JOIN ProductCatgTranslation pct ON p.product_category_name = pct.category_name
        WHERE CAST(o.order_purchase_timestamp AS DATE) BETWEEN @startDate AND @endDate
        GROUP BY FORMAT(CAST(o.order_purchase_timestamp AS DATE), @periodFormat), pct.english_category;
    END

    -- Select the results based on rank range if provided
    SELECT
        Period,
        Category,
        OrderCount,
        Rank
    FROM #CategoryResults
    WHERE (@rankStart IS NULL OR Rank >= @rankStart)
      AND (@rankEnd IS NULL OR Rank <= @rankEnd)
    ORDER BY Period, Rank;

    -- Clean up the temporary table
    DROP TABLE #CategoryResults;
END;


--E.g.1 daily most popular categories in state SP from 2017-01-01 to 2018-08-31
EXEC GetPopularCategories @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'daily', @state = 'SP';

--E.g.2 monthly top 5 popular cateogires in city Rio de Janeiro from 2017-01-01 to 2018-03-31
EXEC GetPopularCategories @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'monthly', @rankStart=1, @rankEnd=5,  @city = 'Rio de Janeiro';

--E.g.3 monthly top 3 popular categories in all locations from 2017-01-01 to 2018-08-31
EXEC GetPopularCategories  @startDate = '2017-01-01', @endDate = '2018-08-31', @period = 'monthly', @rankStart = 1, @rankEnd = 3;
