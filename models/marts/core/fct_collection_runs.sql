-- One row per collector run, plus the scheduled slots that never ran, so coverage is measurable.
with runs as (
    select
        run_id,
        min(run_started_at)                                   as run_started_at,
        count(*)                                              as cameras_attempted,
        sum(case when stream_status = 'ok' then 1 else 0 end) as cameras_read,
        sum(case when is_valid then 1 else 0 end)             as cameras_valid,
        max(runner)                                           as runner,
        max(code_version)                                     as code_version
    from {{ ref('int_captures__checked') }}
    group by run_id
)
select
    *,
    {{ to_pacific('run_started_at') }}                        as run_started_at_local,
    cast({{ to_pacific('run_started_at') }} as date)          as local_date
from runs
