/*
PROJECT: SQL-Based Audit Transaction Analysis
DATABASE: audit_practice
PURPOSE: Demonstrate audit-oriented transaction analysis using read-only queries.

SAFETY: This script contains SELECT statements only. It does not modify or delete data.

CORE TABLES / COLUMNS USED:
  transactions(transaction_id, department, amount, approval_status, vendor_id)
  vendors(vendor_id, vendor_name, category, risk_rating)

Before running the script, verify actual columns with the SHOW COLUMNS statements below.
*/

USE audit_practice;

-- 0. Verify the database and available table columns
SELECT DATABASE() AS active_database;
SHOW COLUMNS FROM transactions;
SHOW COLUMNS FROM vendors;

-- 1. Overall transaction profile
SELECT
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT vendor_id) AS distinct_vendors,
    SUM(amount) AS total_transaction_amount,
    AVG(amount) AS average_transaction_amount,
    MIN(amount) AS minimum_transaction_amount,
    MAX(amount) AS maximum_transaction_amount
FROM transactions;

-- 2. Basic data-quality check: missing key fields
SELECT
    SUM(CASE WHEN vendor_id IS NULL THEN 1 ELSE 0 END) AS missing_vendor_id_count,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS missing_amount_count,
    SUM(CASE WHEN approval_status IS NULL THEN 1 ELSE 0 END) AS missing_approval_status_count
FROM transactions;

-- 3. Approval-status summary
SELECT
    COALESCE(approval_status, 'Missing') AS approval_status_label,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY COALESCE(approval_status, 'Missing')
ORDER BY transaction_count DESC;

-- 4. Department-level transaction analysis
SELECT
    department,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_transaction_amount
FROM transactions
GROUP BY department
ORDER BY total_amount DESC;

-- 5. Departments whose total transaction amount exceeds ₹500,000
SELECT
    department,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY department
HAVING SUM(amount) > 500000
ORDER BY total_amount DESC;

-- 6. Departments with more than five transactions
SELECT
    department,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY department
HAVING COUNT(*) > 5
ORDER BY transaction_count DESC;

-- 7. Transaction value bands (amount-based classification, not vendor risk rating)
SELECT
    CASE
        WHEN amount IS NULL THEN 'Missing Amount'
        WHEN amount > 100000 THEN 'High Value'
        WHEN amount BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS transaction_value_band,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY
    CASE
        WHEN amount IS NULL THEN 'Missing Amount'
        WHEN amount > 100000 THEN 'High Value'
        WHEN amount BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY total_amount DESC;

-- 8. Transactions with pending or missing approval status
SELECT
    transaction_id,
    department,
    amount,
    COALESCE(approval_status, 'Missing') AS approval_status_label,
    vendor_id
FROM transactions
WHERE approval_status = 'Pending'
   OR approval_status IS NULL
ORDER BY amount DESC;

-- 9. Join transactions to vendor reference data
SELECT
    t.transaction_id,
    t.department,
    t.amount,
    COALESCE(t.approval_status, 'Missing') AS approval_status_label,
    v.vendor_name,
    v.category,
    v.risk_rating
FROM transactions AS t
LEFT JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
ORDER BY t.amount DESC;

-- 10. Transactions associated with high-risk vendors
SELECT
    t.transaction_id,
    t.department,
    t.amount,
    COALESCE(t.approval_status, 'Missing') AS approval_status_label,
    v.vendor_name,
    v.risk_rating
FROM transactions AS t
INNER JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
WHERE v.risk_rating = 'High'
ORDER BY t.amount DESC;

-- 11. High-risk vendor transactions above ₹100,000
SELECT
    t.transaction_id,
    t.department,
    t.amount,
    COALESCE(t.approval_status, 'Missing') AS approval_status_label,
    v.vendor_name
FROM transactions AS t
INNER JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
WHERE v.risk_rating = 'High'
  AND t.amount > 100000
ORDER BY t.amount DESC;

-- 12. Pending transactions associated with high-risk vendors
SELECT
    t.transaction_id,
    t.department,
    t.amount,
    t.approval_status,
    v.vendor_name,
    v.risk_rating
FROM transactions AS t
INNER JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
WHERE v.risk_rating = 'High'
  AND t.approval_status = 'Pending'
ORDER BY t.amount DESC;

-- 13. Vendor-level exposure and transaction count
SELECT
    v.vendor_id,
    v.vendor_name,
    v.category,
    v.risk_rating,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_transaction_amount
FROM vendors AS v
LEFT JOIN transactions AS t
    ON t.vendor_id = v.vendor_id
GROUP BY v.vendor_id, v.vendor_name, v.category, v.risk_rating
ORDER BY total_transaction_amount DESC;

-- 14. Risk-rating summary
SELECT
    v.risk_rating,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_transaction_amount
FROM transactions AS t
INNER JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
GROUP BY v.risk_rating
ORDER BY
    CASE v.risk_rating
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;

-- 15. Conditional aggregation: pending and high-risk metrics by department
SELECT
    t.department,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_amount,
    SUM(CASE WHEN t.approval_status = 'Pending' THEN 1 ELSE 0 END) AS pending_transaction_count,
    SUM(CASE WHEN t.approval_status = 'Pending' THEN t.amount ELSE 0 END) AS pending_amount,
    SUM(CASE WHEN v.risk_rating = 'High' THEN 1 ELSE 0 END) AS high_risk_transaction_count,
    SUM(CASE WHEN v.risk_rating = 'High' THEN t.amount ELSE 0 END) AS high_risk_amount
FROM transactions AS t
LEFT JOIN vendors AS v
    ON t.vendor_id = v.vendor_id
GROUP BY t.department
ORDER BY total_amount DESC;

-- 16. CTE: summarize high-risk pending transactions
WITH high_risk_pending AS (
    SELECT
        t.transaction_id,
        t.department,
        t.amount,
        t.approval_status,
        v.vendor_name
    FROM transactions AS t
    INNER JOIN vendors AS v
        ON t.vendor_id = v.vendor_id
    WHERE v.risk_rating = 'High'
      AND t.approval_status = 'Pending'
)
SELECT
    COUNT(*) AS high_risk_pending_transaction_count,
    SUM(amount) AS high_risk_pending_total_amount,
    GROUP_CONCAT(transaction_id ORDER BY transaction_id SEPARATOR ', ') AS transaction_ids
FROM high_risk_pending;

-- 17. Window function: rank transactions by amount within each department
SELECT
    transaction_id,
    department,
    amount,
    approval_status,
    ROW_NUMBER() OVER (
        PARTITION BY department
        ORDER BY amount DESC, transaction_id
    ) AS amount_rank_within_department
FROM transactions
ORDER BY department, amount_rank_within_department;

/*
AUDIT INTERPRETATION REMINDER
- A high-risk vendor rating is a risk indicator, not evidence of wrongdoing.
- A high-value transaction is not automatically an exception.
- A pending or missing approval status requires comparison with applicable policy
  and supporting evidence before concluding that a control failed.
- Similar vendor/amount/payment-method records are potential matches to investigate,
  not automatically duplicate payments.
*/
