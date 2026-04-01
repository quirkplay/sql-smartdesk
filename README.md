# SQL Business Analysis — Smart Desk

Business analysis of Smart Desk, an ergonomic office furniture company,
using SQL on Snowflake. The analysis covers sales performance, regional
benchmarking, industry profitability, and strategic account segmentation.

Developed as part of the Master's in Data Science at
Universidad Complutense de Madrid.

## Structure

### Exercises
- **Exercise 1** — Sales and profit breakdown by product category for a specific account
- **Exercise 2** — Regional performance comparison across APAC and EMEA countries
- **Exercise 3** — Industry profitability for high-value pipeline accounts (CASE WHEN + subquery)
- **Exercise 4** — Forecast vs actual benefit comparison by category (FULL OUTER JOIN + CTE)

### Business Case — Account Value & Risk Distribution
Analysis of 100 accounts over 2019–2021 ($80M total profit) to identify
concentration risk and strategic segmentation opportunities.

- Exploratory queries: portfolio overview, account distribution by category count
- Top 10 account concentration analysis (window functions)
- Profit by account executive
- Strategic value segmentation: High Value / Medium Value / Low Value

## Key SQL Concepts Used
CTEs · Window Functions · FULL OUTER JOIN · Subqueries ·
CASE WHEN · GROUP BY · HAVING · Snowflake syntax

## Files
- `smart_desk_analysis.sql` — all queries
- `smart_desk_report.pdf` — full analysis with results and business recommendations

## Platform
Snowflake
