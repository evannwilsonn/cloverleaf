-- One row per station per UTC hour: the conditions a capture in that hour saw.
select
    station_id,
    date_trunc('hour', observed_at)          as hour_utc,
    avg(temperature_c)                       as temperature_c,
    min(visibility_km)                       as min_visibility_km,
    max(cast(is_wet as integer)) = 1         as is_wet,
    max(cast(is_low_visibility as integer)) = 1 as is_low_visibility,
    max(conditions)                          as conditions
from {{ ref('stg_weather_observations') }}
group by 1, 2
