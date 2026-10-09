-- One point per collector run: how the network looked at that moment.
select
    r.run_id,
    r.run_started_at_local,
    r.local_date,
    r.cameras_attempted,
    r.cameras_read,
    r.cameras_valid,
    avg(case when f.is_valid then f.vehicles_per_min end)                  as vehicles_per_min,
    avg(case when f.is_valid then cast(f.is_congested as integer) end)     as congestion_rate,
    sum(case when f.is_valid then f.moving_heavy else 0 end) * 1.0
        / nullif(sum(case when f.is_valid then f.moving_vehicles else 0 end), 0) as truck_share,
    max(cast(f.is_daylight as integer)) = 1                                as is_daylight
from {{ ref('fct_collection_runs') }} r
join {{ ref('fct_captures') }} f on f.run_id = r.run_id
group by 1, 2, 3, 4, 5, 6
