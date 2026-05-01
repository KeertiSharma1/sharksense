# SharkSense 🦈
### India's First Data-Driven Startup Pitch Intelligence System

> A structured SQL analytics project that reverse-engineers investment decisions across 478 pitches from Shark Tank India (Seasons 1–3) into five business-grade intelligence systems — covering valuation behaviour, investor profiling, market blind spots, negotiation mechanics, and deal structure analysis.

---

## Why This Project Exists

Shark Tank India is one of the few public datasets where **every variable of an early-stage investment negotiation is recorded**: founder ask, shark counter, deal structure, sector, team composition, and outcome. This makes it a uniquely rich proxy for studying startup funding behaviour in the Indian market.

The goal was not to analyse a TV show — it was to treat this dataset as a **structured behavioural finance problem** and build an analytical system that answers questions real investors and founders actually need answered.

---

## Project Architecture

```
sharksense/
├── sql/
│   ├── schema/
│   │   └── create_tables.sql       ← Normalised relational schema (5 tables)
│   ├── data_load/
│   │   └── load_data.sql           ← Cleaned INSERT statements for all tables
│   └── insights/
│       ├── valuation_correction_index.sql
│       ├── shark_dna_matrix.sql
│       ├── unfunded_sector_map.sql
│       ├── negotiation_pattern_decoder.sql
│       └── multishark_illusion.sql
├── data/
│   └── Shark_Tank_India.csv           ← Source: Kaggle (thirumani/shark-tank-india)
└── docs/
    └── README.md
```

---

## Schema Design

The raw Kaggle data is a single 80-column flat file. This project normalises it into a **5-table relational schema** that separates concerns cleanly:

| Table | Rows | Purpose |
|---|---|---|
| `sectors` | 18 | Industry lookup with broad category grouping |
| `pitches` | 478 | Core fact table — one row per startup pitch |
| `founders` | 478 | Presenter demographics and background |
| `deals` | 478 | Outcome of each pitch (NULL columns = no deal) |
| `sharks` | ~2,055 | Per-shark investment record per pitch |

**Key design decisions:**
- `deals.is_multi_shark` is a **generated column** computed from `num_sharks_in_deal` — no data duplication
- All monetary values stored in **Lakhs INR** for consistency with source data
- `yearly_revenue = -1` means loss; `= 0` means pre-revenue — preserved as meaningful signals, not cleaned out
- `sharks` table is in **long format** (one row per shark per pitch) to enable per-shark aggregation without 7-column pivots

---

## The Five Insights

### Insight 1 — Valuation Correction Index
**Question:** By how much do founders overvalue themselves, and does this vary by sector?

**Method:** Compare `asked_valuation` (founder's claim) vs `deal_valuation` (shark's implied valuation on closed deals). Compute correction percentage per sector, rank, and classify.

**SQL techniques:** CTE chain, window function `RANK()`, conditional `CASE` classification, `HAVING` filter for statistical significance.

---

### Insight 2 — Shark DNA Matrix
**Question:** What is each shark's actual investment pattern — beyond their public reputation?

**Method:** For each shark: compute investment rate (deals / episodes present), average ticket size, total capital deployed, equity demanded, solo vs group deal split, and top sector by deal count.

**SQL techniques:** Multi-table JOIN chain, conditional aggregation with `CASE WHEN`, `PARTITION BY` window for top-sector extraction via `ROW_NUMBER()`.

---

### Insight 3 — Unfunded Sector Map
**Question:** Which sectors showed strong revenue but still couldn't raise funding — India's investment blind spots?

**Method:** Compute median revenue across all disclosing pitches. Filter to pitches *above* that median. Measure funding rate per sector. Sectors with low funding rates despite strong revenue signal systematic shark bias, not business weakness.

**SQL techniques:** Median computation via row-numbering subquery, CTE layering, `PERCENTILE` approximation in MySQL, `HAVING` for minimum sample size.

---

