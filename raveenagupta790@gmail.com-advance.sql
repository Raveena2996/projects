--SQL Advance Case Study

use db_SQLCASESTUDIES
--Q1. List all the states in which we have customers who have bought cellphones
--from 2005 till today. 

--BEGIN 
	SELECT DISTINCT STATE FROM
	FACT_TRANSACTIONS  T
	INNER JOIN DIM_LOCATION L
	ON T.IDLocation =L.IDLocation
	WHERE YEAR(DATE) BETWEEN 2005 AND 2023

--Q1--END

--Q2.What state in the US is buying the most 'Samsung' cell phones?

--BEGIN
SELECT TOP 1 DL.STATE FROM DIM_MANUFACTURER AS DM
INNER JOIN DIM_MODEL AS M
ON DM.IDManufacturer = M.IDManufacturer
LEFT JOIN FACT_TRANSACTIONS AS FT
ON M.IDModel = FT.IDModel
LEFT JOIN DIM_LOCATION AS DL
ON FT.IDLocation = DL.IDLocation
WHERE DM.Manufacturer_Name = 'samsung' 
AND COUNTRY = 'US'
GROUP BY DL.State
ORDER BY COUNT(QUANTITY) DESC
--Q2--END

--Q3. Show the number of transactions for each model per zip code per state.

--BEGIN  

SELECT MODEL_NAME ,ZIPCODE, STATE,COUNT(IDCustomer) as COUNT_TRANSACTION
FROM (
       SELECT FT.*,DL.State,DL.ZipCODE ,DM.MODEL_NAME FROM  FACT_TRANSACTIONS AS FT
         LEFT JOIN DIM_MODEL AS DM
         ON FT.IDModel = DM.IDModel
         LEFT JOIN DIM_LOCATION AS DL
         ON FT.IDLocation = DL.IDLocation
)AS X
GROUP BY Model_Name,State,ZipCode

--Q3--END

--Q4. Show the cheapest cellphone (Output should contain the price also).

--BEGIN
SELECT TOP 1  MODEL_NAME ,UNIT_PRICE , MANUFACTURER_NAME FROM DIM_MODEL AS DM
LEFT JOIN DIM_MANUFACTURER AS DMF
ON DM.IDManufacturer = DMF.IDManufacturer
ORDER BY Unit_price

--Q4--END

--Q5. Find out the average price for each model in the top5 manufacturers in
--terms of sales quantity and order by average price. 

--BEGIN

select * from FACT_TRANSACTIONS
select * from DIM_MODEL
select * from DIM_MANUFACTURER
 WITH SUCCESS
 AS
 (
            SELECT TOP 5 MANUFACTURER_NAME ,MODEL_NAME , AVG_PRICE, QUANTITY
			FROM
			      (
				    SELECT COUNT(FT.QUANTITY) AS QUANTITY, DMF.Manufacturer_Name,DM.Model_Name,AVG(FT.TOTALPRICE) AS AVG_PRICE
					FROM FACT_TRANSACTIONS AS FT
					INNER JOIN DIM_MODEL AS DM
					ON FT.IDModel = DM.IDModel
					INNER JOIN DIM_MANUFACTURER AS DMF
					ON DM.IDManufacturer = DMF.IDManufacturer
					GROUP BY DMF.Manufacturer_Name,DM.Model_Name
					)
					AS Z
					GROUP BY Manufacturer_Name,MODEL_NAME,AVG_PRICE,QUANTITY
					ORDER BY QUANTITY DESC
					)
     SELECT MODEL_NAME,AVG_PRICE FROM SUCCESS 
	 ORDER BY AVG_PRICE DESC 

--Q5--END

--Q6.List the names of the customers and the average amount spent in 2009,
 --where the average is higher than 500 

--BEGIN

SELECT CUSTOMER_NAME ,AVG(TotalPrice) AS AVERAGE_AMOUNT FROM DIM_CUSTOMER AS DC
                   LEFT  JOIN FACT_TRANSACTIONS AS FT 
				   ON DC.IDCustomer = FT.IDCustomer
				   WHERE YEAR(DATE) =2009
				   GROUP BY Customer_Name
				   HAVING AVG(TotalPrice)>500

--Q6--END
	
--Q7.List if there is any model that was in the top 5 in terms of quantity,
-- simultaneously in 2008, 2009 and 2010 

--BEGIN  

