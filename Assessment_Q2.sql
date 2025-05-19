#Use Database
USE adashi_staging ;
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