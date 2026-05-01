-- =============================================================
-- SharkSense | Insight 3: Unfunded Sector Map
-- Question: Which sectors had strong pitches but got rejected
--           consistently — India's startup funding blind spots?
-- Tables: pitches, deals, sectors
-- Techniques: CTE, PERCENTILE_CONT via subquery, conditional agg
-- =============================================================

USE sharksense;

-- Step 1: Find the median yearly revenue across all pitches
--         (only pitches that disclosed revenue, >0)
WITH revenue_median AS (
    SELECT AVG(yearly_revenue) AS median_revenue
    FROM (
        SELECT yearly_revenue,
               ROW_NUMBER() OVER (ORDER BY yearly_revenue) AS rn,
               COUNT(*) OVER ()                            AS total
        FROM pitches
        WHERE yearly_revenue > 0    -- exclude pre-revenue (0) and loss (-1)
    ) ranked
    WHERE rn IN (FLOOR((total+1)/2), CEIL((total+1)/2))
),

-- Step 2: Flag each pitch as above/below median revenue
pitch_flags AS (
    SELECT
        p.pitch_id,
        p.asked_valuation,
        p.yearly_revenue,
        s.industry_name,
        s.broad_category,
        d.received_offer,
        d.accepted_offer,
        -- A pitch is "strong" if revenue is above median
        CASE WHEN p.yearly_revenue > (SELECT median_revenue FROM revenue_median)
             THEN 1 ELSE 0 END AS is_above_median_revenue,
        -- Funded = received AND accepted an offer
        CASE WHEN d.received_offer=1 AND d.accepted_offer=1 THEN 1 ELSE 0 END AS got_funded
    FROM pitches p
    JOIN deals   d ON p.pitch_id = d.pitch_id
    JOIN sectors s ON p.sector_id = s.sector_id
    WHERE p.yearly_revenue IS NOT NULL
      AND p.yearly_revenue > 0    -- only revenue-generating businesses
),

-- Step 3: Aggregate by sector for strong pitches only
sector_blindspot AS (
    SELECT
        industry_name,
        broad_category,
        COUNT(*)                                AS strong_pitches,
        SUM(got_funded)                         AS funded_count,
        COUNT(*) - SUM(got_funded)              AS unfunded_count,
        ROUND(SUM(got_funded)*100.0/COUNT(*),1) AS funding_rate_pct,
        ROUND(AVG(asked_valuation),0)           AS avg_valuation_asked,
        ROUND(AVG(yearly_revenue),1)            AS avg_revenue_lakhs
    FROM pitch_flags
    WHERE is_above_median_revenue = 1
    GROUP BY industry_name, broad_category
    HAVING COUNT(*) >= 3
)

-- Step 4: Rank sectors by rejection rate (worst blind spots first)
SELECT
    RANK() OVER (ORDER BY funding_rate_pct ASC) AS blindspot_rank,
    industry_name,
    broad_category,
    strong_pitches                              AS above_median_rev_pitches,
    funded_count,
    unfunded_count,
    CONCAT(funding_rate_pct, '%')               AS funded_rate,
    CONCAT(100 - funding_rate_pct, '%')         AS rejection_rate,
    CONCAT('₹', FORMAT(avg_revenue_lakhs,1),'L') AS avg_revenue,
    CONCAT('₹', FORMAT(avg_valuation_asked,0),'L') AS avg_ask_valuation,
    CASE
        WHEN funding_rate_pct < 25 THEN '🔴 Systematic Blind Spot'
        WHEN funding_rate_pct < 45 THEN '🟠 Underserved Sector'
        WHEN funding_rate_pct < 60 THEN '🟡 Mixed'
        ELSE                            '🟢 Shark Favourite'
    END AS sector_status
FROM sector_blindspot
ORDER BY funding_rate_pct ASC;

-- =============================================================
-- WHAT THIS TELLS YOU:
-- These are sectors where businesses HAVE revenue (above median)
-- but still couldn't get a deal. This is NOT explained by weak
-- businesses — it's a systematic bias or gap in shark appetite.
-- Sectors ranked 1st are where sharks consistently ignore
-- financially viable businesses. These are India's funding gaps.
-- =============================================================