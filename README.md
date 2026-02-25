# Crew Promo Exercise 2026

This repository contains comprehensive SQL solutions for the Crew promotion exercise, covering 6 distinct business domains.

## Problem List

| # | Problem | Domain | Key Concepts |
|---|---------|--------|--------------|
| 1 | [Retail](./Problem-1-Retail) | Orders & Revenue | Window functions, PIVOT, aggregations |
| 2 | [Healthcare](./Problem-2-Healthcare) | Appointments & Patient Gaps | Date math, gap analysis, patient journeys |
| 3 | [AdTech](./Problem-3-AdTech) | Event JSON, Campaign Analytics | JSON parsing, lateral joins, event tracking |
| 4 | [Finance](./Problem-4-Finance) | Ledger, ACID, Upserts | Transactions, MERGE/UPSERT, normalization |
| 5 | [HR/Temporal](./Problem-5-HR-Temporal) | Org Charts, Security | Temporal tables, effective dating, row-level security |
| 6 | [Normalization](./Problem-6-Normalization) | Data Modeling | 1NF, 2NF, 3NF, schema design |

## Setup

Each problem folder contains:
- `README.md` - Problem description and requirements
- `data-model/` - Table creation scripts and sample data
- `queries/` - SQL solutions with comments

## SQL Dialect
All solutions are written in **SQL Server/T-SQL** (SSMS 17 compatible).

## Misc
Using [dbfiddle.uk](https://dbfiddle.uk/) SQL Server 2017 to test/run all queries.
