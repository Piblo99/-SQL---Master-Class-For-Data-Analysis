-- 1:  Pageviews vs bounce rate by day
SELECT pa.datekey,
       Sum(pa.[pageviews])   AS [PageViews],
       Avg(pa.bounceratepct) AS AvgBounceRatePct
FROM   [dbo].[pageanalysis] pa
       INNER JOIN [dbo].[calendar] cal
               ON pa.datekey = cal.datekey
GROUP  BY pa.datekey
ORDER  BY pa.datekey

-- 2:  Pageviews vs bounce by week
SELECT cal.yearnum,
       cal.weeknumyear,
       Sum(pa.[pageviews])   AS [PageViews],
       Avg(pa.bounceratepct) AS AvgBounceRatePct
FROM   [dbo].[pageanalysis] pa
       INNER JOIN [dbo].[calendar] cal
               ON pa.datekey = cal.datekey
GROUP  BY cal.yearnum,
          cal.weeknumyear
ORDER  BY cal.yearnum,
          cal.weeknumyear

--  3:  Pageviews vs bounce rate by month
SELECT cal.[monthyearname],
       Sum(pa.[pageviews])   AS [PageViews],
       Avg(pa.bounceratepct) AS AvgBounceRatePct
FROM   [dbo].[pageanalysis] pa
       INNER JOIN [dbo].[calendar] cal
               ON pa.datekey = cal.datekey
GROUP  BY cal.[monthyearname]
ORDER  BY cal.[monthyearname]

-- 4:  Avg session duration New visitor by week
SELECT Year([datekey]) AS YearNum,
       Datepart(week, [datekey]) AS WeekNum,
       Avg(Datediff(millisecond, 0, avgsessionduration)) / 1000 AS
       AvgSessionDuration,
       Count(va.[usertypekey]) AS WeeklyNewVisitor
FROM   [dbo].[visitoranalysis] va
       INNER JOIN [dbo].[usertype] ut
               ON va.usertypekey = ut.usertypekey
                  AND ut.usertype = 'New Visitor'
GROUP  BY Year([datekey]),
          Datepart(week, [datekey])
ORDER  BY Year([datekey]),
          Datepart(week, [datekey])

-- 4a:  Avg session duration Returning visitor by week  
SELECT Year([datekey]) AS YearNum,
       Datepart(week, [datekey]) AS WeekNum,
       Avg(Datediff(millisecond, 0, avgsessionduration)) / 1000 AS
       AvgSessionDuration
       -- Use Datediff here to calculate the seconds as we cannot just use numeri functions on time data types
       ,
       Count(va.[usertypekey]) AS WeeklyReturningVisitor
FROM   [dbo].[visitoranalysis] va
       INNER JOIN [dbo].[usertype] ut
               ON va.usertypekey = ut.usertypekey
                  AND ut.usertype = 'Returning Visitor'
GROUP  BY Year([datekey]),
          Datepart(week, [datekey])
ORDER  BY Year([datekey]),
          Datepart(week, [datekey])

-- 5:  Sessions vs avg Pages/Session by week
SELECT Year([datekey]) AS YearNum,
       Datepart(week, [datekey]) AS WeekNum,
       Sum([sessions]) AS Sessions,
       Cast(Avg([pagessession]) AS DECIMAL(18, 2)) AS AvgPagesSession
FROM   [dbo].[visitoranalysis] va
GROUP  BY Year([datekey]),
          Datepart(week, [datekey])
ORDER  BY Year([datekey]),
          Datepart(week, [datekey])

-- 6:  New users vs Pageviews by week
SELECT Year(datekey) AS YearNum,
       Datepart(week, [datekey]) AS WeekNum,
       Sum([newusers]) AS NewUsers,
       Sum([pageviews]) AS PageViews
FROM   [dbo].[pageanalysis]
GROUP  BY Year([datekey]),
          Datepart(week, [datekey])
ORDER  BY Year([datekey]),
          Datepart(week, [datekey]) 
