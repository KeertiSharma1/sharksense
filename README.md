# SharkSense 🦈

### A SQL Intelligence System Built on 478 Shark Tank India Pitches

A business analytics project that transforms Shark Tank India investment negotiations into a structured relational database and extracts insights about valuation behaviour, investor preferences, funding blind spots, negotiation outcomes, and deal dynamics.

Built using MySQL 8.0, relational schema design, window functions, and advanced analytical SQL.

---

## Project Overview

Most analyses of Shark Tank India focus on entertainment.

This project treats the dataset as an investment intelligence problem.

Using 478 startup pitches from Seasons 1–3, the raw dataset was redesigned into a normalized relational database and used to answer questions that founders, investors, and analysts actually care about:

- Which sectors are consistently overvalued by founders?
- How do different sharks invest in practice versus reputation?
- Which sectors generate revenue but still struggle to raise funding?
- What conditions lead to royalty deals?
- Do multiple-shark deals actually benefit founders?

The objective was not to analyse a television show, but to study investment decision-making using a real-world negotiation dataset.

---

# Dashboard of Insights

## Insight 1 — Valuation Correction Index

Measures how aggressively sharks correct founder valuations across sectors.

![Valuation Correction](screenshots/insight1_valuation_correction.png)

---

## Insight 2 — Shark DNA Matrix

Profiles each shark using investment frequency, capital deployment, equity demands, deal style, and sector preferences.

![Shark DNA Matrix](screenshots/insight2_shark_dna.png)

---

## Insight 3 — Unfunded Sector Map

Identifies sectors that generate strong revenue but still experience poor funding outcomes.

![Unfunded Sector Map](screenshots/insight3_unfunded_sectors.png)

---

## Insight 4 — Negotiation Pattern Decoder

Examines the conditions associated with royalty deals, equity deals, founder rejections, and no-offer outcomes.

### Outcome Analysis

![Negotiation Pattern A](screenshots/insight4a.png)

### Shark Behaviour Analysis

![Negotiation Pattern B](screenshots/insight4b.png)

### Sector Behaviour Analysis

![Negotiation Pattern C](screenshots/insight4c.png)

---

## Insight 5 — Multiple Shark Illusion

Tests whether attracting multiple sharks actually improves founder outcomes.

### Overall Analysis

![Multiple Shark Overall](screenshots/insight5a_overall.png)

### Sector-Level Analysis

![Multiple Shark Sector](screenshots/insight5b_sector.png)

---

# Database Design

The original dataset contained approximately 80 columns in a single flat structure.

To support analytical querying, the data was normalized into a relational schema consisting of:

| Table | Purpose |
|---------|---------|
| sectors | Industry classification |
| pitches | Startup pitch information |
| founders | Founder demographics |
| deals | Investment outcomes |
| sharks | Individual shark participation records |

### Design Decisions

- Generated columns used where values can be derived automatically.
- Monetary values standardized to Lakhs INR.
- Revenue loss and pre-revenue startups preserved as meaningful business signals.
- Shark participation stored in long format to simplify aggregation and investor-level analysis.

---

# Analytical Systems

## 1. Valuation Correction Index

**Question**

How much do sharks reduce founder valuations, and does the magnitude vary across sectors?

**Techniques Used**

- CTEs
- Window Functions
- Ranking
- Conditional Classification

---

## 2. Shark DNA Matrix

**Question**

What are the true investment patterns of each shark?

**Techniques Used**

- Multi-table Joins
- Conditional Aggregation
- ROW_NUMBER()
- Sector Preference Extraction

---

## 3. Unfunded Sector Map

**Question**

Which sectors demonstrate strong business performance but weak funding outcomes?

**Techniques Used**

- Median Revenue Analysis
- CTE Layering
- Statistical Filtering
- Funding Rate Analysis

---

## 4. Negotiation Pattern Decoder

**Question**

What differentiates royalty deals, equity deals, founder rejections, and no-offer outcomes?

**Techniques Used**

- Outcome Classification
- Multi-stage Aggregation
- Conditional Logic
- Behavioural Segmentation

---

## 5. Multiple Shark Illusion

**Question**

Do multiple-shark deals improve founder outcomes?

**Techniques Used**

- Deal-Type Classification
- Aggregation Analysis
- Sector-Level Comparison
- Valuation Markdown Measurement

---

# Technical Skills Demonstrated

### SQL

- Relational Database Design
- Data Normalization
- Complex Joins
- Common Table Expressions (CTEs)
- Window Functions
- Conditional Aggregation
- Analytical Query Design

### Data Engineering

- Schema Design
- Data Cleaning
- Data Transformation
- ETL Preparation

### Analytics

- Behavioural Analysis
- Investor Profiling
- Funding Pattern Analysis
- Business Intelligence Development

### Tools

- MySQL 8.0
- SQL
- Python (Pandas)
- Git
- GitHub

---

# Dataset

**Source:** Shark Tank India Dataset (Kaggle)

- Seasons 1–3
- 478 Startup Pitches
- Investment Outcomes
- Founder Information
- Sector Information
- Shark Participation Records

Dataset used for educational and portfolio purposes.

---

# Running the Project

### Prerequisites

- MySQL 8.0+

### Create Database

```sql
source sql/schema/create_tables.sql
```

### Load Data

```sql
source sql/data_load/load_data.sql
```

### Run Insight Queries

```sql
source sql/insights/valuation_correction_index.sql
```

The remaining insight queries can be executed from the same folder.

---

# What This Project Demonstrates

This project demonstrates the ability to:

- Design normalized relational databases from messy real-world data
- Build analytical systems rather than isolated SQL queries
- Translate business questions into reproducible data workflows
- Extract actionable insights using advanced SQL techniques
- Communicate technical findings through structured documentation

---

## Author

**Keerti Sharma**

MCA Graduate | Aspiring Data Analyst

Focused on SQL, Analytics, Business Intelligence, and Data Storytelling.
