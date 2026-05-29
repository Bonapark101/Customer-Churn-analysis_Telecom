---Import data
CREATE TABLE telecom_churn (
    customer_id     TEXT,
    age             INTEGER,
    region          TEXT,
    contract_type   TEXT,
    plan            TEXT,
    monthly_charge_eur REAL,
    tenure_months   INTEGER,
    avg_calls_per_month INTEGER,
    avg_data_gb     REAL,
    support_calls   INTEGER,
    late_payments   INTEGER,
    churned         INTEGER
);

--

--- Create customers table
CREATE TABLE customers AS
SELECT 
    customer_id,
    age,
    region
FROM telecom_churn;

-- Create contracts table
CREATE TABLE contracts AS
SELECT 
    customer_id,
    contract_type,
    plan,
    monthly_charge_eur,
    tenure_months
FROM telecom_churn;

-- Create behavior table
CREATE TABLE behavior AS
SELECT 
    customer_id,
    avg_calls_per_month,
    avg_data_gb,
    support_calls,
    late_payments,
    churned
FROM telecom_churn;

--

---Layer_1
--overall churn rate
SELECT 
    COUNT(*) as total_customers,
    SUM(b.churned) as total_churned,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id;

--churn by contract type
SELECT 
    ct.contract_type,
    COUNT(*) as total_customers,
    SUM(b.churned) as churned_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.contract_type
ORDER BY churn_rate DESC;

--churn by plan
SELECT 
    ct.plan,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.plan
ORDER BY churn_rate DESC;

--churn by tenure group
SELECT 
    CASE 
        WHEN ct.tenure_months <= 24 THEN '1 - 0-24 months'
        WHEN ct.tenure_months <= 48 THEN '2 - 25-48 months'
        ELSE '3 - 49+ months'
    END as tenure_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY tenure_group
ORDER BY tenure_group;

--support calls vs churn
SELECT 
    CASE 
        WHEN b.support_calls <= 2 THEN '1 - Low (0-2)'
        WHEN b.support_calls <= 5 THEN '2 - Medium (3-5)'
        ELSE '3 - High (6+)'
    END as support_call_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY support_call_group
ORDER BY support_call_group;

---late payments vs churn
SELECT 
    CASE 
        WHEN b.late_payments = 0 THEN '1 - Never late'
        WHEN b.late_payments = 1 THEN '2 - Once'
        ELSE '3 - 2+ times'
    END as late_payment_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY late_payment_group
ORDER BY late_payment_group;

-- 

---Layer_2 (Monthly contracts only)
--churn by region
SELECT 
    c.region,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate,
    ROUND(AVG(b.support_calls)::numeric, 1) as avg_support_calls,
    ROUND(AVG(b.late_payments)::numeric, 1) as avg_late_payments,
    ROUND(AVG(ct.monthly_charge_eur)::numeric, 2) as avg_charge
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE ct.contract_type = 'Monthly'
GROUP BY c.region
ORDER BY churn_rate DESC;

--Utrecht vs other regions
SELECT 
    CASE 
        WHEN c.region = 'Utrecht' THEN 'Utrecht'
        ELSE 'Other regions'
    END as region_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate,
    ROUND(AVG(b.support_calls)::numeric, 1) as avg_support_calls,
    ROUND(AVG(b.late_payments)::numeric, 1) as avg_late_payments
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE ct.contract_type = 'Monthly'
GROUP BY region_group
ORDER BY churn_rate DESC;

--Utrecht churn by tenure group
SELECT 
    CASE 
        WHEN ct.tenure_months <= 24 THEN '1 - 0-24 months'
        WHEN ct.tenure_months <= 48 THEN '2 - 25-48 months'
        ELSE '3 - 49+ months'
    END as tenure_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE c.region = 'Utrecht'
AND ct.contract_type = 'Monthly'
GROUP BY tenure_group
ORDER BY tenure_group;

--Utrecht churn by plan
SELECT 
    ct.plan,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate,
    ROUND(AVG(b.support_calls)::numeric, 1) as avg_support_calls,
    ROUND(AVG(b.late_payments)::numeric, 1) as avg_late_payments
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE c.region = 'Utrecht'
AND ct.contract_type = 'Monthly'
GROUP BY ct.plan
ORDER BY churn_rate DESC;

--

---Layer 3_Contract type
--full contract type comparison
SELECT 
    ct.contract_type,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate,
    ROUND(AVG(b.support_calls)::numeric, 1) as avg_support_calls,
    ROUND(AVG(b.late_payments)::numeric, 1) as avg_late_payments,
    ROUND(AVG(ct.monthly_charge_eur)::numeric, 2) as avg_charge,
    ROUND(AVG(ct.tenure_months)::numeric, 1) as avg_tenure
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.contract_type
ORDER BY churn_rate DESC;

--late payment vs churn by contract type
SELECT 
    ct.contract_type,
    CASE 
        WHEN b.late_payments = 0 THEN '1 - Never late'
        WHEN b.late_payments = 1 THEN '2 - Once'
        ELSE '3 - 2+ times'
    END as late_payment_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.contract_type, late_payment_group
ORDER BY ct.contract_type, late_payment_group;

--support calls vs churn by contract type
SELECT 
    ct.contract_type,
    CASE 
        WHEN b.support_calls <= 2 THEN '1 - Low (0-2)'
        WHEN b.support_calls <= 5 THEN '2 - Medium (3-5)'
        ELSE '3 - High (6+)'
    END as support_call_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.contract_type, support_call_group
ORDER BY ct.contract_type, support_call_group;

--tenure vs churn by contract type
SELECT 
    ct.contract_type,
    CASE 
        WHEN ct.tenure_months <= 24 THEN '1 - 0-24 months'
        WHEN ct.tenure_months <= 48 THEN '2 - 25-48 months'
        ELSE '3 - 49+ months'
    END as tenure_group,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
GROUP BY ct.contract_type, tenure_group
ORDER BY ct.contract_type, tenure_group;

--

---Final_High risk customers
--high risk customer profile
SELECT 
    ct.contract_type,
    c.region,
    COUNT(*) as total_customers,
    ROUND(AVG(b.churned)::numeric * 100, 1) as churn_rate,
    ROUND(AVG(b.support_calls)::numeric, 1) as avg_support_calls,
    ROUND(AVG(b.late_payments)::numeric, 1) as avg_late_payments
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE b.support_calls >= 4
AND b.late_payments >= 2
AND ct.tenure_months <= 24
GROUP BY ct.contract_type, c.region
ORDER BY churn_rate DESC;

--at risk customers not yet churned
SELECT 
    c.customer_id,
    c.region,
    ct.contract_type,
    ct.plan,
    ct.tenure_months,
    b.support_calls,
    b.late_payments,
    ct.monthly_charge_eur
FROM customers c
JOIN contracts ct ON c.customer_id = ct.customer_id
JOIN behavior b ON c.customer_id = b.customer_id
WHERE b.churned = 0
AND ct.contract_type = 'Monthly'
AND b.support_calls >= 4
AND b.late_payments >= 2
AND ct.tenure_months <= 24
ORDER BY b.support_calls DESC, b.late_payments DESC;
