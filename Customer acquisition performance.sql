-- Measuring customer aquisition 
-- In this SQL How to, we build up a query to analyse the acuisition of new customers &
-- to some extent we leverage some basics from Cohort analysis as we are interested
-- in when the customer first purchased a product from us, hence we place them in 
-- the appropriate cohort for comparisons
-- Summary of Customer counts and sale values
SELECT Year([orderdate]) AS SaleYear,
       Count(DISTINCT( customerkey )) AS Customers,
       Sum([salesamount]) AS TotalSales
FROM   [dbo].[onlinesales]
GROUP  BY Year([orderdate])
ORDER  BY Year([orderdate])

-- Step 1 , now get all the customers in a cohort, but we only require distinct customers, in other words
--          we dont want to count all customer occurrences for the cohort as this will skew the analysis
--    
SELECT DISTINCT( os.customerkey ),
               cohorts.cohortmonthly
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate]) AS FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS
                    CohortMonthly
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
ORDER  BY 2

-- Step 2 , As we will use the LAG function shortly which requires a sort order, the cohort monthly will not work for this as it is an string
--      so we have to create numeric sort keys , we can use Year and Month, so in effect we are representing the cohort as a multi part 
--      numeric and whilst at it, reduce the rowset to just return counts for the cohort
SELECT cohorts.cohortmonthly,
       yearsortkey,
       monthsortkey,
       Count(DISTINCT( os.customerkey )) AS CohortCustomerCount
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate]) AS FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS CohortMonthly,
                    Year(Min([orderdate])) AS YearSortKey
                    -- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
                    ,
                    Month(Min([orderdate])) AS MonthSortKey
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
GROUP  BY cohorts.cohortmonthly,
          yearsortkey,
          monthsortkey
ORDER  BY 2,
          3

-- Step 3 , now we can calculate the customer counts for current and previous cohorts and show the change, we use LAG for this
--        plotting change on a chart reveals the trends
--
--      Note: These are only statistical (i.e counted) values, there is no deep analysis to determine numbers
--            of customers are that returning across the cohorts
--          Hence this analysis does assume customers are new customers only
SELECT cohorts.cohortmonthly,
       yearsortkey,
       monthsortkey
       -- Metrics here
       ,
       Count(DISTINCT( cohorts.customerkey ))   AS CohortMonthlyCustCount,
       Lag(Count(DISTINCT( cohorts.customerkey )), 1, 0)
         OVER (
           ORDER BY yearsortkey, monthsortkey ) AS PrevCohortMonthlyCustCount,
       Count(DISTINCT( cohorts.customerkey )) -
       Lag(Count(DISTINCT
           ( cohorts.customerkey )), 1, 0)
         OVER (
           ORDER BY yearsortkey, monthsortkey)
       AS ChangeToPrevCohort
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate]) AS FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS
                    CohortMonthly,
                    Year(Min([orderdate])) AS YearSortKey
                    -- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
                    ,
                    Month(Min([orderdate])) AS MonthSortKey
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
GROUP  BY cohorts.cohortmonthly,
          yearsortkey,
          monthsortkey
ORDER  BY 2,
          3

-- Step 4 , Now extend the code to wrap within and outer query to enable neater calculation of the
--      % change over the cohorts, rather than use lag multiple times which is messy, Im for neat readable code
--      If you plan to use code over and over, ensure you comment the important ideas the code implements
SELECT Measures.cohortmonthly,
       Measures.yearsortkey,
       Measures.monthsortkey,
       Measures.cohortmonthlycustcount,
       Sum(Measures.cohortmonthlycustcount)
         OVER (
           ORDER BY yearsortkey, monthsortkey) AS AccumCustomerCount,
       Measures.prevcohortmonthlycustcount,
       Measures.changetoprevcohort,
       Measures.changetoprevcohort / cohortmonthlycustcount * 100 AS ChangeToPrevCohortPct,
       Measures.changetoprevcohortcast / cohortmonthlycustcount * 100 AS ChangeToPrevCohortPctCast
FROM   (SELECT cohorts.cohortmonthly,
               cohorts.yearsortkey,
               cohorts.monthsortkey
               -- Metrics here
               ,
               Count(DISTINCT( cohorts.customerkey ))
               AS
                      CohortMonthlyCustCount,
               Lag(Count(DISTINCT( cohorts.customerkey )), 1, 0)
                 OVER (
                   ORDER BY cohorts.yearsortkey, monthsortkey )
               AS
                      PrevCohortMonthlyCustCount,
               Cast(Count(DISTINCT( cohorts.customerkey )) -
                    Lag(Count(DISTINCT
                             ( cohorts.customerkey )), 1, 0)
                      OVER (
                        ORDER BY yearsortkey, monthsortkey) AS DECIMAL(18, 2))
               AS
               ChangeToPrevCohort
               -- Why do we use cast in the Pct calculation ?? Because the counts return Integer values and we require Decimal values for % calcs
               ,
               Count(DISTINCT( cohorts.customerkey )) -
               Lag(Count(DISTINCT
                   ( cohorts.customerkey )), 1, 0)
                 OVER (
                   ORDER BY yearsortkey, monthsortkey)
                                      AS ChangeToPrevCohortCast
        FROM   [dbo].[onlinesales] os
               JOIN (SELECT customerkey,
                            Min([orderdate]) AS FirstPurchDate,
                            Cast(Year(Min([orderdate])) AS CHAR(4))
                            + '-'
                            + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS CohortMonthly,
                            Year(Min([orderdate])) AS
                            YearSortKey
                            -- Use these to sort, as cohort sort is alpha based and won't provide the order required for LAG
                            ,
                            Month(Min([orderdate])) AS MonthSortKey
                     FROM   [onlinesales]
                     GROUP  BY customerkey) AS cohorts
                 ON os.customerkey = cohorts.customerkey
        GROUP  BY cohorts.cohortmonthly,
                  yearsortkey,
                  monthsortkey) AS Measures
ORDER  BY 2,
          3
-- Drop the data into a bi tool to observe trends
