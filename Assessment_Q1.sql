#Use Database
USE adashi_staging ;
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
