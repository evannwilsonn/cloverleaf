-- Traffic measures for valid captures, normalised per camera.
-- speed_index is in frame units, so it is only comparable within one camera: each camera's
-- free-flow speed is the 85th percentile of its own valid captures, and speed_ratio compares to that.
with v as (
    select
        *,
        moving_cars + moving_trucks + moving_buses + moving_motorcycles                as moving_vehicles,
        in_view_cars + in_view_trucks + in_view_buses + in_view_motorcycles            as vehicles_in_view
    from {{ ref('int_captures__checked') }}
    where is_valid
),
baselines as (
    select
        *,
        {{ pctl("speed_index", 0.85) }} over (partition by camera_id) as free_flow_speed_index,
        median(vehicles_in_view) over (partition by camera_id)                                   as camera_median_in_view
    from v
)
select
    run_id,
    camera_id,
    moving_vehicles,
    moving_trucks + moving_buses                                          as moving_heavy,
    vehicles_in_view,
    moving_vehicles * 60.0 / nullif(clip_seconds, 0)                      as vehicles_per_min,
    speed_index,
    free_flow_speed_index,
    speed_index / nullif(free_flow_speed_index, 0)                        as speed_ratio,
    camera_median_in_view,
    coalesce(speed_index / nullif(free_flow_speed_index, 0) < {{ var('congested_speed_ratio') }}
             and vehicles_in_view >= camera_median_in_view, false)        as is_congested
from baselines
