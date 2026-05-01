-- =============================================================
-- SharkSense | Insight 1: Valuation Correction Index
-- Question: By how much do founders overvalue themselves —
--           and does it vary by sector?
-- Tables: pitches, deals, sectors
-- Techniques: CTE, window functions, ROUND, CASE
-- =============================================================

USE sharksense;

-- Step 1: Base CTE — only closed deals have a Deal Valuation to compare
WITH deal_valuations AS (
    SELECT
        p.pitch_id,
        s.industry_name,
        s.broad_category,
        p.asked_valuation,
        d.deal_valuation,
        -- Valuation Correction % = how much sharks cut the founder's valuation
        ROUND(
            ((p.asked_valuation - d.deal_valuation) / p.asked_valuation) * 100,
            2
        ) AS correction_pct
    FROM pitches p
    JOIN deals   d ON p.pitch_id = d.pitch_id
    JOIN sectors s ON p.sector_id = s.sector_id
    WHERE d.deal_valuation IS NOT NULL    -- only closed deals
      AND p.asked_valuation > 0
),

-- Step 2: Aggregate by sector
sector_summary AS (
    SELECT
        industry_name,
        broad_category,
        COUNT(*)                            AS deals_analysed,
        ROUND(AVG(asked_valuation), 0)      AS avg_founder_valuation,
        ROUND(AVG(deal_valuation), 0)       AS avg_shark_valuation,
        ROUND(AVG(correction_pct), 1)       AS avg_correction_pct,
        ROUND(MIN(correction_pct), 1)       AS min_correction_pct,
        ROUND(MAX(correction_pct), 1)       AS max_correction_pct
    FROM deal_valuations
    GROUP BY industry_name, broad_category
    HAVING COUNT(*) >= 3                   -- only sectors with enough data points
)

-- Step 3: Final output — ranked by overvaluation (worst offenders first)
SELECT
    RANK() OVER (ORDER BY avg_correction_pct DESC) AS overvaluation_rank,
    industry_name,
    broad_category,
    deals_analysed,
    CONCAT('₹', FORMAT(avg_founder_valuation, 0), 'L') AS founder_asks,
    CONCAT('₹', FORMAT(avg_shark_valuation,   0), 'L') AS sharks_value_at,
    CONCAT(avg_correction_pct, '%')                    AS avg_markdown,
    CONCAT(min_correction_pct, '% to ', max_correction_pct, '%') AS correction_range,
    CASE
        WHEN avg_correction_pct > 60 THEN '🔴 Severely Overvalued'
        WHEN avg_correction_pct > 40 THEN '🟠 Overvalued'
        WHEN avg_correction_pct > 20 THEN '🟡 Moderately Priced'
        ELSE                               '🟢 Realistically Priced'
    END AS valuation_signal
FROM sector_summary
ORDER BY avg_correction_pct DESC;

-- =============================================================
-- WHAT THIS TELLS YOU:
-- Sectors at the top overvalue the most — sharks consistently
-- cut their ask by the shown %. Sectors at the bottom have
-- founders who price themselves closest to what sharks accept.
-- A correction of 50% means a founder asking ₹10Cr walked
-- away with a deal implying ₹5Cr company value.
-- =============================================================