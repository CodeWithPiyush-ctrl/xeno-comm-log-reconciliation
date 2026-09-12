-- ============================================================
-- 1. Naive count
-- ============================================================

SELECT COUNT(*) AS naive_count
FROM communication_log
WHERE merchant_id = 501
  AND communication_type = '2'
  AND sent_time >= '2026-10-01'
  AND sent_time < '2026-11-01';


-- ============================================================
-- 2. Inspect campaign structure and statuses
-- ============================================================

SELECT
    id,
    parent_id,
    name,
    creation_status,
    processing_status
FROM campaign
WHERE merchant_id = 501
ORDER BY id;


-- ============================================================
-- 3. Compare attempts vs unique customers by campaign
-- ============================================================

SELECT
    communication_id,
    COUNT(*) AS attempts,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM communication_log
WHERE merchant_id = 501
  AND communication_type = '2'
  AND sent_time >= '2026-10-01'
  AND sent_time < '2026-11-01'
GROUP BY communication_id
ORDER BY communication_id;


-- ============================================================
-- 4. Inspect first retry family
-- ============================================================

SELECT
    communication_id,
    customer_id,
    delivery_status,
    sent_time
FROM communication_log
WHERE communication_id IN (9001, 9002, 9003)
ORDER BY customer_id, sent_time;


-- ============================================================
-- 5. Inspect second retry family
-- ============================================================

SELECT
    communication_id,
    customer_id,
    delivery_status,
    sent_time
FROM communication_log
WHERE communication_id IN (9201, 9202)
ORDER BY customer_id, sent_time;


-- ============================================================
-- 6. Inspect standalone campaign
-- ============================================================

SELECT
    communication_id,
    customer_id,
    delivery_status,
    sent_time
FROM communication_log
WHERE communication_id = 9101
ORDER BY customer_id, sent_time;