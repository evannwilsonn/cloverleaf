-- Health and recent traffic per camera, for the camera grid.
with latest as (
    select max(captured_at) as as_of from {{ ref('fct_captures') }}
),
recent as (
    select f.*, l.as_of
    from {{ ref('fct_captures') }} f cross join latest l
    where f.captured_at > l.as_of - interval '24 hours'
),
last_capture as (
    select camera_id, stream_status, exclusion_reason, vehicles_per_min, captured_at_local,
           row_number() over (partition by camera_id order by captured_at desc) as rn
    from {{ ref('fct_captures') }}
),
reasons as (
    select camera_id, exclusion_reason, count(*) as n,
           row_number() over (partition by camera_id order by count(*) desc, exclusion_reason) as rn
    from recent where exclusion_reason is not null and exclusion_reason <> 'low_light'
    group by 1, 2
)
select
    d.camera_id, d.camera_name, d.corridor, d.route, d.direction, d.county, d.latitude, d.longitude, d.still_url,
    count(r.run_id)                                                         as captures_24h,
    avg(cast(r.is_live_feed as integer))                                    as availability_24h,
    avg(case when r.is_daylight then cast(r.is_valid as integer) end)       as daylight_valid_rate_24h,
    avg(case when r.is_valid then r.vehicles_per_min end)                   as vehicles_per_min_24h,
    avg(case when r.is_valid then cast(r.is_congested as integer) end)      as congestion_rate_24h,
    max(lc.stream_status)                                                   as last_stream_status,
    max(lc.exclusion_reason)                                                as last_exclusion_reason,
    max(lc.captured_at_local)                                               as last_capture_local,
    max(rs.exclusion_reason)                                                as main_issue_24h,
    d.last_valid_capture_at
from {{ ref('dim_cameras') }} d
left join recent r on r.camera_id = d.camera_id
left join last_capture lc on lc.camera_id = d.camera_id and lc.rn = 1
left join reasons rs on rs.camera_id = d.camera_id and rs.rn = 1
group by d.camera_id, d.camera_name, d.corridor, d.route, d.direction, d.county, d.latitude, d.longitude, d.still_url,
         d.last_valid_capture_at
