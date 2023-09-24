-- Dataset at
-- https://www.kaggle.com/datasets/new-york-city/nyc-property-sales


SELECT *
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;





------------------------------------------------
-- Standardize Date Format in "SALE_DATE" column

SELECT CAST(SALE_DATE as DATE)
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET SALE_DATE = CAST(SALE_DATE as DATE);






------------------------------------------------------------------------------------------------------------
-- Change numbers in "BOROUGH" column to the names of the actual NYC borough names the numbers correspond to

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET BOROUGH = REPLACE(BOROUGH, '1', 'Manhattan')
WHERE BOROUGH IS NOT NULL;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET BOROUGH = REPLACE(BOROUGH, '2', 'Bronx')
WHERE BOROUGH IS NOT NULL;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET BOROUGH = REPLACE(BOROUGH, '3', 'Brooklyn')
WHERE BOROUGH IS NOT NULL;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET BOROUGH = REPLACE(BOROUGH, '4', 'Queens')
WHERE BOROUGH IS NOT NULL;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET BOROUGH = REPLACE(BOROUGH, '5', 'Staten Island')
WHERE BOROUGH IS NOT NULL;






---------------------------------------------------------
-- Remove unnecessary/trailing spaces in "ADDRESS" column

SELECT *
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

SELECT REPLACE(REPLACE(REPLACE(ADDRESS, ' ', '<>'), '><', ''), '<>', ' ')
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET ADDRESS = REPLACE(REPLACE(REPLACE(ADDRESS, ' ', '<>'), '><', ''), '<>', ' ');

SELECT TRIM(ADDRESS)
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET ADDRESS = TRIM(ADDRESS);







---------------------------------------------------------------------------------------------------------------------
-- Populate "APARTMENTS_REVISED" column with apartment numbers from the "ADDRESS" column

SELECT SUBSTRING(ADDRESS, CHARINDEX(',', ADDRESS) +2, LEN(ADDRESS)) AS NEW_APT_NUMBER
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

-- ADD A COMMA AT THE END OF "ADDRESS" IN ORDER TO USE SUBSTRING METHOD
SELECT CONCAT(ADDRESS, ',')
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET ADDRESS = CONCAT(ADDRESS, ',');

-- CREATE NEW COLUMN "NEW_APT_NUMBER"
ALTER TABLE NYC_Property_Sales.dbo.nyc_rolling_sales
ADD NEW_APT_NUMBER VARCHAR(MAX);

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET NEW_APT_NUMBER = SUBSTRING(ADDRESS, CHARINDEX(',', ADDRESS) +2, LEN(ADDRESS));

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET NEW_APT_NUMBER = TRIM(NEW_APT_NUMBER);

-- TAKE AWAY THE COMMA FROM THE END OF "ADDRESS" COLUMN AFTER USING SUBSTRING METHOD
SELECT SUBSTRING(ADDRESS, 1, (LEN(ADDRESS) - 1))
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET ADDRESS = SUBSTRING(ADDRESS, 1, (LEN(ADDRESS) - 1));

-- DELETE THE COMMAS AT THE END OF "NEW_APT_NUMBER"
UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET NEW_APT_NUMBER = NULLIF(NEW_APT_NUMBER,'');

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET NEW_APT_NUMBER = SUBSTRING(NEW_APT_NUMBER, 1, (LEN(NEW_APT_NUMBER) - 1));


-- COMBINE "APARTMENT_NUMBER" AND "NEW_APT_NUMBER" COLUMNS INTO THE NEW "APARTMENTS_REVISED" COLUMN
SELECT CONCAT(APARTMENT_NUMBER, NEW_APT_NUMBER) AS APARTMENTS_REVISED
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

ALTER TABLE NYC_Property_Sales.dbo.nyc_rolling_sales
ADD APARTMENTS_REVISED VARCHAR(MAX);

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET APARTMENTS_REVISED = CONCAT(APARTMENT_NUMBER, NEW_APT_NUMBER);

UPDATE NYC_Property_Sales.dbo.nyc_rolling_sales
SET APARTMENTS_REVISED = NULLIF(APARTMENTS_REVISED,'');



------------------------
-- Remove/check for duplicate rows
-- CREATE A PRIMARY KEY COLUMN AND SET AS THE PRIMARY KEY
ALTER TABLE NYC_Property_Sales.dbo.nyc_rolling_sales
ADD PK_NUMBER INT IDENTITY(1,1) NOT NULL;

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY IDROW,
                     ADDRESS,
                     NEIGHBORHOOD,
                     BUILDING_CLASS_CATEGORY,
                     BLOCK,
                     LOT,
                     APARTMENT_NUMBER,
                     ZIP_CODE,
                     LAND_SQUARE_FEET,
                     GROSS_SQUARE_FEET,
                     YEAR_BUILT,
                     SALE_PRICE,
                     SALE_DATE
                     ORDER BY PK_NUMBER
                     ) ROW_NUM
FROM NYC_Property_Sales.dbo.nyc_rolling_sales
-- ORDER BY IDROW
)
SELECT *
FROM RowNumCTE
WHERE ROW_NUM > 1;
-- *** THERE ARE NO DUPLICATE ROWS ***







-- Remove unnecessary columns (Drop "EASE_MENT" column)
SELECT *
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;

SELECT DISTINCT(EASE_MENT)
FROM NYC_Property_Sales.dbo.nyc_rolling_sales;
-- ***"EASE_MENT" CONTAINS ALL NULL VALUES

ALTER TABLE NYC_Property_Sales.dbo.nyc_rolling_sales
DROP COLUMN EASE_MENT;









-- CHECK IF THERE ARE NONSENSICALL SMALL DOLLAR AMOUNTS UNDER "SALE_PRICE" COLUMN TO INDICATE IF THERE HAS BEEN A TRANSFER OF DEED
SELECT COUNT(SALE_PRICE)
FROM NYC_Property_Sales.dbo.nyc_rolling_sales
WHERE SALE_PRICE < 1000;

SELECT DISTINCT(SALE_PRICE), COUNT(SALE_PRICE) AS SALE_PRICE_COUNT
FROM NYC_Property_Sales.dbo.nyc_rolling_sales
GROUP BY SALE_PRICE
ORDER BY SALE_PRICE;

-- *** $0 SEEMS TO BE THE MOST COMMON NONSENSICALL SMALL DOLLAR AMOUNT FOR "SALE_PRICE" TO INDICATE A TRANSFER OF DEED ***