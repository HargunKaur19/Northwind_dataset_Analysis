CUSTOMER ANALYSIS
--ANALYSIS
SELECT * FROM CATEGORIES;
SELECT * FROM CUSTOMERS;
SELECT * FROM EMPLOYEE_TERRITORIES;
SELECT * FROM EMPLOYEES;
SELECT * FROM ORDER_DETAILS;
SELECT * FROM ORDERS;
SELECT * FROM PRODUCTS;
SELECT * FROM REGION;
SELECT * FROM SHIPPERS;
SELECT * FROM SUPPLIERS;
SELECT * FROM TERRITORIES;
SELECT * FROM US_STATES;

-----------------------------------------CUSTOMER ANALYSIS--------------------------------------------------------
--Top customers by revenue and number of orders

SELECT CUSTOMER_ID,
	COMPANY_NAME,
	SUM (SELLING_PRICE) AS TOTAL_REVENUE,
	COUNT(DISTINCT O.ORDER_ID) AS NO_OF_ORDERS
FROM REVENUE
INNER JOIN ORDERS O USING (ORDER_ID)
INNER JOIN CUSTOMERS USING (CUSTOMER_ID)
GROUP BY 1,2
ORDER BY TOTAL_REVENUE DESC, NO_OF_ORDERS DESC
LIMIT 10;

--Regional distribution of customers
--COUNTRY WISE
SELECT COUNTRY,
	COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMERS
FROM CUSTOMERS
GROUP BY 1
ORDER BY TOTAL_CUSTOMERS DESC;

--CITY WISE 
SELECT CITY,
	COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMERS
FROM CUSTOMERS
GROUP BY 1
ORDER BY TOTAL_CUSTOMERS DESC;

--REPEAT CUSTOMERS - WHAT PERCENT OF CUSTOMERS ARE LOYAL

WITH ORDERS_PER_CUST AS (SELECT YEAR,
           MONTH, 
           CUSTOMER_ID,
           COMPANY_NAME,
           COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
    FROM ORDERS 
    INNER JOIN CUSTOMERS USING (CUSTOMER_ID)
    INNER JOIN DATE_TABLE USING (ORDER_DATE)
    GROUP BY 1,2,3,4
    ORDER BY 1,2)

,REPEAT_CUSTS AS (SELECT
	YEAR,
    MONTH,
    COUNT(DISTINCT CUSTOMER_ID) AS REPEAT_CUSTOMERS
FROM ORDERS_PER_CUST 
WHERE NO_OF_ORDERS>1 AND YEAR = 1997 --ONLY FOR THIS YEAR COMPLETE DATA IS AVAILABLE
GROUP BY 1,2
ORDER BY 1,2)
	
,TOTAL_CUSTS AS (
SELECT
	YEAR,
    MONTH,
    COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMERS 
FROM ORDERS_PER_CUST 
WHERE YEAR = 1997 --ONLY FOR THIS YEAR COMPLETE DATA IS AVAILABLE
GROUP BY 1,2
ORDER BY 1,2
)

SELECT R.YEAR,
	MONTH,
	REPEAT_CUSTOMERS,
	TOTAL_CUSTOMERS,
    (CAST(REPEAT_CUSTOMERS AS DECIMAL)/TOTAL_CUSTOMERS)*100 AS LOYAL_CUST_PERC
FROM REPEAT_CUSTS R
INNER JOIN TOTAL_CUSTS T USING (YEAR, MONTH)	
GROUP BY 1,2,3,4
ORDER BY 1,2;

--Customers who haven't ordered in last 6 months
WITH LAST_ORDER AS (SELECT CUSTOMER_ID,
       MAX(ORDER_DATE) AS LAST_ORDER_DATE
FROM ORDERS
GROUP BY 1)

, SIXMONTH_DATE AS (
SELECT MAX(ORDER_DATE) AS MAX_ORDER_DATE,
       --DATE_SUBTRACT(MAX(ORDER_DATE), INTERVAL '6 MONTH') AS SIXMONTH_DATE
	   MAX(ORDER_DATE) - INTERVAL '6 month' AS SIXMONTH_DATE
FROM ORDERS)
	
SELECT CUSTOMER_ID,
	LAST_ORDER_DATE
FROM LAST_ORDER
CROSS JOIN SIXMONTH_DATE
WHERE LAST_ORDER_DATE<SIXMONTH_DATE OR LAST_ORDER_DATE IS NULL
ORDER BY 2;

--New customers per month/year

SELECT DATE_PART('YEAR', FIRST_ORDER_DATE), 
	DATE_PART('MONTH', FIRST_ORDER_DATE),
	COUNT (*)
FROM (
	SELECT CUSTOMER_ID, 
       MIN(ORDER_DATE) AS FIRST_ORDER_DATE
FROM ORDERS
GROUP BY 1
)
GROUP BY 1,2
ORDER BY 1,2;

--How many customers did not reorder after first purchase
SELECT CUSTOMER_ID, 
	COMPANY_NAME
FROM CUSTOMERS
LEFT JOIN ORDERS USING (CUSTOMER_ID)
GROUP BY 1,2
HAVING COUNT(ORDER_ID) =1;

--Average time between repeat orders — customer purchase frequency

SELECT CUSTOMER_ID,
	   AVG(ORDER_DATE-LAST_ORDER_DATE) AS AVG_TIME_DIFF
FROM(
SELECT CUSTOMER_ID, 
	   ORDER_ID,
	   ORDER_DATE,
       ROW_NUMBER()OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) AS RN,
	   LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS LAST_ORDER_DATE
FROM ORDERS)
GROUP BY 1
;






