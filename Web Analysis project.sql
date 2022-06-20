-- 1:	Pageviews vs bounce rate by day

select
	 pa.DateKey
	,sum(pa.[PageViews]) as [PageViews] 
	,avg(pa.BounceRatePct) as AvgBounceRatePct
from
	[dbo].[PageAnalysis] pa inner join
	[dbo].[Calendar] cal on pa.DateKey = cal.DateKey
group by
	 pa.DateKey
order by 
	 pa.DateKey

-- 2:	Pageviews vs bounce by week

select
	 cal.YearNum
	,cal.WeekNumYear
	,sum(pa.[PageViews]) as [PageViews] 
	,avg(pa.BounceRatePct) as AvgBounceRatePct
from
	[dbo].[PageAnalysis] pa inner join
	[dbo].[Calendar] cal on pa.DateKey = cal.DateKey
group by
	 cal.YearNum
	,cal.WeekNumYear
order by 
	 cal.YearNum
	,cal.WeekNumYear

--  3:  Pageviews vs bounce rate by month

select
	 cal.[MonthYearName]
	,sum(pa.[PageViews]) as [PageViews] 
	,avg(pa.BounceRatePct) as AvgBounceRatePct
from
	[dbo].[PageAnalysis] pa inner join
	[dbo].[Calendar] cal on pa.DateKey = cal.DateKey
group by
	cal.[MonthYearName]
order by 
	cal.[MonthYearName]
		
-- 4:	Avg session duration New visitor by week

select
	 year([DateKey]) as YearNum
	,datepart(week,[DateKey]) as WeekNum
	,avg(datediff(millisecond,0,AvgSessionDuration))/1000 as  AvgSessionDuration
	,count(va.[UserTypeKey]) as WeeklyNewVisitor
from
	[dbo].[VisitorAnalysis] va inner join
	[dbo].[UserType] ut on va.UserTypeKey = ut.UserTypeKey and
                                            ut.UserType = 'New Visitor'
group by
	 year([DateKey]) 
	,datepart(week,[DateKey]) 
order by 
	 year([DateKey]) 
	,datepart(week,[DateKey]) 

-- 4a:	Avg session duration Returning visitor by week	

	select
		 year([DateKey]) as YearNum
		,datepart(week,[DateKey]) as WeekNum
		,avg(datediff(millisecond,0,AvgSessionDuration))/1000 as  AvgSessionDuration		-- Use Datediff here to calculate the seconds as we cannot just use numeri functions on time data types
		,count(va.[UserTypeKey]) as WeeklyReturningVisitor
	from
		[dbo].[VisitorAnalysis] va inner join
		[dbo].[UserType] ut on va.UserTypeKey = ut.UserTypeKey and
                                                ut.UserType = 'Returning Visitor'
	group by
		 year([DateKey]) 
		,datepart(week,[DateKey]) 
	order by 
		 year([DateKey]) 
		,datepart(week,[DateKey]) 


-- 5:	Sessions vs avg Pages/Session by week

select
	 year([DateKey]) as YearNum
	,datepart(week,[DateKey]) as WeekNum
	,sum([Sessions]) as Sessions
	,cast(avg([PagesSession]) as decimal(18,2)) as AvgPagesSession
from
	[dbo].[VisitorAnalysis] va
group by
	 year([DateKey]) 
	,datepart(week,[DateKey])
order by 
	 year([DateKey]) 
	,datepart(week,[DateKey])

-- 6:	New users vs Pageviews by week

select
	 year(DateKey) as YearNum	
	,datepart(week,[DateKey]) as WeekNum
	,sum([NewUsers]) as NewUsers
	,sum([PageViews]) as PageViews
from
	[dbo].[PageAnalysis]
group by
	 year([DateKey]) 
	,datepart(week,[DateKey]) 
order by 
	 year([DateKey]) 
	,datepart(week,[DateKey]) 

