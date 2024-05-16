use amazon;

-- To View the Data
DELIMITER //
CREATE PROCEDURE GetSalesData()
BEGIN
    SELECT *
    FROM sales;
END //
DELIMITER ;

CALL GetSalesData();

-- To check for missing values
SELECT 
    *
FROM
    sales
WHERE
    'Invoice ID' IS NULL OR 'Branch' IS NULL
        OR 'City' IS NULL
        OR 'Customer type' IS NULL
        OR 'Gender' IS NULL
        OR 'Product line' IS NULL
        OR 'Unit price' IS NULL
        OR 'Quantity' IS NULL
        OR 'Tax 5%' IS NULL
        OR 'Total' IS NULL
        OR 'Date' IS NULL
        OR 'Time' IS NULL
        OR 'Payment' IS NULL
        OR 'cogs' IS NULL
        OR 'gross margin percentage' IS NULL
        OR 'gross income' IS NULL
        OR 'Rating' IS NULL;
        
-- Changing the name of the columns Date and Time to sales_date and sales_time respectively.
ALTER TABLE sales
CHANGE COLUMN `Date` sales_date DATE;

ALTER TABLE sales
CHANGE COLUMN `Time` sales_time TIME(6);

-- Modifying the datatypes of the columns.
ALTER TABLE sales
MODIFY COLUMN `Unit price` DOUBLE(10, 2);

ALTER TABLE sales
MODIFY COLUMN `Quantity` INT(10);

ALTER TABLE sales
MODIFY COLUMN `Tax 5%` DOUBLE(10, 2);

ALTER TABLE sales
MODIFY COLUMN `Total` DOUBLE(10, 2);

ALTER TABLE sales
MODIFY COLUMN `cogs` DOUBLE(10, 5);

ALTER TABLE sales
MODIFY COLUMN `gross margin percentage` DOUBLE(10, 10);

ALTER TABLE sales
MODIFY COLUMN `gross income` DOUBLE(10, 5);

ALTER TABLE sales
MODIFY COLUMN `Rating` DOUBLE(2, 2);

------------------------------------ X ----------------------------------------------------
-- Feature Engineering: 
-- This will help us generate some new columns from existing ones.
-- 1. Add a new column named timeofday to give insight of sales in the Morning, Afternoon and Evening. This will help answer the question on which part of the day most sales are made.
    
-- Assuming that 6 am to 12 pm (Morning), 12:01 pm to 6 pm (Afternoon) and 6:01 pm onwards (Evening)
	
ALTER TABLE sales
ADD COLUMN timeofday VARCHAR(20);

UPDATE sales
SET timeofday = CASE
    WHEN HOUR(sales_time) >= 6 AND HOUR(sales_time) < 12 THEN 'Morning'
    WHEN HOUR(sales_time) >= 12 AND HOUR(sales_time) < 18 THEN 'Afternoon'
    ELSE 'Evening'
END;

-- 2. Add a new column named dayname that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri). This will help answer the question on which week of the day each branch is busiest.

ALTER TABLE sales
ADD COLUMN dayname VARCHAR(20);

UPDATE sales
SET dayname = DAYNAME(sales_date);

-- 3. Add a new column named monthname that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar). Help determine which month of the year has the most sales and profit.

ALTER TABLE sales
ADD COLUMN monthname VARCHAR(20);

UPDATE sales
SET monthname = MONTHNAME(sales_date);

CALL GetSalesData();
------------------------------------ X -------------------------------------------------
    
-- Questions
-- 1. What is the count of distinct cities in the dataset?

-- OUTPUT:
-- 3 (Yangon, Naypyitaw, Mandalay)

SELECT 
    COUNT(DISTINCT (City)) AS `Distinct Cities`
FROM
    sales;

-- 2. For each branch, what is the corresponding city?

-- OUTPUT:
-- A	Yangon
-- B	Mandalay
-- C	Naypyitaw

SELECT 
    Branch, City
FROM
    sales
GROUP BY Branch, City
ORDER BY Branch, City;

-- 3. What is the count of distinct product lines in the dataset?

-- OUTPUT:
-- 6 (Health and beauty,Electronic accessories,Home and lifestyle,Sports and travel,Food -- and beverages, Fashion accessories) 


SELECT 
    COUNT(DISTINCT (`Product line`)) AS `Number Of Distinct Products`
