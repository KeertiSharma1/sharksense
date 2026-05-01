-- =============================================================
-- SharkSense | Insight 5: The Multiple Shark Illusion
-- Question: Do founders with multiple sharks actually get
--           worse deals than those with one committed shark?
-- Tables: pitches, deals, sectors
-- Techniques: CTE, window functions, GROUP BY comparison
-- =============================================================

USE sharksense;

-- Step 1: Tag every closed deal as single-shark or multi-shark
WITH deal_type_base AS (
    SELECT
        p.pitch_id,
        s.industry_name,
        s.broad_category,
        p.asked_valuation,
        d.deal_valuation,
        d.deal_equity_pct,
        d.deal_amount_lakhs,
        d.num_sharks_in_deal,
        -- Valuation correction: how much did sharks cut the founder's valuation?
        ROUND(
            (p.asked_valuation - d.deal_valuation) / p.asked_valuation * 100,
            2
        ) AS valuation_markdown_pct,
        -- Deal structure label
        CASE
            WHEN d.num_sharks_in_deal = 1 THEN 'Single Shark'
            WHEN d.num_sharks_in_deal = 2 THEN 'Two Sharks'
            WHEN d.num_sharks_in_deal >= 3 THEN 'Three+ Sharks'
        END AS shark_count_label
    FROM pitches p
    JOIN deals   d ON p.pitch_id = d.pitch_id
    JOIN sectors s ON p.sector_id = s.sector_id
    WHERE d.accepted_offer = 1
      AND d.deal_valuation IS NOT NULL
      AND p.asked_valuation > 0
      AND d.num_sharks_in_deal IS NOT NULL
),

-- Step 2: Summary comparison — single vs multi
overall_comparison AS (
    SELECT
        shark_count_label,
        COUNT(*)                                       AS deals,
        ROUND(AVG(deal_equity_pct), 2)                AS avg_equity_given_pct,
        ROUND(AVG(asked_valuation), 0)                AS avg_founder_valuation,
        ROUND(AVG(deal_valuation), 0)                 AS avg_deal_valuation,
        ROUND(AVG(valuation_markdown_pct), 1)         AS avg_valuation_cut_pct,
        ROUND(AVG(deal_amount_lakhs), 1)              AS avg_money_raised,
        ROUND(MIN(deal_equity_pct), 2)                AS min_equity_given,
        ROUND(MAX(deal_equity_pct), 2)                AS max_equity_given
    FROM deal_type_base
    WHERE shark_count_label IS NOT NULL
    GROUP BY shark_count_label
),

-- Step 3: Sector-level breakdown — does the pattern hold across industries?
sector_breakdown AS (
    SELECT
        industry_name,
        shark_count_label,
        COUNT(*)                                       AS deals,
        ROUND(AVG(deal_equity_pct), 2)                AS avg_equity,
        ROUND(AVG(valuation_markdown_pct), 1)         AS avg_valuation_cut
    FROM deal_type_base
    WHERE shark_count_label IS NOT NULL
    GROUP BY industry_name, shark_count_label
    HAVING COUNT(*) >= 2
),

-- Step 4: For each sector, does multi-shark = more equity given?
sector_verdict AS (
    SELECT
        industry_name,
        MAX(CASE WHEN shark_count_label='Single Shark' THEN avg_equity END) AS single_equity,
        MAX(CASE WHEN shark_count_label IN ('Two Sharks','Three+ Sharks') THEN avg_equity END) AS multi_equity,
        MAX(CASE WHEN shark_count_label='Single Shark' THEN avg_valuation_cut END) AS single_vcut,
        MAX(CASE WHEN shark_count_label IN ('Two Sharks','Three+ Sharks') THEN avg_valuation_cut END) AS multi_vcut
    FROM sector_breakdown
    GROUP BY industry_name
    HAVING single_equity IS NOT NULL AND multi_equity IS NOT NULL
)

-- OUTPUT A: Overall comparison (the headline finding)
-- SELECT
--     'OVERALL' AS analysis_level,
--     shark_count_label,
--     deals,
--     CONCAT(avg_equity_given_pct, '%')              AS avg_equity_given,
--     CONCAT('₹', FORMAT(avg_founder_valuation,0),'L') AS founder_valued_at,
--     CONCAT('₹', FORMAT(avg_deal_valuation,0),'L')    AS sharks_valued_at,
--     CONCAT(avg_valuation_cut_pct, '%')             AS valuation_markdown,
--     CONCAT('₹', avg_money_raised, 'L')             AS avg_money_raised
-- FROM overall_comparison
-- ORDER BY deals DESC;

-- OUTPUT B: Sector-level verdict — is illusion sector-specific?
SELECT
    industry_name,
    ROUND(single_equity, 2)  AS single_shark_equity_pct,
    ROUND(multi_equity, 2)   AS multi_shark_equity_pct,
    ROUND(multi_equity - single_equity, 2)   AS equity_premium_for_extra_sharks,
    ROUND(single_vcut, 1)    AS single_shark_val_cut_pct,
    ROUND(multi_vcut, 1)     AS multi_shark_val_cut_pct,
    CASE
        WHEN multi_equity > single_equity AND multi_vcut > single_vcut
             THEN '🔴 Illusion CONFIRMED — more sharks = worse deal'
        WHEN multi_equity > single_equity AND multi_vcut <= single_vcut
             THEN '🟡 Mixed — more equity given but better valuation'
        WHEN multi_equity <= single_equity
             THEN '🟢 Illusion BUSTED — multi-shark deals are fine here'
        ELSE '⚪ Inconclusive'
    END AS illusion_verdict
FROM sector_verdict
ORDER BY equity_premium_for_extra_sharks DESC;

-- =============================================================
-- WHAT THIS TELLS YOU:
-- OUTPUT A: At the aggregate level — do single-shark deals
--   protect founder valuation better than multi-shark deals?
-- OUTPUT B: The sector verdict tells you WHERE the illusion
--   is real and where it isn't. If multi_equity > single_equity
--   AND valuation cut is higher → founders are systematically
--   giving away more when more sharks pile in.
-- =============================================================