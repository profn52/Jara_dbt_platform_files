
-- Delivery Data Quality and Investigation Model

WITH deliveries AS (

    SELECT *
    FROM {{ source('jara_source', 'deliveries') }}

),

riders AS (

    SELECT *
    FROM {{ source('jara_source', 'riders') }}

),

-- 1. Identify Duplicate Deliveries
duplicate_deliveries AS (

    SELECT
        d.*,
        'Duplicate delivery record' AS investigation_reason
    FROM deliveries d
    WHERE d.delivery_id IN (

        SELECT delivery_id
        FROM deliveries
        GROUP BY delivery_id
        HAVING COUNT(*) > 1

    )

),

-- 2. Identify Ghost Drivers
non_existent_riders AS (

    SELECT
        d.*,
        'Non-existent rider_id' AS investigation_reason
    FROM deliveries d
    LEFT JOIN riders r
        ON d.rider_id = r.rider_id
    WHERE r.rider_id IS NULL
      AND d.rider_id IS NOT NULL

),

-- 3. Identify Abnormal Delivery Distances
abnormal_distance AS (

    SELECT
        d.*,
        'Distance greater than 41 km in partner fleet during November'
            AS investigation_reason
    FROM deliveries d
    WHERE d.fleet = 'partner'
      AND d.status = 'delivered'
      AND d.distance > 41
      AND EXTRACT(MONTH FROM d.created_at) = 11

),

-- 4. Combine All Investigation Records
investigation_records AS (

    SELECT * FROM duplicate_deliveries

    UNION ALL

    SELECT * FROM non_existent_riders

    UNION ALL

    SELECT * FROM abnormal_distance

)

-- 5. Generate Final Investigation Output
SELECT
    ROW_NUMBER() OVER (
        ORDER BY delivery_id, investigation_reason
    ) AS investigation_id,

    delivery_id,
    customer_id,
    rider_id,
    distance,
    delivery_fee,
    fleet,
    status,
    created_at,
    investigation_reason

FROM investigation_records