FROM
    sales;

-- 4. Which payment method occurs most frequently?

-- OUTPUT:
-- 'Ewallet'

SELECT 
    Payment
FROM
    sales
GROUP BY Payment
ORDER BY COUNT(Payment) DESC
LIMIT 1;

-- 5. Which product line has the highest sales?

-- OUTPUT:
-- Electronic accessories

SELECT 
    `Product line`
FROM
    sales
GROUP BY `Product line`
ORDER BY SUM(Quantity) DESC
LIMIT 1;

-- 6. How much revenue is generated each month?

-- OUTPUT:
-- January	116291.868
-- March	109455.507
-- February	97219.374

SELECT 
    monthname, ROUND(SUM(Total), 3) AS Total_Revenue
FROM
    sales
GROUP BY monthname
ORDER BY Total_Revenue DESC;

-- 7. In which month did the cost of goods sold reach its peak?

-- OUTPUT:
-- January

SELECT 
    monthname
FROM
    sales
GROUP BY monthname
ORDER BY SUM(cogs) DESC
LIMIT 1;

-- 8. Which product line generated the highest revenue?

-- OUTPUT:
-- Food and beverages

SELECT 
    `Product line`
FROM
    sales
GROUP BY `Product line`
ORDER BY SUM(Total) DESC
LIMIT 1;

-- 9. In which city was the highest revenue recorded?

-- OUTPUT:
-- Naypyitaw

SELECT 
    City
FROM
    sales
GROUP BY City
ORDER BY SUM(Total) DESC
LIMIT 1;

-- 10. Which product line incurred the highest Value Added Tax?

-- OUTPUT:
-- Health and beauty

SELECT 
    `Product line`
FROM
    (SELECT 
        `Product line`, MAX(`Tax 5%`) AS max_tax
    FROM
        sales
    GROUP BY `Product line`) AS subquery
LIMIT 1;


-- 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

CALL GetSalesData();

ALTER TABLE sales
ADD COLUMN product_line_status VARCHAR(20);

SET @avg_total = (SELECT AVG(Total) FROM sales);

UPDATE sales 
SET product_line_status = CASE 
    WHEN Total > @avg_total THEN 'Good' 
    ELSE 'Bad'
END;

-- 12. Identify the branch that exceeded the average number of products sold.

-- OUTPUT:
-- C

SELECT 
    Branch
FROM
    sales
GROUP BY Branch
HAVING AVG(Quantity) > (SELECT 
        AVG(Quantity)
    FROM
        sales);

-- 13. Which product line is most frequently associated with each gender?

-- OUTPUT:
-- Electronic accessories	Female	84
-- Electronic accessories	Male	86
-- Fashion accessories	Female	96
-- Fashion accessories	Male	82
-- Food and beverages	Female	90
-- Food and beverages	Male	84
-- Health and beauty	Female	64
-- Health and beauty	Male	88
-- Home and lifestyle	Female	79
-- Home and lifestyle	Male	81
-- Sports and travel	Female	88
-- Sports and travel	Male	78

SELECT 
    `Product line`, Gender, COUNT(`Product line`) AS Frequency
FROM
    sales
GROUP BY `Product line`, Gender
ORDER BY `Product line`;

-- 14. Calculate the average rating for each product line.

-- OUTPUT:
-- Food and beverages	7.1
-- Health and beauty	7.0
-- Fashion accessories	7.0
-- Electronic accessories	6.9
-- Sports and travel	6.9
-- Home and lifestyle	6.8

SELECT 
    `Product line`, ROUND(AVG(Rating), 1) AS avergae_ratings
FROM
    sales
GROUP BY `Product line`
ORDER BY avergae_ratings DESC;

-- 15. Count the sales occurrences for each time of day on every weekday.

-- OUTPUT:
-- Friday	139
-- Monday	125
-- Thursday	138
-- Tuesday	158
-- Wednesday	143

SELECT 
    dayname, SUM(Quantity) AS total_sales_occured
FROM
    sales
WHERE
    dayname NOT IN ('Sunday' , 'Saturday')
GROUP BY dayname
ORDER BY total_sales_occured DESC;

-- 16. Identify the customer type contributing the highest revenue.

-- OUTPUT:
-- Member

SELECT 
    `Customer type`
