-- Average traffic by local hour and day type, network-wide and per corridor ('All corridors').
with base as (
    select
        corridor,
        case when local_weekday < 5 then 'Weekday' else 'Weekend' end as day_type,
        local_hour,
        vehicles_per_min,
        cast(is_congested as integer) as congested,
        moving_heavy,
        moving_vehicles
    from {{ ref('fct_captures') }}
    where is_valid
)
select corridor, day_type, local_hour, count(*) as valid_captures, avg(vehicles_per_min) as vehicles_per_min,
       avg(congested) as congestion_rate, sum(moving_heavy) * 1.0 / nullif(sum(moving_vehicles), 0) as truck_share
from base group by 1, 2, 3
union all
select 'All corridors', day_type, local_hour, count(*), avg(vehicles_per_min), avg(congested),
       sum(moving_heavy) * 1.0 / nullif(sum(moving_vehicles), 0)
from base group by 2, 3
