-- =============================================================
-- SharkSense | Insight 2: Shark DNA Matrix
-- Question: What is each shark's actual investment pattern-
--           vs their public persona?
-- Tables: sharks, pitches, deals, sectors
-- Techniques: CTE, conditional aggregation, window functions
-- =============================================================

USE sharksense;

-- Step 1: Shark-level investment summary
WITH shark_base AS (
    SELECT
        sh.shark_name,
        sh.pitch_id,
        sh.was_present,
        sh.invested,
        sh.investment_amount,
        sh.investment_equity,
        d.num_sharks_in_deal,
        d.is_royalty_deal,
        s.industry_name,
        s.broad_category
    FROM sharks sh
    JOIN pitches p ON sh.pitch_id = p.pitch_id
    JOIN deals   d ON sh.pitch_id = d.pitch_id
    JOIN sectors s ON p.sector_id = s.sector_id
    WHERE sh.was_present = 1
),

-- Step 2: Aggregate per shark
shark_profile AS (
    SELECT
        shark_name,
        COUNT(*)                                        AS episodes_present,
        SUM(invested)                                   AS total_deals_done,
        ROUND(SUM(invested) * 100.0 / COUNT(*), 1)     AS investment_rate_pct,
        ROUND(AVG(CASE WHEN invested=1 THEN investment_amount END), 1) AS avg_ticket_lakhs,
        ROUND(SUM(CASE WHEN invested=1 THEN investment_amount ELSE 0 END), 0) AS total_deployed_lakhs,
        ROUND(AVG(CASE WHEN invested=1 THEN investment_equity END), 2)  AS avg_equity_taken_pct,
        -- Solo deal preference
        SUM(CASE WHEN invested=1 AND num_sharks_in_deal=1 THEN 1 ELSE 0 END) AS solo_deals,
        SUM(CASE WHEN invested=1 AND num_sharks_in_deal>1 THEN 1 ELSE 0 END) AS group_deals,
        -- Royalty preference
        SUM(CASE WHEN invested=1 AND is_royalty_deal=1 THEN 1 ELSE 0 END)   AS royalty_deals
    FROM shark_base
    GROUP BY shark_name
),

-- Step 3: Each shark's top sector by deal count
shark_top_sector AS (
    SELECT
        shark_name,
        industry_name AS favourite_sector,
        sector_deal_count,
        ROW_NUMBER() OVER (PARTITION BY shark_name ORDER BY sector_deal_count DESC) AS rn
    FROM (
        SELECT
            shark_name,
            industry_name,
            COUNT(*) AS sector_deal_count
        FROM shark_base
        WHERE invested = 1
        GROUP BY shark_name, industry_name
    ) sector_counts
)

-- Final: Join profile + top sector
SELECT
    sp.shark_name,
    sp.episodes_present,
    sp.total_deals_done,
    CONCAT(sp.investment_rate_pct, '%')               AS deal_rate,
    CONCAT('₹', sp.avg_ticket_lakhs, 'L')             AS avg_ticket_size,
    CONCAT('₹', FORMAT(sp.total_deployed_lakhs,0),'L') AS total_capital_deployed,
    CONCAT(sp.avg_equity_taken_pct, '%')              AS avg_equity_taken,
    sp.solo_deals,
    sp.group_deals,
    ROUND(sp.solo_deals * 100.0 / NULLIF(sp.total_deals_done,0), 0) AS solo_deal_pct,
    sp.royalty_deals,
    ts.favourite_sector,
    CASE
        WHEN sp.investment_rate_pct > 40 THEN 'High Activity'
        WHEN sp.investment_rate_pct > 25 THEN 'Selective'
        ELSE                                  'Very Selective'
    END AS investment_style,
    CASE
        WHEN sp.avg_equity_taken_pct > 10 THEN 'Equity Aggressive'
        WHEN sp.avg_equity_taken_pct > 6  THEN 'Balanced'
        ELSE                                   'Equity Friendly'
    END AS equity_stance
FROM shark_profile sp
JOIN shark_top_sector ts ON sp.shark_name = ts.shark_name AND ts.rn = 1
ORDER BY sp.investment_rate_pct DESC;

-- =============================================================
-- WHAT THIS TELLS YOU:
-- Each row is a data-built profile of one shark.
-- "Deal rate" = out of every episode they sat in, how often
-- did they actually write a cheque?
-- "Solo deal %" = do they like to go alone or share risk?
-- Compare avg_equity_taken — a high number means that shark
-- is expensive for founders to get money from.
-- =============================================================