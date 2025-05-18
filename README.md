# DataAnalytics-Assessment

## Overview
This repository contains SQL solutions for a Data Analyst assessment involving real-world business scenarios. The tasks required data retrieval, aggregation, and analysis using relational tables from a staging database.

---
![ERD](https://drive.google.com/uc?export=view&id=1DiI9kOr8Y3GuWnESI3G9eujDukgBxW5f)



## Table of Contents

- [Assessment_Q1.sql](./Assessment_Q1.sql) – High-Value Customers with Multiple Products  
- [Assessment_Q2.sql](./Assessment_Q2.sql) – Transaction Frequency Analysis  
- [Assessment_Q3.sql](./Assessment_Q3.sql) – Account Inactivity Alert  
- [Assessment_Q4.sql](./Assessment_Q4.sql) – Customer Lifetime Value (CLV) Estimation

---

## Per-Question Explanations

### 1. High-Value Customers with Multiple Products

**Objective:** Identify customers who have at least one funded savings plan and one investment plan, sorted by total deposits.

**Approach:**
- Used subqueries to separately count regular savings and investment plans per customer.
- Calculated total deposits from the `savings_savingsaccount` table, assuming `amount > 0` indicates a deposit.
- Joined all metrics using `LEFT JOIN` on the `users_customuser` table.
- Combined `first_name` and `last_name` to create a full customer name due to the absence of a single `name` field.

**Challenge:**
- Initially attempted to join directly using savings account owner ID and plan owner ID, but it returned empty results.
- Found it more reliable to derive customer identifiers using `owner_id` and aggregate accordingly.

---

### 2. Transaction Frequency Analysis

**Objective:** Classify customers based on their average monthly transaction frequency.

**Approach:**
- Extracted transaction month using `DATE_FORMAT`.
- Calculated monthly transaction counts per customer, then averaged them across all months.
- Categorized customers into `High`, `Medium`, and `Low Frequency` based on defined thresholds.
- Grouped and counted users per category with a rounded average.

**Challenge:**
- Data sparsity across months might affect averages.
- Excluded failed transactions by filtering `transaction_status = 'success'`.

---

### 3. Account Inactivity Alert

**Objective:** Identify active accounts with no inflow transactions for over a year.

**Approach:**
- Filtered only active, non-deleted, non-archived plans.
- Identified last inflow transaction date per `plan_id` using `transaction_type_id = 1` for inflows.
- Calculated inactivity in days by comparing with the current date.
- Included logic to capture plans with no inflow at all (NULL transaction dates).

**Challenge:**
- Some `plan_id` values did not match those in `savings_savingsaccount`, leading to missing results.
- Ensured LEFT JOIN was used to avoid excluding plans with no transactions.

---

### 4. Customer Lifetime Value (CLV) Estimation

**Objective:** Estimate CLV based on account tenure and transaction history.

**Approach:**
- Calculated tenure in months using `TIMESTAMPDIFF` between `date_joined` and current date.
- Computed total and average transaction values per user.
- Applied a simplified CLV formula using 0.1% profit per transaction value.
- Rounded results and ordered by CLV in descending order.

**Challenge:**
- Some users had zero tenure or no transactions; used `NULLIF` to avoid divide-by-zero errors.
- Attempted to map savings account to customer ID directly, but empty results led to combining via joins instead.

---

## General Challenges

- Some fields such as `name` existed as ‘null’ and had to be constructed from `first_name` and `last_name`.
- Mismatched IDs across tables occasionally led to empty outputs; corrected by checking foreign key references.
- Ensured NULL-safe operations when dealing with calculations to avoid runtime errors.

---

## Notes

- All SQL queries are written with readability and performance in mind.
- Complex operations such as subqueries and aggregations are commented for clarity.
- This assessment was a good exercise in joining business logic with SQL best practices.

---

## Author
Ibinayo Blessing Temilade

