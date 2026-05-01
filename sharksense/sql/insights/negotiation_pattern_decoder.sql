-- =============================================================
-- SharkSense | Insight 4: Negotiation Pattern Decoder
-- File: negotiation_pattern_decoder.sql
-- Tables: pitches, deals, sectors, founders
-- Techniques: CTE, CASE classification, conditional aggregation
-- =============================================================

USE sharksense;

-- =============================================================
-- OUTPUT A: What does a typical pitch look like per outcome type?
-- =============================================================
WITH pitch_classified AS (
    SELECT
        p.pitch_id,
        s.industry_name,
        p.ask_amount_lakhs,
        p.asked_valuation,
        p.yearly_revenue,
        f.num_presenters,
        d.received_offer,
        d.accepted_offer,
        d.is_royalty_deal,
        d.deal_equity_pct,
        d.deal_amount_lakhs,
        CASE
            WHEN d.received_offer = 0                           THEN 'No Offer'
            WHEN d.received_offer = 1 AND d.accepted_offer = 0 THEN 'Offer Rejected by Founder'
            WHEN d.is_royalty_deal = 1                          THEN 'Royalty Deal'
            WHEN d.deal_equity_pct IS NOT NULL                  THEN 'Equity Deal'
            ELSE 'Other'
        END AS deal_type
    FROM pitches  p
    JOIN deals    d ON p.pitch_id = d.pitch_id
    JOIN sectors  s ON p.sector_id = s.sector_id
    JOIN founders f ON p.pitch_id = f.pitch_id
)
SELECT
    deal_type,
    COUNT(*)                                             AS pitch_count,
    ROUND(AVG(ask_amount_lakhs), 1)                     AS avg_ask_lakhs,
    ROUND(AVG(asked_valuation), 0)                      AS avg_valuation_asked,
    ROUND(AVG(yearly_revenue), 1)                       AS avg_revenue,
    ROUND(AVG(num_presenters), 1)                       AS avg_num_founders,
    ROUND(AVG(deal_equity_pct), 2)                      AS avg_equity_given,
    ROUND(AVG(deal_amount_lakhs), 1)                    AS avg_deal_amount
FROM pitch_classified
GROUP BY deal_type
ORDER BY pitch_count DESC;


-- =============================================================
-- OUTPUT B: Per-shark royalty preference
-- =============================================================
WITH shark_royalty AS (
    SELECT
        sh.shark_name,
        COUNT(*)                                          AS deals_done,
        SUM(d.is_royalty_deal)                           AS royalty_deals,
        ROUND(SUM(d.is_royalty_deal) * 100.0 / COUNT(*), 1) AS royalty_pct
    FROM sharks sh
    JOIN deals  d ON sh.pitch_id = d.pitch_id
    WHERE sh.invested = 1
    GROUP BY sh.shark_name
    HAVING COUNT(*) >= 5
)
SELECT
    shark_name,
    deals_done,
    royalty_deals,
    CONCAT(royalty_pct, '%') AS royalty_deal_pct
FROM shark_royalty
ORDER BY royalty_pct DESC;


-- =============================================================
-- OUTPUT C: Which sectors end up in royalty deals most?
-- =============================================================
WITH sector_royalty AS (
    SELECT
        s.industry_name,
        COUNT(*)                                              AS total_deals,
        SUM(d.is_royalty_deal)                               AS royalty_count,
        ROUND(SUM(d.is_royalty_deal) * 100.0 / COUNT(*), 1) AS royalty_rate_pct
    FROM deals   d
    JOIN pitches p ON d.pitch_id = p.pitch_id
    JOIN sectors s ON p.sector_id = s.sector_id
    WHERE d.accepted_offer = 1
    GROUP BY s.industry_name
    HAVING COUNT(*) >= 3
)
SELECT
    industry_name,
    total_deals,
    royalty_count,
    CONCAT(royalty_rate_pct, '%') AS royalty_rate
FROM sector_royalty
ORDER BY royalty_rate_pct DESC;