SELECT MODEL_NAME 
FROM
     (
	 SELECT TOP 5 COUNT(QUANTITY) AS QUAN,
	 MODEL_NAME FROM DIM_MODEL AS DM
	 INNER JOIN FACT_TRANSACTIONS AS FT
	 ON DM.IDModel = FT.IDModel
	 WHERE YEAR (DATE) IN (2008,2009,2010)
	 GROUP BY Model_Name
	 ORDER BY QUAN DESC
	 )
	 AS MN

--Q7--END	
--Q8.Show the manufacturer with the 2nd top sales in the year of 2009 and the
--manufacturer with the 2nd top sales in the year of 2010. 

--BEGIN

SELECT TOP 2 MANUFACTURER_NAME 
FROM DIM_MANUFACTURER T1
INNER JOIN DIM_MODEL T2 ON T1.IDMANUFACTURER= T2.IDMANUFACTURER
INNER JOIN FACT_TRANSACTIONS T3 ON T2.IDMODEL= T3.IDMODEL
GROUP BY MANUFACTURER_NAME
ORDER BY SUM(TOTALPRICE) DESC

 SELECT * FROM DIM_MODEL
 SELECT * FROM FACT_TRANSACTIONS
 

with sales 
as (
		select * ,DENSE_RANK() over(order by Sales desc) denserank
		from (
				select --count(d.IDManufacturer) as id_manu, 
				d.Manufacturer_Name,sum(f.TotalPrice) Sales from DIM_MODEL m
				inner join  DIM_MANUFACTURER d 
				on m.idmanufacturer = d.idmanufacturer 
				inner join FACT_TRANSACTIONS f
				on m.IDModel = f.IDModel
				where year(date) =2009
				group by  d.Manufacturer_Name
			 ) as Z
union
		select * , dense_rank () over (order by Sales desc)  as denserank
		from(
				select --count(d.IDManufacturer) as id_manu, 
				d.Manufacturer_Name,sum(f.TotalPrice)  Sales --,DENSE_RANK() over(order by TotalPrice desc)  
				from DIM_MODEL m
				inner join  DIM_MANUFACTURER d 
				on m.idmanufacturer = d.idmanufacturer 
				inner join FACT_TRANSACTIONS f
				on m.IDModel = f.IDModel
				where year(date) =2010
				group by  d.Manufacturer_Name
			) as y
	) 
select Manufacturer_Name,Sales from sales
where DENSERANK = 2

--Q8--END
--Q9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. 

--BEGIN
	SELECT DMF.Manufacturer_Name FROM FACT_TRANSACTIONS AS FT
	LEFT JOIN DIM_MODEL AS DM 
	ON FT.IDModel = DM.IDModel
	LEFT JOIN DIM_MANUFACTURER AS DMF
	ON DM.IDManufacturer =DMF.IDManufacturer
	WHERE YEAR(DATE) = 2010
	EXCEPT
	SELECT DMF.MANUFACTURER_NAME FROM FACT_TRANSACTIONS AS FT
	LEFT JOIN DIM_MODEL AS DM
	ON FT.IDModel=DM.IDModel
	LEFT JOIN DIM_MANUFACTURER AS DMF
	ON DM.IDManufacturer =DMF.IDManufacturer
	WHERE YEAR(DATE) =2009
	

--Q9--END

--Q10. Find top 100 customers and their average spend, average quantity by each
--year. Also find the percentage of change in their spend. 

--BEGIN
SELECT * ,(((avg_price-pre_year)/(pre_year))*100)AS NXT_YEAR FROM 
(
SELECT * ,LAG(AVG_PRICE,1)OVER (partition BY IDCUSTOMER ORDER BY [YEAR]) AS PRE_YEAR FROM
(
SELECT DC.IDCustomer,DC.Customer_Name,YEAR( FT.DATE)[YEAR],AVG(FT.TotalPrice) avg_price,AVG(FT.QUANTITY)AVG_QTY FROM DIM_CUSTOMER AS DC
INNER JOIN FACT_TRANSACTIONS AS FT
ON DC.IDCustomer =FT.IDCustomer
WHERE DC.IDCustomer IN (SELECT TOP 10 IDCustomer FROM FACT_TRANSACTIONS GROUP BY IDCustomer ORDER BY SUM(TOtalPrice)desc)
GROUP BY DC.IDCustomer,DC.Customer_NAME ,YEAR(FT.DATE)
)
  as X
) 
AS Y

--Q10--END
	