FROM
    sales
GROUP BY `Customer type`
ORDER BY SUM(Total) DESC
LIMIT 1;

-- 17. Determine the city with the highest VAT percentage.

-- OUTPUT:
-- Naypyitaw

SELECT 
    City, MAX(`Tax 5%`)
FROM
    sales
GROUP BY City
ORDER BY MAX(`Tax 5%`) DESC
LIMIT 1;

-- 18. Identify the customer type with the highest VAT payments.

-- OUTPUT:
-- Member

SELECT 
    `Customer type`
FROM
    sales
GROUP BY `Customer type`
ORDER BY MAX(`Tax 5%`) DESC
LIMIT 1;

-- 19. What is the count of distinct customer types in the dataset?

-- OUTPUT:
-- Member	501
-- Normal	499

SELECT 
    `Customer type`, COUNT(*) AS Frequency
FROM
    sales
GROUP BY `Customer type`;

-- 20. What is the count of distinct payment methods in the dataset?

-- OUTPUT:
-- Cash	344
-- Credit card	311
-- Ewallet	345

SELECT 
    Payment, COUNT(*) AS Frequency
FROM
    sales
GROUP BY Payment;

-- 21. Which customer type occurs most frequently?

-- OUTPUT:
-- Member

SELECT 
    `Customer type`
FROM
    sales
GROUP BY `Customer type`
ORDER BY COUNT(*) DESC 
LIMIT 1;

-- 22. Identify the customer type with the highest purchase frequency.

-- OUTPUT:
-- Member

SELECT 
    `Customer type`
FROM
    sales
GROUP BY `Customer type`
ORDER BY COUNT(*) DESC 
LIMIT 1;

-- 23. Determine the predominant gender among customers.

-- OUTPUT:
-- Female

SELECT 
    Gender
FROM
    sales
GROUP BY Gender
ORDER BY COUNT(*) DESC 
LIMIT 1;

-- 24. Examine the distribution of genders within each branch.

-- OUTPUT:
-- A	Male	179	52.65
-- A	Female	161 47.35
-- B	Male	170 51.20
-- B	Female	162 48.80
-- C	Female	178 54.27
-- C	Male	150 45.73

SELECT 
    Branch,
    Gender,
    COUNT(*) AS 'Count',
    ROUND((COUNT(*) * 100) / (SELECT 
                    COUNT(*)
                FROM
                    sales
                WHERE
                    Branch = s.Branch),
            2) AS 'Distribution (%)'
FROM
    sales s
GROUP BY Branch , Gender
ORDER BY Branch , COUNT(*) DESC;

-- 25. Identify the time of day when customers provide the most ratings.

-- OUTPUT:
-- Afternoon

SELECT 
    timeofday
FROM
    sales
GROUP BY timeofday
ORDER BY ROUND(AVG(Rating), 3) DESC
LIMIT 1;

-- 26. Determine the time of day with the highest customer ratings for each branch.

-- OUTPUT:
-- A	Afternoon	7.057
-- A	Evening	6.979
-- A	Morning	7.005
-- B	Afternoon	6.807
-- B	Evening	6.795
-- B	Morning	6.892
-- C	Afternoon	7.096
-- C	Evening	7.092
-- C	Morning	6.975

SELECT 
    Branch, timeofday, ROUND(AVG(Rating), 3) AS 'Average Rating'
FROM
    sales
GROUP BY Branch , timeofday 
ORDER BY Branch;

-- 27. Identify the day of the week with the highest average ratings.

-- OUTPUT:
-- Monday

SELECT 
    dayname
FROM
    sales
GROUP BY dayname 
ORDER BY ROUND(AVG(Rating), 3) DESC
LIMIT 1;

-- 28. Determine the day of the week with the highest average ratings for each branch.

-- OUTPUT:
-- A	Friday	7.312
-- B	Monday	7.336
-- C	Friday	7.279

SELECT 
    Branch, dayname, AVG_Rating
FROM (
    SELECT 
        Branch,
        dayname,
        ROUND(AVG(Rating), 3) AS AVG_Rating,
        ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY AVG(Rating) DESC) AS row_num
    FROM
        sales
    GROUP BY Branch, dayname
) AS ranked_sales
WHERE row_num = 1;


------------------------------------ X ------------------------------------------------


