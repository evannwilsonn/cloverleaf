select
    local_date,
    corridor,
    count(*)                                                        as captures,
    sum(case when is_valid then 1 else 0 end)                       as valid_captures,
    avg(case when is_valid then vehicles_per_min end)               as vehicles_per_min,
    sum(case when is_valid then moving_heavy else 0 end) * 1.0
        / nullif(sum(case when is_valid then moving_vehicles else 0 end), 0) as truck_share,
    avg(case when is_valid then cast(is_congested as integer) end)  as congestion_rate
from {{ ref('fct_captures') }}
group by 1, 2
