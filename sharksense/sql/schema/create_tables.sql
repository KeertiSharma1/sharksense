-- =============================================================
-- SharkSense: India's Startup Pitch Intelligence System
-- File: create_tables.sql
-- Purpose: Create the normalized relational schema
-- Database: MySQL 8.0+
-- All monetary values are in LAKHS INR
-- =============================================================

CREATE DATABASE IF NOT EXISTS sharksense;
USE sharksense;

-- Drop tables in reverse dependency order if re-running
DROP TABLE IF EXISTS sharks;
DROP TABLE IF EXISTS deals;
DROP TABLE IF EXISTS founders;
DROP TABLE IF EXISTS pitches;
DROP TABLE IF EXISTS sectors;

-- =============================================================
-- TABLE 1: sectors
-- Lookup table for industry categories
-- =============================================================
CREATE TABLE sectors (
    sector_id       INT AUTO_INCREMENT PRIMARY KEY,
    industry_name   VARCHAR(100) NOT NULL UNIQUE,
    broad_category  VARCHAR(50)  NOT NULL
    -- broad_category groups industries into:
    -- Consumer, Technology, Health, Industrial, Sustainability
);

-- =============================================================
-- TABLE 2: pitches
-- One row per startup pitch. Core fact table.
-- =============================================================
CREATE TABLE pitches (
    pitch_id            INT PRIMARY KEY,   -- = Pitch Number from CSV
    startup_name        VARCHAR(200) NOT NULL,
    season_number       TINYINT      NOT NULL,
    episode_number      TINYINT      NOT NULL,
    sector_id           INT          NOT NULL,
    ask_amount_lakhs    DECIMAL(10,2),     -- Original Ask Amount
    ask_equity_pct      DECIMAL(6,2),      -- Original Offered Equity %
    asked_valuation     DECIMAL(12,2),     -- Valuation Requested by founder
    yearly_revenue      DECIMAL(12,2),     -- -1 = loss, 0 = pre-revenue, NULL = not disclosed
    monthly_sales       DECIMAL(10,2),
    gross_margin_pct    DECIMAL(6,2),
    started_year        YEAR,
    bootstrapped        VARCHAR(10),       -- 'yes', 'no', 'funded'
    has_patents         VARCHAR(5),        -- 'Yes', 'No'
    FOREIGN KEY (sector_id) REFERENCES sectors(sector_id)
);

-- =============================================================
-- TABLE 3: founders
-- Presenter/founder details per pitch
-- =============================================================
CREATE TABLE founders (
    founder_id          INT AUTO_INCREMENT PRIMARY KEY,
    pitch_id            INT          NOT NULL UNIQUE,
    num_presenters      TINYINT,
    male_presenters     TINYINT,
    female_presenters   TINYINT,
    is_couple           TINYINT,           -- 1 = husband-wife team
    pitcher_city        VARCHAR(100),
    pitcher_state       VARCHAR(100),
    avg_age_group       VARCHAR(20),       -- 'young' (<30), 'middle' (30-50), 'old' (>50)
    FOREIGN KEY (pitch_id) REFERENCES pitches(pitch_id)
);

-- =============================================================
-- TABLE 4: deals
-- Outcome of each pitch — NULL deal columns = no deal closed
-- =============================================================
CREATE TABLE deals (
    deal_id                 INT AUTO_INCREMENT PRIMARY KEY,
    pitch_id                INT          NOT NULL UNIQUE,
    received_offer          TINYINT      NOT NULL,  -- 1 = sharks made an offer
    accepted_offer          TINYINT,                -- 1 = founder accepted, 0 = rejected, NULL = no offer made
    deal_amount_lakhs       DECIMAL(10,2),          -- NULL if no deal
    deal_equity_pct         DECIMAL(6,2),
    deal_debt_lakhs         DECIMAL(10,2),
    debt_interest_pct       DECIMAL(6,2),
    deal_valuation          DECIMAL(12,2),          -- Implied valuation by sharks
    num_sharks_in_deal      TINYINT,                -- NULL if no deal
    is_multi_shark          TINYINT                 -- 1 = multiple sharks, 0 = solo shark
        GENERATED ALWAYS AS (IF(num_sharks_in_deal > 1, 1, 0)) VIRTUAL,
    is_royalty_deal         TINYINT,                -- 1 = royalty structure
    royalty_percentage      DECIMAL(6,2),
    deal_has_conditions     VARCHAR(5),             -- 'Yes', 'No'
    advisory_shares_pct     DECIMAL(6,2),
    FOREIGN KEY (pitch_id) REFERENCES pitches(pitch_id)
);

-- =============================================================
-- TABLE 5: sharks
-- Per-shark investment record per pitch (one row per shark per pitch)
-- Only rows where shark was PRESENT in episode
-- =============================================================
CREATE TABLE sharks (
    shark_record_id     INT AUTO_INCREMENT PRIMARY KEY,
    pitch_id            INT          NOT NULL,
    shark_name          VARCHAR(50)  NOT NULL,      -- 'Namita', 'Vineeta', etc.
    was_present         TINYINT      NOT NULL,      -- 1 = in the episode
    invested            TINYINT      NOT NULL,      -- 1 = put money in
    investment_amount   DECIMAL(10,2),              -- NULL if did not invest
    investment_equity   DECIMAL(6,2),
    debt_amount         DECIMAL(10,2),
    FOREIGN KEY (pitch_id) REFERENCES pitches(pitch_id),
    UNIQUE KEY uq_shark_pitch (pitch_id, shark_name)
);

-- =============================================================
-- Indexes for query performance
-- =============================================================
CREATE INDEX idx_pitches_season   ON pitches(season_number);
CREATE INDEX idx_pitches_sector   ON pitches(sector_id);
CREATE INDEX idx_sharks_name      ON sharks(shark_name);
CREATE INDEX idx_sharks_invested  ON sharks(invested);
CREATE INDEX idx_deals_offer      ON deals(received_offer, accepted_offer);