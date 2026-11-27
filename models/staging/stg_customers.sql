select
    customer_id,
    full_name,
    trim(city)           as city,
    lower(trim(tier)) as tier,
    signup_date
from {{ source('jara_source', 'customers') }}