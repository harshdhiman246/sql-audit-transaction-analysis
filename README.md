# SQL-Based Audit Transaction Analysis

## Project purpose
This portfolio project demonstrates how MySQL can support audit-focused transaction analysis: data-quality checks, department spending analysis, approval-status monitoring, vendor-risk analysis, potential duplicate-payment screening, and prioritisation of items for further testing.

## Files
- `SQL_Audit_Transaction_Analysis.sql` — commented, read-only MySQL queries.
- `SQL_Audit_Transaction_Analysis_Case_Study.docx` — professional case-study report.

## Database
The script is designed for the existing `audit_practice` database with these known tables:
- `transactions`: `transaction_id`, `department`, `amount`, `approval_status`, `vendor_id`
- `vendors`: `vendor_id`, `vendor_name`, `category`, `risk_rating`

The script begins with `SHOW COLUMNS` so the schema can be verified. Optional queries using `payment_method` or `transaction_date` are commented out and should only be enabled if those columns exist in the actual database.

## How to run
1. Open MySQL Workbench and connect to your local MySQL instance.
2. Open `SQL_Audit_Transaction_Analysis.sql`.
3. Run the initial database and column checks.
4. Execute the core queries in order, reviewing each result set.
5. If a column used by an optional query is absent, leave that optional query commented out.
6. Save selected result grids or screenshots for your portfolio evidence, ensuring they match the current database outputs.

The script uses `SELECT` statements only; it does not insert, update, or delete records.

## Important interpretation note
A high-risk vendor classification, high transaction value, pending status, or potential match is an indicator for further investigation. None alone proves fraud, financial loss, or a control failure. Conclusions require corroborating evidence and the applicable company policy.

## Known illustrative findings from prior practice
Previously established results from the user's `audit_practice` exercises include:
- Department transaction values: IT ₹1,090,000; Finance ₹358,000; Operations ₹331,000; Sales ₹278,500; HR ₹77,500.
- The threshold `HAVING SUM(amount) > 500000` returned IT only.
- Amount-based transaction bands using `> ₹100,000` as High, `₹50,000–₹100,000` as Medium, and lower values as Low returned counts of 6 High, 9 Medium, and 16 Low.
- High-risk vendor-linked transactions previously identified: 1003, 1008, 1012, 1015, 1019, 1025, 1029, and 1031.
- High-risk vendor transactions over ₹100,000: 1008, 1015, 1019, 1025, and 1029.
- Pending transactions linked to high-risk vendors: 1015 and 1025.
- Transaction 1031 was identified with a NULL approval status; checks previously showed 0 missing `vendor_id` values and 0 missing `amount` values.

Re-run the SQL before publishing outputs. If the database has changed since these exercises, update the case study to reflect the current results.