### Insight 4 — Negotiation Pattern Decoder
**Question:** What triggers a royalty deal vs equity deal vs rejection?

**Method:** Classify every pitch outcome into four categories (No Offer / Founder Rejected / Royalty Deal / Equity Deal). Profile each category by ask size, valuation, revenue, and team size. Separately compute per-shark and per-sector royalty tendency.

**SQL techniques:** Multi-output CTE query, outcome classification with nested `CASE`, conditional aggregation, three separate output sections from one SQL file.

---

### Insight 5 — The Multiple Shark Illusion
**Question:** Do founders who attract multiple sharks actually end up giving away more equity and accepting deeper valuation cuts than founders who close with one committed shark?

**Method:** Split all closed deals into Single / Two / Three+ shark groups. Compare average equity given and valuation markdown across groups. Run the same comparison sector-by-sector to identify where the illusion holds and where it breaks.

**SQL techniques:** `CASE` deal classification, aggregation with `MAX(CASE...)` pivot pattern, verdict labelling logic, window ordering.

---

## How to Run This Project

**Prerequisites:** MySQL 8.0+ installed

```bash
# Step 1: Log into MySQL
mysql -u root -p

# Step 2: Run schema creation
source /path/to/sharksense/sql/schema/create_tables.sql

# Step 3: Load the data
source /path/to/sharksense/sql/data_load/load_data.sql

# Step 4: Run any insight query
source /path/to/sharksense/sql/insights/valuation_correction_index.sql
```

---

## Dataset

- **Source:** [Shark Tank India Dataset — Kaggle (thirumani)](https://www.kaggle.com/datasets/thirumani/shark-tank-india)
- **Scope used:** Seasons 1, 2, and 3 (478 pitches)
- **Seasons 4–5 excluded** to keep the shark panel consistent (same 7 core sharks)
- **All monetary values:** Lakhs INR

---

## Technical Stack

| Component | Tool |
|---|---|
| Database | MySQL 8.0 |
| SQL features used | CTEs, Window Functions (`RANK`, `ROW_NUMBER`, `PARTITION BY`), Multi-table JOINs, Conditional Aggregation, Generated Columns |
| Data preparation | Python (pandas) — for generating clean INSERT statements from raw CSV |
| Version control | Git / GitHub |

---

## Key Findings (Headline Results)

*Run the queries to generate your own numbers — findings will vary slightly based on MySQL version and NULL handling.*

- **Valuation Correction Index:** Food & Beverage and Lifestyle sectors show the deepest valuation markdowns — founders consistently ask 2–4x what sharks are willing to imply through deals.
- **Shark DNA:** Investment rates vary from ~20% to ~45% across sharks — the sharks perceived as "generous" are not always the most active investors by volume.
- **Blind Spots:** Certain sectors show above-median revenue but below-25% funding rates — suggesting shark portfolio bias rather than business quality driving rejection.
- **Royalty Triggers:** Royalty deals cluster in specific sectors and are strongly associated with one or two individual sharks — not a panel-wide preference.
- **Multiple Shark Illusion:** At the aggregate level, multi-shark deals show higher average equity dilution — but the pattern is sector-dependent, not universal.

---

## Sample Output Screenshots

### Insight 1 — Valuation Correction Index
![Valuation Correction](screenshots/insight1_valuation_correction.png)

### Insight 2 — Shark DNA Matrix
![Shark DNA](screenshots/insight2_shark_dna.png)

### Insight 3 — Unfunded Sector Map
![Unfunded Sectors](screenshots/insight3_unfunded_sectors.png)

### Insight 4 — Negotiation Pattern Decoder
![Negotiation Patterns](screenshots/insight4a.png)

### Insight 5 — Multiple Shark Illusion
![Multishark Illusion](screenshots/insight5a_overall.png)

## About

Built as a portfolio project demonstrating SQL system design, analytical thinking, and the ability to extract structured insight from raw real-world data.

**Skills demonstrated:** Relational schema design, query engineering, business framing of analytical findings, GitHub documentation.
