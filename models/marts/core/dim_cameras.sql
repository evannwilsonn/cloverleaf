select
    c.camera_id, c.camera_name, c.caltrans_name, c.route, c.direction, c.corridor, c.county,
    c.latitude, c.longitude, c.weather_station, c.still_url,
    min(f.captured_at)                                      as first_capture_at,
    max(f.captured_at)                                      as last_capture_at,
    max(case when f.is_valid then f.captured_at end)        as last_valid_capture_at
from {{ ref('cameras') }} c
left join {{ ref('fct_captures') }} f on f.camera_id = c.camera_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
