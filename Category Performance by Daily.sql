-- Category performance over time (Time series) , a nice relaxing project this time

/*	-- Scenario --- 

	-- As a large an online retailer, our CEO of wants a performance analysis of DAILY sales by
	-- product grouped by product category for the year 2013 , the CEO also wants to see when the 
	-- product was first sold

	-- Our CEO has requested when was the product first stocked levels be added to the summary as well
	-- do CSQ on [dbo].[ProductInventory] 
*/

USE [Chapter 3 - Sales (Keyed) ];

-- Initial build up
	select
		 [OrderDate]
		,[ProductName]
		,sum([SalesAmount]) as TotalSales
	from
		[dbo].[OnlineSales] os inner join
		[dbo].[Product] prod on os.ProductKey = prod.ProductKey
	group by	 
		 [OrderDate]
		,[ProductName]
	order by
		 [OrderDate]
		,[ProductName]	

-- Add product categories 

	select
		 convert(date,[OrderDate]) as [Purchase date]
		,pc.ProductCategoryName
		,[ProductName]
		,sum([SalesAmount]) as TotalSales
	from
		[dbo].[OnlineSales] os inner join
		[dbo].[Product] prod on os.ProductKey = prod.ProductKey and
								year([OrderDate]) = 2013		inner join
		[dbo].[ProductSubcategory] psc on prod.ProductSubcategoryKey = psc.ProductSubcategoryKey inner join
		[dbo].[ProductCategory] pc on psc.ProductCategoryKey = pc.ProductCategoryKey
	group by	 
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]
	order by
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]	
	
-- Add product first sold using correlated sub query

	select
		 convert(date,[OrderDate]) as [Purchase date]
		,pc.ProductCategoryName
		,[ProductName]
		,(select min(cast(os1.[OrderDate] as date)) from [dbo].[OnlineSales] os1 where os1.ProductKey = os.ProductKey ) as [First sold date]
		,sum([SalesAmount]) as TotalSales
	from
		[dbo].[OnlineSales] os inner join
		[dbo].[Product] prod on os.ProductKey = prod.ProductKey and
								year([OrderDate]) = 2013		inner join
		[dbo].[ProductSubcategory] psc on prod.ProductSubcategoryKey = psc.ProductSubcategoryKey inner join
		[dbo].[ProductCategory] pc on psc.ProductCategoryKey = pc.ProductCategoryKey
	group by	 
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]
		,os.ProductKey
	order by
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]	

-- Prac work, item was first stocked 

	select
		 convert(date,[OrderDate]) as [Purchase date]
		,pc.ProductCategoryName
		,[ProductName]
		,(select min(cast(os1.[OrderDate] as date)) from [dbo].[OnlineSales] os1 where os1.ProductKey = os.ProductKey ) as [First sold date]
		,sum(os.[SalesAmount]) as TotalSales
		,(select min(pin.DateKey) from [dbo].[ProductInventory] pin where pin.ProductKey = os.ProductKey ) as [First stocked date]

	from
		[dbo].[OnlineSales] os inner join
		[dbo].[Product] prod on os.ProductKey = prod.ProductKey and
								year([OrderDate]) = 2013 		inner join
		[dbo].[ProductSubcategory] psc on prod.ProductSubcategoryKey = psc.ProductSubcategoryKey inner join
		[dbo].[ProductCategory] pc on psc.ProductCategoryKey = pc.ProductCategoryKey 
										
	group by	 
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]
		,os.ProductKey
	order by
		 [OrderDate]
		,pc.ProductCategoryName
		,[ProductName]	

-- After prac questions
-- Question : what is the first stocked date of product "Mountain-200 Black, 46"    A: 2010-12-28
--            what is the first sold date of product "Fender Set - Mountain"		A: 2012-12-29
 				    