-- REQUEST 1

SELECT DISTINCT(MARKET)
FROM dim_customer
WHERE customer="Atliq Exclusive" AND regiON="APAC";

-- REQUEST 2

WITH t2 AS (
SELECT CASE WHEN fiscal_year=2020 THEN COUNT(DISTINCT(product_code)) 
            END AS up_20,
        CASE WHEN fiscal_year=2021 THEN COUNT(DISTINCT(product_code))
            END AS up_21   
FROM fact_gross_price
GROUP BY fiscal_year)
SELECT SUM(up_20) AS unique_products_2020,SUM(up_21) AS unique_products_2021,ROUND(((SUM(up_21)-SUM(up_20))/SUM(up_20))*100,2) AS percentage_chg
FROM t2
GROUP BY up_20 AND up_21;

-- REQUEST 3

SELECT segment , COUNT(DISTINCT(product_code)) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- REQUEST 4

WITH t4 AS (
SELECT p.segment ,CASE WHEN fgp.fiscal_year=2020 THEN COUNT(DISTINCT(fgp.product_code)) 
				  END AS up_20,
                  CASE WHEN fgp.fiscal_year=2021 THEN COUNT(DISTINCT(fgp.product_code))
				  END AS up_21   
FROM fact_gross_price fgp
JOIN dim_product p
ON p.product_code=fgp.product_code
GROUP BY fgp.fiscal_year,p.segment)
SELECT segment,SUM(up_20) AS unique_products_2020,SUM(up_21) AS unique_products_2021,(SUM(up_21)-SUM(up_20)) AS difference
FROM t4
GROUP BY segment
ORDER BY difference DESC;

-- REQUEST 5

SELECT p.product_code,p.product,mfc.manufacturing_cost AS manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost mfc
ON p.product_code=mfc.product_code
WHERE mfc.manufacturing_cost in 
((SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
ORDER BY manufacturing_cost DESC;

-- REQUEST 6

SELECT c.customer_code,c.customer,ROUND(AVG(invd.pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer c
JOIN fact_pre_invoice_deductions invd
ON c.customer_code=invd.customer_code
WHERE c.market='India' AND invd.fiscal_year=2021
GROUP BY c.customer_code,c.customer
ORDER BY average_discount_percentage DESC
limit 5;

 -- REQUEST 7
 
WITH t7 AS (
SELECT MONTHNAME(date) AS Month,YEAR(date) AS Year,(fsm.sold_quantity)* (fgp.gross_price) AS Gsm
FROM fact_sales_monthly fsm
JOIN dim_customer c
ON c.customer_code=fsm.customer_code
JOIN fact_gross_price fgp
ON fsm.product_code=fgp.product_code
WHERE c.customer='Atliq Exclusive')
SELECT Month,Year,SUM(Gsm) AS Gross_sales_Amount 
FROM t7
GROUP BY Month,Year;

-- REQUEST 8

WITH t8 AS (
SELECT *,CASE WHEN MONTH(date) in (9,10,11)
		 THEN 1
         WHEN MONTH(date) in (12,1,2)
		 THEN 2
         WHEN MONTH(date) in (3,4,5)
		 THEN 3
         ELSE 4
         END AS Quarter
FROM fact_sales_monthly
WHERE fiscal_year=2020)
SELECT Quarter,SUM(sold_quantity) AS total_sold_quantity
FROM t8
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

-- REQUEST 9

WITH t9 AS (
SELECT c.channel,fsm.fiscal_year,((fsm.sold_quantity)* (fgp.gross_price)) AS Gsm
FROM fact_sales_monthly fsm
JOIN dim_customer c
ON c.customer_code=fsm.customer_code
JOIN fact_gross_price fgp
ON fsm.product_code=fgp.product_code
WHERE fsm.fiscal_year=2021)
SELECT channel,ROUND(SUM(Gsm)/1000000,2) AS gross_sales_mln,ROUND(SUM(Gsm)/(SELECT SUM(Gsm) FROM t9 GROUP BY fiscal_year)*100,2) AS percentage
FROM t9
GROUP BY channel,fiscal_year
ORDER BY percentage DESC ;

-- REQUEST 10

WITH t10 AS (
SELECT p.division,p.product_code,p.product,
	   SUM(fsm.sold_quantity) AS SUM_sold_qty,
       DENSE_RANK() OVER(PARTITION BY division ORDER BY SUM(fsm.sold_quantity) DESC) as rank_order
FROM dim_product p
JOIN fact_sales_monthly fsm
ON p.product_code=fsm.product_code
WHERE fsm.fiscal_year=2021
GROUP BY p.product_code,p.product,p.division)
SELECT *
FROM t10
WHERE rank_order<4;

-- REQUEST 10 (ADDITIONAL REQUEST)
-- REQUEST 1 WITH GROSS_SALES

WITH t11 AS
(SELECT c.market,SUM(sold_quantity*gross_price) AS gross_sales
FROM dim_customer c
JOIN fact_sales_monthly fsm
ON fsm.customer_code=c.customer_code
JOIN fact_gross_price fgp
ON fgp.product_code=fsm.product_code
WHERE c.region='APAC' AND c.customer='Atliq Exclusive'
GROUP BY c.market)
SELECT *
FROM t11
ORDER BY gross_sales DESC;
