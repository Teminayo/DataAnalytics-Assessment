#Use Database
USE adashi_staging ;
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




