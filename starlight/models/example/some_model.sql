select number
from {{ ref('numbers') }}
where 1 = 1
