
-- Fact Delivery Model
-- October and November 2025 Partner Fleet Payments
-- Excludes ghost drivers and duplicate deliveries

WITH deliveries AS (

    SELECT *
    FROM {{ ref('stg_deliveries') }}

),

riders AS (

    SELECT *
    FROM {{ source('jara_source', 'riders') }}

),

-- 1. Remove duplicate delivery IDs
deduplicated_deliveries AS (

    SELECT
        d.*,
        ROW_NUMBER() OVER (
            PARTITION BY d.delivery_id
            ORDER BY d.created_at ASC
        ) AS rn

    FROM deliveries d

    WHERE d.delivery_id IS NOT NULL

),

-- 2. Select valid deliveries
valid_deliveries AS (

    SELECT
        dd.*

    FROM deduplicated_deliveries dd

    WHERE dd.rn = 1
      AND dd.customer_id IS NOT NULL
      AND dd.rider_id IS NOT NULL
      AND LOWER(TRIM(dd.status)) = 'delivered'
      AND LOWER(TRIM(dd.fleet)) = 'partner'

      -- Exclude ghost drivers
      AND EXISTS (

          SELECT 1
          FROM riders r
          WHERE r.rider_id = dd.rider_id

      )

      -- October and November 2025
      AND dd.created_at >= '2025-10-01'
      AND dd.created_at < '2025-12-01'

),

-- 3. Calculate monthly delivery payments
monthly_delivery_summary AS (

    SELECT

        CASE
            WHEN created_at < '2025-11-01'
                THEN 'October'
            ELSE 'November'
        END AS delivery_month,

        COUNT(*) AS total_deliveries,

        SUM(distance) AS total_distance_covered,

        SUM(distance) * 220 AS total_payment_ngn

    FROM valid_deliveries

    GROUP BY 1

)

-- 4. Final Fact Table
SELECT
    delivery_month,
    total_deliveries,
    total_distance_covered,
    total_payment_ngn

FROM monthly_delivery_summary
