-- Sales and product analysis project

/*	-- Scenario --- Study our best customers sales and best products

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

use [Chapter 3 - Sales (Keyed) ];

-- Ranked list of customer sales over country for Dec 2013

select 
	   geo.CountryRegionName
	  ,cust.CustomerKey
	  ,cust.LastName 
	  ,cust.FirstName
	  ,cust.EmailAddress	
	  ,sum([SalesAmount]) as TotalMthSales
	  ,RANK() OVER (PARTITION by [CountryRegionName] ORDER BY sum([SalesAmount]) DESC) as CustomerRank
from
	  [dbo].[OnlineSales] os inner join
	  [dbo].[Customer] cust ON os.CustomerKey = cust.CustomerKey and
											    os.OrderDate  between '2013-12-01' and '2013-12-31' inner join
	  [dbo].[Geography] geo ON cust.GeographyKey =  geo.GeographyKey 	
group by
       cust.CustomerKey
	  ,cust.LastName 
	  ,cust.FirstName
	  ,cust.EmailAddress
	  ,CountryRegionName

--   And Now the Product manager wants a ranked list of all products including product name, cost and listprice sold $
--   during the month of Nov 2013 the ranking is grouped by Product Category
--   Prac - Ranked list of product sales over country Nov 2013
	
select 
	   pc.ProductCategoryName
	  ,ProductName
	  ,sum([SalesAmount]) as TotalMthSales
	  ,RANK() OVER (PARTITION by pc.ProductCategoryName ORDER BY sum([SalesAmount]) DESC) as ProductRank
from
	  [dbo].[OnlineSales] os inner join
	  [dbo].[Product] prod on os.ProductKey = prod.ProductKey and
											  os.OrderDate  between '2013-12-01' and '2013-12-31' inner join
	  [dbo].[ProductSubcategory] psc on prod.ProductSubcategoryKey = psc.ProductSubcategoryKey inner join
	  [dbo].[ProductCategory] pc on psc.ProductCategoryKey = pc.ProductCategoryKey
group by
	   pc.ProductCategoryName
	  ,ProductName

-- Questions
-- 1 What is the ranking for Cat:Accessories/Prod:Touring Tire/TotalSales:2406.17		Answer = 10
-- 2 What product is the worst sales performer (looking at Rank) for Category=Bikes		Answer = Mountain-500 Black, 40	 
-- 3 What product is the best sales performer (looking at Rank) for Category=Clothing	Answer = Short-Sleeve Classic Jersey, XL	
