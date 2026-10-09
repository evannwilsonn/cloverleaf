-- Every capture: what the camera delivered, which rule (if any) excluded it, the traffic it
-- measured, and the weather at the nearest station that hour.
select
    k.run_id,
    k.camera_id,
    k.corridor,
    k.captured_at,
    k.captured_at_local,
    cast(k.captured_at_local as date)                    as local_date,
    {{ hour_of('k.captured_at_local') }}                 as local_hour,
    {{ weekday_of('k.captured_at_local') }}              as local_weekday,
    k.stream_status,
    k.is_live_feed,
    k.is_daylight,
    k.is_valid,
    k.exclusion_reason,
    k.sun_elevation,
    k.brightness,
    k.sharpness,
    k.motion,
    k.frames_analyzed,
    k.clip_seconds,
    m.moving_vehicles,
    m.moving_heavy,
    m.vehicles_in_view,
    m.vehicles_per_min,
    m.speed_index,
    m.speed_ratio,
    m.is_congested,
    w.conditions                                         as weather_conditions,
    w.is_wet,
    w.is_low_visibility,
    w.temperature_c,
    k.model,
    k.runner,
    k.code_version
from {{ ref('int_captures__checked') }} k
left join {{ ref('int_captures__measured') }} m on m.run_id = k.run_id and m.camera_id = k.camera_id
left join {{ ref('int_weather__hourly') }} w
    on w.station_id = k.weather_station and w.hour_utc = date_trunc('hour', k.captured_at)
