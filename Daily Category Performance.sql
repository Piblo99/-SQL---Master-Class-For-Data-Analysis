-- Category performance over time (Time series) , a nice relaxing project this time
/*  -- Scenario --- 
  -- As a large an online retailer, our CEO of wants a performance analysis of DAILY sales by
  -- product grouped by product category for the year 2013 , the CEO also wants to see when the 
  -- product was first sold
  -- Our CEO has requested when was the product first stocked levels be added to the summary as well
  -- do CSQ on [dbo].[ProductInventory] 
*/
USE [Chapter 3 - Sales (Keyed) ];

-- Initial build up
SELECT [orderdate],
       [productname],
       Sum([salesamount]) AS TotalSales
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[product] prod
               ON os.productkey = prod.productkey
GROUP  BY [orderdate],
          [productname]
ORDER  BY [orderdate],
          [productname]

-- Add product categories 
SELECT CONVERT(DATE, [orderdate]) AS [Purchase date],
       pc.productcategoryname,
       [productname],
       Sum([salesamount])         AS TotalSales
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[product] prod
               ON os.productkey = prod.productkey
                  AND Year([orderdate]) = 2013
       INNER JOIN [dbo].[productsubcategory] psc
               ON prod.productsubcategorykey = psc.productsubcategorykey
       INNER JOIN [dbo].[productcategory] pc
               ON psc.productcategorykey = pc.productcategorykey
GROUP  BY [orderdate],
          pc.productcategoryname,
          [productname]
ORDER  BY [orderdate],
          pc.productcategoryname,
          [productname]

-- Add product first sold using correlated sub query
SELECT CONVERT(DATE, [orderdate])              AS [Purchase date],
       pc.productcategoryname,
       [productname],
       (SELECT Min(Cast(os1.[orderdate] AS DATE))
        FROM   [dbo].[onlinesales] os1
        WHERE  os1.productkey = os.productkey) AS [First sold date],
       Sum([salesamount])                      AS TotalSales
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[product] prod
               ON os.productkey = prod.productkey
                  AND Year([orderdate]) = 2013
       INNER JOIN [dbo].[productsubcategory] psc
               ON prod.productsubcategorykey = psc.productsubcategorykey
       INNER JOIN [dbo].[productcategory] pc
               ON psc.productcategorykey = pc.productcategorykey
GROUP  BY [orderdate],
          pc.productcategoryname,
          [productname],
          os.productkey
ORDER  BY [orderdate],
          pc.productcategoryname,
          [productname]

-- Prac work, item was first stocked 
SELECT CONVERT(DATE, [orderdate]) AS [Purchase date],
       pc.productcategoryname,
       [productname],
       (SELECT Min(Cast(os1.[orderdate] AS DATE))
        FROM   [dbo].[onlinesales] os1
        WHERE  os1.productkey = os.productkey) AS [First sold date],
       Sum(os.[salesamount]) AS TotalSales,
       (SELECT Min(pin.datekey)
        FROM   [dbo].[productinventory] pin
        WHERE  pin.productkey = os.productkey) AS [First stocked date]
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[product] prod
               ON os.productkey = prod.productkey
                  AND Year([orderdate]) = 2013
       INNER JOIN [dbo].[productsubcategory] psc
               ON prod.productsubcategorykey = psc.productsubcategorykey
       INNER JOIN [dbo].[productcategory] pc
               ON psc.productcategorykey = pc.productcategorykey
GROUP  BY [orderdate],
          pc.productcategoryname,
          [productname],
          os.productkey
ORDER  BY [orderdate],
          pc.productcategoryname,
          [productname]
-- Questions
-- what is the first stocked date of product "Mountain-200 Black, 46"   A: 2010-12-28
-- what is the first sold date of product "Fender Set - Mountain"  A: 2012-12-29
