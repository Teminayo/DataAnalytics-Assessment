#Use Database
USE adashi_staging ;

#To check tables
select * from users_customuser;
Select * from savings_savingsaccount;
Select * from plans_plan;
# To View Structure of a Table
DESCRIBE users_customuser ;
DESCRIBE savings_savingsaccount;

#To Check for Missing Values
SELECT 
  SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS missing_values
FROM users_customuser ;

SELECT 
  SUM(CASE WHEN owner_id IS NULL THEN 1 ELSE 0 END) AS missing_values
FROM savings_savingsaccount;




#1. High-Value Customers with Multiple Products
SELECT
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    COALESCE(s.savings_count, 0) AS savings_count,
    COALESCE(i.investment_count, 0) AS investment_count,
    COALESCE(sa.total_deposits, 0) AS total_deposits
FROM users_customuser u
LEFT JOIN (
    SELECT
        owner_id,
        COUNT(*) AS savings_count
    FROM plans_plan
    WHERE is_regular_savings = 1
    GROUP BY owner_id
) s ON u.id = s.owner_id
LEFT JOIN (
    SELECT
        owner_id,
        COUNT(*) AS investment_count
    FROM plans_plan
    WHERE is_fixed_investment = 1 OR is_managed_portfolio = 1
    GROUP BY owner_id
) i ON u.id = i.owner_id
LEFT JOIN (
    SELECT
        owner_id,
        SUM(amount) AS total_deposits
    FROM savings_savingsaccount
    WHERE amount > 0
    GROUP BY owner_id
) sa ON u.id = sa.owner_id
WHERE s.savings_count > 0 AND i.investment_count > 0
ORDER BY total_deposits DESC;



#2. Transaction Frequency Analysis
-- To Get monthly transaction count per user
WITH user_transactions AS (
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS txn_month,
        COUNT(*) AS monthly_txn_count
    FROM savings_savingsaccount s
    WHERE s.transaction_status = 'success'  
    GROUP BY s.owner_id, DATE_FORMAT(s.transaction_date, '%Y-%m')
),

-- calculating average monthly transactions per user
monthly_avg AS (
    SELECT 
        owner_id,
        AVG(monthly_txn_count) AS avg_txn_per_month
    FROM user_transactions
    GROUP BY owner_id
),

-- Categorize users
categorized_users AS (
    SELECT 
        CASE 
            WHEN avg_txn_per_month >= 10 THEN 'High Frequency'
            WHEN avg_txn_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        avg_txn_per_month
    FROM monthly_avg
)

--  Summarize by category
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month
FROM categorized_users
GROUP BY frequency_category
ORDER BY 
    FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');


#3
-- Account Inactivity Alert
WITH latest_inflow AS (
    SELECT
        s.plan_id,
        MAX(s.transaction_date) AS last_transaction_date
    FROM savings_savingsaccount s
    WHERE s.transaction_type_id = 1 
    GROUP BY s.plan_id
),
active_plans AS (
    SELECT
        p.id AS plan_id,
        p.owner_id,
        CASE 
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE 'Savings'
        END AS type
    FROM plans_plan p
    WHERE p.is_deleted = 0 AND p.is_archived = 0
)

SELECT
    ap.plan_id,
    ap.owner_id,
    ap.type,
    li.last_transaction_date,
    DATEDIFF(CURDATE(), li.last_transaction_date) AS inactivity_days
FROM active_plans ap
LEFT JOIN latest_inflow li ON ap.plan_id = li.plan_id
WHERE li.last_transaction_date IS NULL
   OR li.last_transaction_date < CURDATE() - INTERVAL 365 DAY
ORDER BY inactivity_days DESC;


#4 Customer Lifetime Value (CLV) Estimation

-- To Summarize transactions per user
WITH transaction_summary AS (
    SELECT
        s.owner_id AS customer_id,
        COUNT(*) AS total_transactions,
        SUM(s.amount) AS total_transaction_value,
        AVG(s.amount) AS avg_transaction_value
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
),

-- To Compute tenure in months since signup
tenure_data AS (
    SELECT
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months
    FROM users_customuser u
    WHERE u.is_account_deleted = 0 AND u.is_account_disabled = 0
)

-- To Combine for CLV calculation
SELECT
    td.customer_id,
    td.name,
    td.tenure_months,
    ts.total_transactions,
    ROUND((
        (ts.total_transactions / NULLIF(td.tenure_months, 0)) 
        * 12 
        * (0.1 * ts.avg_transaction_value)
    ), 2) AS estimated_clv
FROM tenure_data td
JOIN transaction_summary ts ON td.customer_id = ts.customer_id
ORDER BY estimated_clv DESC;









