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
SELECT Year([orderdate])  AS SaleYear,
       Count([orderdate]) AS Orders,
       Sum([salesamount]) AS TotalSales
FROM   [dbo].[onlinesales]
GROUP  BY Year([orderdate])
ORDER  BY Year([orderdate])

-- Step 1 : Grab the sales data and compute the first purchase date 
--      using a JOIN to a calculated table, note: yes we could cheat
--      and use the [DateFirstPurchase] value in Customer, but you may
--      not always have that available. In addition we could also use an
--      Outer Apply or correlated sub query for computing this date.
SELECT os.customerkey,
       os.salesamount,
       os.[orderdate],
       cohorts.firstpurchdate
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate]) AS FirstPurchDate
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
ORDER  BY 1

-- Step 2 :  Setup year/month groups since we are doing cohort analysis by
--       customers when they made their first purchase, we can re-use the
--       step 1 query again for this
SELECT os.customerkey,
       os.salesamount,
       os.[orderdate],
       cohorts.firstpurchdate,
       cohorts.cohortmonthly
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate])                              AS
                    FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS
                    CohortMonthly
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
ORDER  BY 1

-- Step 3 : Establish the life time month at which each sale event took place 
--      for each cohort member (customer), hence if the member (cust) made their first
--      purchase in Dec 2010 then they are in the '2010-12' cohort , which is Month 1 
--      life time month, if they next purchased in April 2011 then their life time month
--      is Month 5 as the purchase happened in the 5th month since their first purchase
-- 
--      To calculate we need to determine the time between the first purchase date and
--      the next purchase and so on
--      
-- It's easy to compute using the DateDiff function, we saw this function when in 
-- working out session duration in the google analytics data project 1
SELECT os.customerkey,
       os.salesamount,
       os.[orderdate],
       cohorts.firstpurchdate,
       cohorts.cohortmonthly,
       ( Datediff(d, cohorts.firstpurchdate, os.orderdate) / 30 ) + 1 AS
       LifetimeMonth
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate])                              AS
                    FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS
                    CohortMonthly
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
ORDER  BY 1

-- Step 4 : Calculate Average the sales value for each cohort and group by the cohort
SELECT Avg(os.salesamount)                                            AS
       AvgCustSales,
       cohorts.cohortmonthly,
       ( Datediff(d, cohorts.firstpurchdate, os.orderdate) / 30 ) + 1 AS
       LifetimeMonth
FROM   [dbo].[onlinesales] os
       JOIN (SELECT customerkey,
                    Min([orderdate])                              AS
                    FirstPurchDate,
                    Cast(Year(Min([orderdate])) AS CHAR(4))
                    + '-'
                    + Cast(Month(Min([orderdate])) AS VARCHAR(2)) AS
                    CohortMonthly
             FROM   [onlinesales]
             GROUP  BY customerkey) AS cohorts
         ON os.customerkey = cohorts.customerkey
GROUP  BY cohortmonthly,
          ( Datediff(d, cohorts.firstpurchdate, os.orderdate) / 30 ) + 1
ORDER  BY 3  
