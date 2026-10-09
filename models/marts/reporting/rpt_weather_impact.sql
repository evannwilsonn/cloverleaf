-- Daylight captures by weather at the nearest NWS station: does weather change traffic, and
-- does it change how often the cameras produce usable video?
select
    case when is_wet then 'Wet' when is_low_visibility then 'Fog / low visibility'
         when weather_conditions is null then 'No observation' else 'Dry, clear' end as weather,
    count(*)                                                        as daylight_captures,
    avg(cast(is_valid as integer))                                  as valid_rate,
    avg(case when is_valid then vehicles_per_min end)               as vehicles_per_min,
    avg(case when is_valid then cast(is_congested as integer) end)  as congestion_rate,
    avg(case when is_live_feed then sharpness end)                  as avg_sharpness
from {{ ref('fct_captures') }}
where is_daylight
group by 1
