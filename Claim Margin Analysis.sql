/*
  Insurance claims profit analysis 
  -- Scenario --- Understanding policy margins by type , are we profitable ? Bear in mind this is totally fictitious data and bears no
            resemblance to any insurance business , living or deceased!
*/
USE [Chapter 4 - Insurance];

-- The product manager wants a simple statement of the profitability of TPD insurance for years 2012 to 2014
-- The Claims value will be compared to ALL TPD premiums to establish the margin (profit)
-- This query only returns the Claimant Premium, which is fine if analysing the claims/claimant margin, but we
-- want ALL of TPD premiums regardless, for further analysis
SELECT [underwriting_year],
       cl.claimtype,
       [total_tpd_cover_premium],
       Sum(claimpaidamount) AS TotalClaimPaid,
       Sum([total_tpd_cover_premium]) - Sum(cl.claimpaidamount) AS CoverProfit
FROM   [dbo].[memberclaims] cl
       INNER JOIN [dbo].[membercover] mc
               ON cl.memberkey = mc.memberkey
                  AND cl.claimtype = 'TPD'
                  AND Year(cl.claimpaiddate) IN ( 2012, 2013, 2014 )
                  AND underwriting_year = Year(cl.claimpaiddate)
GROUP  BY [underwriting_year],
          cl.claimtype,
          [total_tpd_cover_premium]
ORDER  BY [underwriting_year]

-- We use an outer apply to see ALL TPD premiums as that is what was requested, it is important a 
-- data analyst comprehends the question fully, question the user or yourself when looking for insight
-- as misunderstanding the question can be disastrous 
SELECT YearlyPremium.underwriting_year,
       cl.claimtype,
       YearlyPremium.tpdcoverpremium,
       Sum(claimpaidamount) AS TotalClaimPaid,
       YearlyPremium.tpdcoverpremium - Sum(cl.claimpaidamount) AS CoverProfit
FROM   [dbo].[memberclaims] cl
       OUTER apply (SELECT underwriting_year,
                           Sum([total_death_cover_premium]) AS DTHCoverPremium,
                           Sum([total_tpd_cover_premium])   AS TPDCoverPremium,
                           Sum([total_ip_cover_premium])    AS IPCoverPremium
                    FROM   [dbo].[membercover] mc
                    WHERE  mc.underwriting_year = Year(cl.claimpaiddate)
                    GROUP  BY underwriting_year) AS YearlyPremium
WHERE  Year(cl.claimpaiddate) IN ( 2012, 2013, 2014 )
       AND cl.claimtype = 'TPD'
GROUP  BY YearlyPremium.underwriting_year,
          YearlyPremium.tpdcoverpremium,
          cl.claimtype

-- The product manager wants a simple statement of the profitability of DTH insurance for years 2012 to 2014
-- The Claims value will be compared to ALL DTH premiums to establish the margin (profit)
-- Include the claim count and the policy holder count
SELECT YearlyPremium.underwriting_year,
       cl.claimtype,
       Count(claimtype) AS ClaimCount,
       YearlyPremium.dthcoverpremium,
       dthpolicyholders,
       Sum(claimpaidamount) AS TotalClaimPaid
       ,
       YearlyPremium.dthcoverpremium - Sum(cl.claimpaidamount) AS CoverProfit
FROM   [dbo].[memberclaims] cl
       OUTER apply (SELECT underwriting_year,
                           Sum([total_death_cover_premium])   AS DTHCoverPremium,
                           Sum([total_tpd_cover_premium])     AS TPDCoverPremium,
                           Sum([total_ip_cover_premium])      AS IPCoverPremium,
                           Count([total_death_cover_premium]) AS DTHPolicyHolders,
                           Count([total_tpd_cover_premium])   AS TPDPolicyHolders,
                           Count([total_ip_cover_premium])    AS IPPolicyHolders
                    FROM   [dbo].[membercover] mc
                    WHERE  mc.underwriting_year = Year(cl.claimpaiddate)
                    GROUP  BY underwriting_year) AS YearlyPremium
WHERE  Year(cl.claimpaiddate) IN ( 2012, 2013, 2014 )
       AND cl.claimtype = 'DTH'
GROUP  BY YearlyPremium.underwriting_year,
          YearlyPremium.dthcoverpremium,
          YearlyPremium.dthpolicyholders,
          cl.claimtype
-- How many claims for 2013           ? A: = 40
-- How many policy holders for 2014   ? A: = 7480
-- What year was the least profitable ? A: = 2013
