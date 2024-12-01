select number
from {{ ref('numbers') }}
union all
select 1 as number
union all
select 1 as number
union all
select 2 as number
