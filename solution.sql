WITH RECURSIVE campaign_roots(campaign_id, root_id) AS (

    -- Original campaigns are their own roots
    SELECT
        id,
        id
    FROM campaign
    WHERE merchant_id = 501
      AND parent_id IS NULL

    UNION ALL

    -- Follow retry relationships
    SELECT
        c.id,
        cr.root_id
    FROM campaign c
    JOIN campaign_roots cr
        ON c.parent_id = cr.campaign_id
    WHERE c.merchant_id = 501
),

eligible_campaigns AS (

    SELECT id
    FROM campaign
    WHERE merchant_id = 501
      AND creation_status IN
          ('approved', 'aborted', 'resumed', 'stopped')
      AND processing_status = 'processed'
),

rooted_logs AS (

    SELECT
        cl.id,
        cl.customer_id,
        cl.communication_id,
        cr.root_id

    FROM communication_log cl

    JOIN campaign_roots cr
        ON cl.communication_id = cr.campaign_id

    JOIN eligible_campaigns ec
        ON cl.communication_id = ec.id

    WHERE cl.merchant_id = 501
      AND cl.communication_type = '2'
      AND cl.sent_time >= '2026-10-01'
      AND cl.sent_time < '2026-11-01'
),

family_type AS (

    SELECT
        root_id,
        MAX(
            CASE
                WHEN campaign_id <> root_id
                THEN 1
                ELSE 0
            END
        ) AS has_retry

    FROM campaign_roots
    GROUP BY root_id
),

summary AS (

    SELECT
        rl.root_id,
        ft.has_retry,
        COUNT(*) AS attempts,
        COUNT(DISTINCT rl.customer_id) AS unique_customers

    FROM rooted_logs rl

    JOIN family_type ft
        ON rl.root_id = ft.root_id

    GROUP BY
        rl.root_id,
        ft.has_retry
)

SELECT
    SUM(
        CASE
            WHEN has_retry = 1
                THEN unique_customers
            ELSE attempts
        END
    ) AS target_base
FROM summary;