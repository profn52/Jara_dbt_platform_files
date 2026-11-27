select
    rider_id,
    rider_name,
    lower(trim(vehicle_type)) as vehicle_type,
    lower(trim(fleet))  as fleet,
    base_city,
    joined_date
from {{ source('jara_source', 'riders') }}