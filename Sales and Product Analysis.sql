-- Sales and product analysis project
/*  -- Scenario --- Study our best customers sales and best products
  Our business has a lot of customers and products.
  
  The CRM manager wants a list of all customers with name and email address by COUNTRY, RANKED by their total $ purchase 
  for the month of Dec 2013, the ranking is over country.
  And Now the Product manager wants a ranked list of all products including product name, cost and listprice sold $ 
  during the month of Nov 2013 the ranking is grouped by Product Category
  *******************************************************************************************************
  Def:  Returns the rank of each row within the partition of a result set. 
    The rank of a row is one plus the number of ranks that come before the row in question
    Note: Where value is the same across rows int the group , then a rank can tie
*/
USE [Chapter 3 - Sales (Keyed) ];

-- Ranked list of customer sales over country for Dec 2013
SELECT geo.countryregionname,
       cust.customerkey,
       cust.lastname,
       cust.firstname,
       cust.emailaddress,
       Sum([salesamount])                    AS TotalMthSales,
       Rank()
         OVER (
           partition BY [countryregionname]
           ORDER BY Sum([salesamount]) DESC) AS CustomerRank
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[customer] cust
               ON os.customerkey = cust.customerkey
                  AND os.orderdate BETWEEN '2013-12-01' AND '2013-12-31'
       INNER JOIN [dbo].[geography] geo
               ON cust.geographykey = geo.geographykey
GROUP  BY cust.customerkey,
          cust.lastname,
          cust.firstname,
          cust.emailaddress,
          countryregionname

--   And Now the Product manager wants a ranked list of all products including product name, cost and listprice sold $
--   during the month of Nov 2013 the ranking is grouped by Product Category
--   Prac - Ranked list of product sales over country Nov 2013
SELECT pc.productcategoryname,
       productname,
       Sum([salesamount])                    AS TotalMthSales,
       Rank()
         OVER (
           partition BY pc.productcategoryname
           ORDER BY Sum([salesamount]) DESC) AS ProductRank
FROM   [dbo].[onlinesales] os
       INNER JOIN [dbo].[product] prod
               ON os.productkey = prod.productkey
                  AND os.orderdate BETWEEN '2013-12-01' AND '2013-12-31'
       INNER JOIN [dbo].[productsubcategory] psc
               ON prod.productsubcategorykey = psc.productsubcategorykey
       INNER JOIN [dbo].[productcategory] pc
               ON psc.productcategorykey = pc.productcategorykey
GROUP  BY pc.productcategoryname,
          productname
-- Questions
-- 1 What is the ranking for Cat:Accessories/Prod:Touring Tire/TotalSales:2406.17  Answer = 10
-- 2 What product is the worst sales performer (looking at Rank) for Category=Bikes  Answer = Mountain-500 Black, 40   
-- 3 What product is the best sales performer (looking at Rank) for Category=Clothing  Answer = Short-Sleeve Classic Jersey, XL  
