-- One row per KPI per local (Pacific) day, with its target status. Definitions: seeds/kpi_catalog.csv.
with bounds as (
    select min(run_started_at_local) as first_run, max(run_started_at_local) as last_run
    from {{ ref('fct_collection_runs') }}
),
days as (
    select distinct local_date from {{ ref('fct_captures') }}
),
expected as (
    -- scheduled slots on each day, counting only the part of the day the collector has existed for
    select
        d.local_date,
        greatest(1, round({{ hours_between(
            'greatest(cast(d.local_date as timestamp), b.first_run)',
            'least(cast(d.local_date as timestamp) + interval \'1 day\', b.last_run)') }} * {{ var('runs_per_day') }} / 24.0) + 1) as expected_runs
    from days d cross join bounds b
),
runs as (
    select local_date, count(*) as runs from {{ ref('fct_collection_runs') }} group by 1
),
caps as (
    select
        local_date,
        count(*)                                                                    as attempted,
        sum(case when is_live_feed then 1 else 0 end)                               as live,
        sum(case when is_daylight then 1 else 0 end)                                as daylight_attempted,
        sum(case when is_daylight and is_valid then 1 else 0 end)                   as daylight_valid,
        avg(case when is_valid then vehicles_per_min end)                           as vehicles_per_min,
        sum(case when is_valid then moving_heavy else 0 end) * 1.0
            / nullif(sum(case when is_valid then moving_vehicles else 0 end), 0)    as truck_share,
        avg(case when is_valid then cast(is_congested as integer) end)              as congestion_rate
    from {{ ref('fct_captures') }}
    group by 1
),
values_long as (
    select c.local_date, 'collection_coverage' as kpi_id, least(1.0, r.runs * 1.0 / e.expected_runs) as value
    from caps c join runs r using (local_date) join expected e using (local_date)
    union all select local_date, 'feed_availability', live * 1.0 / nullif(attempted, 0) from caps
    union all select local_date, 'daylight_valid_rate', daylight_valid * 1.0 / nullif(daylight_attempted, 0) from caps
    union all select local_date, 'vehicles_per_min', vehicles_per_min from caps
    union all select local_date, 'truck_share', truck_share from caps
    union all select local_date, 'congestion_rate', congestion_rate from caps
)
select
    v.local_date,
    v.kpi_id,
    k.kpi_name,
    k.category,
    k.unit,
    v.value,
    k.target,
    case
        when k.target is null or v.value is null then 'no target'
        when k.target_type = 'min' and v.value >= k.target then 'met'
        when k.target_type = 'max' and v.value <= k.target then 'met'
        else 'missed'
    end as target_status
from values_long v
join {{ ref('kpi_catalog') }} k on k.kpi_id = v.kpi_id
