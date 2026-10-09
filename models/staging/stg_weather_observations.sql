-- NWS observations, de-duplicated (each pull overlaps the last) and converted to plain units.
with src as (
    select
        {{ jfield('payload', 'station_id') }}                                as station_id,
        {{ utc_ts(jfield('payload', 'timestamp')) }}                         as observed_at,
        {{ jfield('payload', 'textDescription') }}                           as conditions,
        {{ jfield('payload', 'temperature.value', 'double') }}               as temperature_c,
        {{ jfield('payload', 'windSpeed.value', 'double') }}                 as wind_kmh,
        {{ jfield('payload', 'visibility.value', 'double') }} / 1000.0       as visibility_km,
        {{ jfield('payload', 'precipitationLastHour.value', 'double') }}     as precip_last_hour_mm,
        {{ jfield('payload', 'relativeHumidity.value', 'double') }}          as relative_humidity,
        {{ utc_ts(jfield('payload', 'fetched_at')) }}                        as fetched_at
    from {{ source('raw_cloverleaf', 'weather_observations') }}
),
ranked as (
    select *, row_number() over (partition by station_id, observed_at order by fetched_at desc) as rn
    from src
    where observed_at is not null
)
select
    station_id, observed_at, conditions, temperature_c, wind_kmh, visibility_km, precip_last_hour_mm,
    relative_humidity,
    coalesce({{ ilike_any('conditions', ['rain', 'drizzle', 'shower', 'thunder']) }}, false)
        or coalesce(precip_last_hour_mm, 0) > 0                         as is_wet,
    coalesce({{ ilike_any('conditions', ['fog', 'mist', 'haze', 'smoke']) }}, false)
        or coalesce(visibility_km < 3, false)                           as is_low_visibility
from ranked
where rn = 1
