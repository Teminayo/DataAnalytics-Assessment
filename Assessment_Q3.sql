#Use Database
USE adashi_staging ;
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