-- Measuring customer aquisition 

-- In this SQL How to, we build up a query to analyse the acuisition of new customers &
-- to some extent we leverage some basics from Cohort analysis as we are interested
-- in when the customer first purchased a product from us, hence we place them in 
-- the appropriate cohort for comparisons

-- Summary of Customer counts and sale values

	select
		 Year([OrderDate]) as SaleYear
		,count(distinct(customerkey)) as Customers
		,sum([SalesAmount]) as TotalSales
	from
		[dbo].[OnlineSales]
	group by
		 Year([OrderDate])
	order by
		 Year([OrderDate])

-- Step 1 , now get all the customers in a cohort, but we only require distinct customers, in other words
--          we dont want to count all customer occurrences for the cohort as this will skew the analysis
--		


	SELECT 
			distinct(os.CustomerKey)
		   ,cohorts.CohortMonthly
	FROM   
		   [dbo].[OnlineSales] os
		   JOIN (SELECT CustomerKey
					   ,Min([OrderDate]) AS FirstPurchDate 
					   ,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
				 FROM   [OnlineSales] 		 
			     GROUP BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	order by
		2

-- Step 2 , As we will use the LAG function shortly which requires a sort order, the cohort monthly will not work for this as it is an string
--			so we have to create numeric sort keys , we can use Year and Month, so in effect we are representing the cohort as a multi part 
--			numeric and whilst at it, reduce the rowset to just return counts for the cohort


	SELECT 
	     cohorts.CohortMonthly
		,YearSortKey
		,MonthSortKey
		,count(distinct(os.CustomerKey)) as CohortCustomerCount
	FROM   
 	    [dbo].[OnlineSales] os
		 JOIN (SELECT 
						CustomerKey
		  				,Min([OrderDate]) AS FirstPurchDate 
						,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
						,year(Min([OrderDate])) as YearSortKey			-- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
						,month(Min([OrderDate])) as MonthSortKey		
				 FROM   [OnlineSales] 		 
			     GROUP BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	group by
	   cohorts.CohortMonthly	
	  ,YearSortKey
	  ,MonthSortKey
	order by
	2,3



-- Step 3 , now we can calculate the customer counts for current and previous cohorts and show the change, we use LAG for this
--		    plotting change on a chart reveals the trends
--
--			Note: These are only statistical (i.e counted) values, there is no deep analysis to determine numbers
--			      of customers are that returning across the cohorts
--				  Hence this analysis does assume customers are new customers only


	SELECT 
	     cohorts.CohortMonthly
		,YearSortKey
		,MonthSortKey
	-- Metrics here
		,count(distinct(cohorts.CustomerKey)) as CohortMonthlyCustCount

	    ,LAG(count(distinct(cohorts.CustomerKey)), 1,0) OVER (ORDER BY YearSortKey,MonthSortKey ) AS PrevCohortMonthlyCustCount
	  
	    ,count(distinct(cohorts.CustomerKey)) - LAG(count(distinct(cohorts.CustomerKey)), 1,0) OVER (ORDER BY YearSortKey,MonthSortKey) as ChangeToPrevCohort

	FROM   
 	    [dbo].[OnlineSales] os
		 JOIN (SELECT	 CustomerKey 
						,Min([OrderDate]) AS FirstPurchDate 
						,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
						,year(Min([OrderDate])) as YearSortKey			-- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
						,month(Min([OrderDate])) as MonthSortKey		
				 FROM   [OnlineSales] 		 
			     GROUP BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	group by
	   cohorts.CohortMonthly	
	  ,YearSortKey
	  ,MonthSortKey
	order by
	  2,3

-- Step 4 , Now extend the code to wrap within and outer query to enable neater calculation of the
--			% change over the cohorts, rather than use lag multiple times which is messy, Im for neat readable code
--			If you plan to use code over and over, ensure you comment the important ideas the code implements

select									
	 Measures.CohortMonthly
	,Measures.YearSortKey
	,Measures.MonthSortKey  	   
	,Measures.CohortMonthlyCustCount

	,sum(Measures.CohortMonthlyCustCount) OVER (ORDER BY YearSortKey,MonthSortKey) as AccumCustomerCount

	,Measures.PrevCohortMonthlyCustCount
	,Measures.ChangeToPrevCohort

	,Measures.ChangeToPrevCohort / CohortMonthlyCustCount * 100 as ChangeToPrevCohortPct

	,Measures.ChangeToPrevCohortcast / CohortMonthlyCustCount * 100 as ChangeToPrevCohortPctCast
from
(
	SELECT 
	     cohorts.CohortMonthly
		,cohorts.YearSortKey
		,cohorts.MonthSortKey   
	-- Metrics here
		,count(distinct(cohorts.CustomerKey)) as CohortMonthlyCustCount

	    ,LAG(count(distinct(cohorts.CustomerKey)), 1,0) OVER (ORDER BY cohorts.YearSortKey,MonthSortKey ) AS PrevCohortMonthlyCustCount

	    ,cast(count(distinct(cohorts.CustomerKey)) - LAG(count(distinct(cohorts.CustomerKey)), 1,0) OVER (ORDER BY YearSortKey,MonthSortKey) as decimal(18,2)) as ChangeToPrevCohort

    -- Why do we use cast in the Pct calculation ?? Because the counts return Integer values and we require Decimal values for % calcs

	 ,count(distinct(cohorts.CustomerKey)) - LAG(count(distinct(cohorts.CustomerKey)), 1,0) OVER (ORDER BY YearSortKey,MonthSortKey) as ChangeToPrevCohortCast

	FROM   
 	    [dbo].[OnlineSales] os
		 JOIN (SELECT	 CustomerKey 
						,Min([OrderDate]) AS FirstPurchDate 
						,cast(Year(Min([OrderDate])) as char(4)) + '-' + cast(month(Min([OrderDate])) as varchar(2)) as CohortMonthly
						,year(Min([OrderDate])) as YearSortKey			-- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
						,month(Min([OrderDate])) as MonthSortKey		
				 FROM   [OnlineSales] 		 
			     GROUP BY CustomerKey) AS cohorts 
		 ON os.CustomerKey = cohorts.CustomerKey 
	group by
	   cohorts.CohortMonthly	
	  ,YearSortKey
	  ,MonthSortKey
) as Measures
	order by
	  2,3


-- Drop the data into a bi tool to observe trends