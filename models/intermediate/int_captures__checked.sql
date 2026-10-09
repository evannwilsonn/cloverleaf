-- Apply the capture rules (seeds/qc_rules.csv). A capture keeps every measurement; it gets
-- is_valid and the first rule it failed, in priority order. Only valid captures feed traffic KPIs.
with c as (
    select
        s.*,
        cam.corridor,
        cam.weather_station,
        {{ to_pacific('s.captured_at') }} as captured_at_local,
        s.clip_target_seconds * s.sample_fps as expected_frames,
        median(case when s.stream_status = 'ok' and s.sun_elevation >= {{ var('min_sun_elevation') }} then s.sharpness end)
            over (partition by s.camera_id) as camera_median_sharpness
    from {{ ref('stg_captures') }} s
    left join {{ ref('cameras') }} cam on cam.camera_id = s.camera_id
),
checks as (
    select
        *,
        stream_status = 'offline'                                                      as fails_feed_offline,
        stream_status = 'error'                                                        as fails_decode_failed,
        stream_status = 'ok' and frames_analyzed < {{ var('min_frame_share') }} * expected_frames as fails_short_clip,
        stream_status = 'ok' and (brightness < {{ var('min_brightness') }} or contrast < {{ var('min_contrast') }}) as fails_no_signal,
        stream_status = 'ok' and motion < {{ var('frozen_motion') }}                   as fails_frozen_feed,
        sun_elevation < {{ var('min_sun_elevation') }}                                 as fails_low_light,
        stream_status = 'ok' and camera_median_sharpness > 0
            and sharpness < {{ var('min_relative_sharpness') }} * camera_median_sharpness as fails_obstructed
    from c
)
select
    *,
    case
        when fails_feed_offline then 'feed_offline'
        when fails_decode_failed then 'decode_failed'
        when fails_short_clip then 'short_clip'
        when fails_no_signal then 'no_signal'
        when fails_frozen_feed then 'frozen_feed'
        when fails_low_light then 'low_light'
        when fails_obstructed then 'obstructed'
    end as exclusion_reason,
    not (fails_feed_offline or fails_decode_failed or coalesce(fails_short_clip, false) or coalesce(fails_no_signal, false)
         or coalesce(fails_frozen_feed, false) or fails_low_light or coalesce(fails_obstructed, false)) as is_valid,
    stream_status = 'ok' and not (coalesce(fails_short_clip, false) or coalesce(fails_no_signal, false)
         or coalesce(fails_frozen_feed, false)) as is_live_feed,
    sun_elevation >= {{ var('min_sun_elevation') }} as is_daylight
from checks
