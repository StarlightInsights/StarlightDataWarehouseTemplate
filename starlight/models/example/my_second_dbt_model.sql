select id
from {{ ref('my_first_dbt_model') }}
whereid = 1
