-- Quality gate: in daylight the detector must find at least min_daylight_count_ratio of the vehicles
-- counted by hand on the labelled frames, and its per-frame error must average under
-- max_daylight_mean_abs_pct_error. Relative measures, because frames range from 0 to 40+ vehicles.
-- Returns a row (fails the build) if daylight frames are missing or either measure misses.
with d as (
    select * from {{ ref('rpt_detection_accuracy') }} where light = 'Daylight'
)
select 'no daylight frames labelled' as problem from (select count(*) as n from d) x where n = 0
union all
select 'daylight count ratio ' || cast(round(count_ratio, 2) as varchar) from d
where count_ratio < {{ var('min_daylight_count_ratio') }}
union all
select 'daylight mean absolute % error ' || cast(round(mean_abs_pct_error, 2) as varchar) from d
where mean_abs_pct_error > {{ var('max_daylight_mean_abs_pct_error') }}
