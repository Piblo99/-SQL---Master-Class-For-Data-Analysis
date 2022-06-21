-- COHORT Analysis

-- What is and how to do Cohort analysis 
-- Most commonly used to observe customer loyalty trends, predict future revenue, and monitor churn	
-- It can also reveal what is not initially obvious, take the next query , a basic grouping of
-- Sales and Transaction count over years since the business started, it looks like it's reasonably
-- heathy, but is it, could it be better ?
--
-- So as Im a punk analyst I will look into this without being asked and come back to the CEO with
-- my observations 

-- Quick summary of sales orders/value over the years

	select
		 Year([OrderDate]) as SaleYear
		,count([OrderDate]) as Orders
		,sum([SalesAmount]) as TotalSales
	from
		[dbo].[OnlineSales]
	group by
		 Year([OrderDate])
	order by
		 Year([OrderDate])


-- Step 1 : Grab the sales data and compute the first purchase date 
--			using a JOIN to a calculated table, note: yes we could cheat
--			and use the [DateFirstPurchase] value in Customer, but you may
--			not always have that available. In addition we could also use an
--			Outer Apply or correlated sub query for computing this date.

	SELECT 
		    os.CustomerKey
		   ,os.SalesAmount 
		   ,os.[OrderDate]
		   ,cohorts.FirstPurchDate 
	FROM   
		   [dbo].[OnlineSales] os
		   JOIN (SELECT CustomerKey, 
						Min([OrderDate]) AS FirstPurchDate 
				 FROM   [OnlineSales] 
			 
				 GROUP  BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	ORDER BY 1

-- Step 2 :  Setup year/month groups since we are doing cohort analysis by
--			 customers when they made their first purchase, we can re-use the
--			 step 1 query again for this


	SELECT	
		    os.CustomerKey
		   ,os.SalesAmount 
		   ,os.[OrderDate]
		   ,cohorts.FirstPurchDate
		   ,cohorts.CohortMonthly
	FROM   
		   [dbo].[OnlineSales] os
		   JOIN (SELECT CustomerKey, 
			        Min([OrderDate]) AS FirstPurchDate 
			        ,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
				 FROM   [OnlineSales] 
				 GROUP  BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	ORDER BY 1

-- Step 3 : Establish the life time month at which each sale event took place 
--			for each cohort member (customer), hence if the member (cust) made their first
--			purchase in Dec 2010 then they are in the '2010-12' cohort , which is Month 1 
--			life time month, if they next purchased in April 2011 then their life time month
--			is Month 5 as the purchase happened in the 5th month since their first purchase
--
--			To calculate we need to determine the time between the first purchase date and
--			the next purchase and so on
--			
-- It's easy to compute using the DateDiff function, we saw this function when in 
-- working out session duration in the google analytics data project 1
	
	SELECT	
		    os.CustomerKey
		   ,os.SalesAmount 
		   ,os.[OrderDate]
		   ,cohorts.FirstPurchDate
		   ,cohorts.CohortMonthly
		   ,(datediff(d,cohorts.FirstPurchDate,os.OrderDate)/30)+1 as LifetimeMonth 
	FROM   
		   [dbo].[OnlineSales] os
		   JOIN (SELECT CustomerKey, 
					    Min([OrderDate]) AS FirstPurchDate 
					   ,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
				 FROM   [OnlineSales] 
				 GROUP  BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	ORDER BY 1 	


-- Step 4 : Calculate Average the sales value for each cohort and group by the cohort

	SELECT	
		    avg(os.SalesAmount ) as AvgCustSales
		   ,cohorts.CohortMonthly
		   ,(datediff(d,cohorts.FirstPurchDate,os.OrderDate)/30)+1 as LifetimeMonth
	FROM   
		   [dbo].[OnlineSales] os
			JOIN (SELECT CustomerKey, 
			             Min([OrderDate]) AS FirstPurchDate 
				     ,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
				 FROM   [OnlineSales] 
				 GROUP  BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	GROUP BY
		  CohortMonthly
		 ,(datediff(d,cohorts.FirstPurchDate,os.OrderDate)/30)+1
	ORDER BY 3


