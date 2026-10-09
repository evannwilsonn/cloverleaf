-- One row per camera per collector run, typed. Nothing is filtered here: offline feeds and
-- failed clips stay in so availability can be measured.
with src as (
    select payload, _source_file, _loaded_at from {{ source('raw_cloverleaf', 'captures') }}
)
select
    {{ jfield('payload', 'run_id') }}                               as run_id,
    {{ jfield('payload', 'camera_id') }}                            as camera_id,
    {{ utc_ts(jfield('payload', 'run_started_at')) }}               as run_started_at,
    {{ utc_ts(jfield('payload', 'captured_at')) }}                  as captured_at,
    {{ jfield('payload', 'status') }}                               as stream_status,
    {{ jfield('payload', 'error') }}                                as stream_error,
    {{ jfield('payload', 'runner') }}                               as runner,
    {{ jfield('payload', 'code_version') }}                         as code_version,
    {{ jfield('payload', 'model') }}                                as model,
    {{ jfield('payload', 'clip_target_seconds', 'double') }}        as clip_target_seconds,
    {{ jfield('payload', 'sample_fps', 'double') }}                 as sample_fps,
    {{ jfield('payload', 'stream_fps', 'double') }}                 as stream_fps,
    {{ jfield('payload', 'source_width', 'integer') }}              as source_width,
    {{ jfield('payload', 'source_height', 'integer') }}             as source_height,
    {{ jfield('payload', 'read_seconds', 'double') }}               as read_seconds,
    {{ jfield('payload', 'sun_elevation', 'double') }}              as sun_elevation,
    {{ jfield('payload', 'brightness', 'double') }}                 as brightness,
    {{ jfield('payload', 'contrast', 'double') }}                   as contrast,
    {{ jfield('payload', 'sharpness', 'double') }}                  as sharpness,
    {{ jfield('payload', 'motion', 'double') }}                     as motion,
    {{ jfield('payload', 'frames_analyzed', 'integer') }}           as frames_analyzed,
    {{ jfield('payload', 'clip_seconds', 'double') }}               as clip_seconds,
    {{ jfield('payload', 'in_view_mean.car', 'double') }}           as in_view_cars,
    {{ jfield('payload', 'in_view_mean.truck', 'double') }}         as in_view_trucks,
    {{ jfield('payload', 'in_view_mean.bus', 'double') }}           as in_view_buses,
    {{ jfield('payload', 'in_view_mean.motorcycle', 'double') }}    as in_view_motorcycles,
    {{ jfield('payload', 'tracks_total', 'integer') }}              as tracks_total,
    {{ jfield('payload', 'moving_vehicles.car', 'integer') }}       as moving_cars,
    {{ jfield('payload', 'moving_vehicles.truck', 'integer') }}     as moving_trucks,
    {{ jfield('payload', 'moving_vehicles.bus', 'integer') }}       as moving_buses,
    {{ jfield('payload', 'moving_vehicles.motorcycle', 'integer') }} as moving_motorcycles,
    {{ jfield('payload', 'speed_index', 'double') }}                as speed_index,
    _source_file,
    _loaded_at
from src
