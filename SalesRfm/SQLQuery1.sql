-- Overview of data
SELECT * 
FROM PortfolioProject..sales_data_sample

SELECT DISTINCT status FROM PortfolioProject..sales_data_sample
SELECT DISTINCT YEAR_ID FROM PortfolioProject..sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM PortfolioProject..sales_data_sample
SELECT DISTINCT COUNTRY FROM PortfolioProject..sales_data_sample
SELECT DISTINCT DEALSIZE FROM PortfolioProject..sales_data_sample
SELECT DISTINCT TERRITORY FROM PortfolioProject..sales_data_sample

-- Analysing productlines performance
SELECT PRODUCTLINE, SUM(sales) AS Revenue
FROM PortfolioProject..sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Sales across the years
SELECT YEAR_ID, SUM(sales) AS Revenue
FROM PortfolioProject..sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

--Dealsize across the years
SELECT DEALSIZE, SUM(sales) AS Revenue
FROM PortfolioProject..sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

--Best performing months year by year
--2003
SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Total_Orders
FROM PortfolioProject..sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC

--2004
SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Total_Orders
FROM PortfolioProject..sales_data_sample
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC

--2005 --Operated only in 5 months
SELECT MONTH_ID, SUM(sales) AS Revenue, COUNT(ORDERNUMBER) AS Total_Orders
FROM PortfolioProject..sales_data_sample
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY 2 DESC

--RFM Analysis
DROP TABLE IF EXISTS #RFM
;WITH cte_rfm AS (
	SELECT
		CUSTOMERNAME,
		SUM(sales) AS MonetaryValue,
		AVG(sales) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS LastOrderDate,
		(SELECT MAX(ORDERDATE) FROM PortfolioProject..sales_data_sample) AS MaxOrderDate,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM PortfolioProject..sales_data_sample)) AS Recent_Order
	FROM PortfolioProject..sales_data_sample
	GROUP BY CUSTOMERNAME
	),
cte_calc AS (
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recent_Order DESC) AS rfm_receny,
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
	FROM cte_rfm r
	)
SELECT 
	c.*, rfm_receny + rfm_frequency + rfm_monetary AS rfm_total,
	CAST(rfm_receny AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar) AS rfm_cell
INTO #RFM
FROM cte_calc c

-- Customer segmentation
SELECT *
FROM #RFM

SELECT CUSTOMERNAME, MonetaryValue, rfm_receny, rfm_frequency, rfm_monetary,
	CASE WHEN rfm_cell IN ('433','434','443','444') THEN 'Loyal Customers'
		 WHEN rfm_cell IN ('323','332', '333','321','422','423','432') THEN 'Active Customers'		 
		 WHEN rfm_cell IN ('311','411','331') THEN 'Promising Newbies'
		 WHEN rfm_cell IN ('222','223','233','322') THEN 'Potential Churners'
		 WHEN rfm_cell IN ('133','134','143','144', '244','334','343','344') THEN 'Slipping Away'
		 WHEN rfm_cell IN ('111', '112', '114', '121', '122', '123', '132', '141', '211', '212') THEN 'Lost Customers'
	ELSE 'Other' 
	END rfm_segment
FROM #RFM

--Product analysis to find items sold together
SELECT DISTINCT ORDERNUMBER, STUFF(
	(SELECT ',' + PRODUCTCODE
	FROM PortfolioProject..sales_data_sample AS a
	WHERE ORDERNUMBER IN (
		SELECT ORDERNUMBER
		FROM (
			SELECT ORDERNUMBER, COUNT(*) AS Row_Numbers
			FROM PortfolioProject..sales_data_sample
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
			) AS OrderLines
		WHERE Row_Numbers = 2
		)
		AND a.ORDERNUMBER = b.ORDERNUMBER
		FOR XML PATH ('')), 1, 1, '') AS Product_Codes
FROM PortfolioProject..sales_data_sample AS b
ORDER BY 2 DESC

