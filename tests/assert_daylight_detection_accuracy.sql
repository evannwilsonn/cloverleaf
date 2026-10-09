-- Quality gate: the detector must count vehicles in daylight within the configured error on the
-- hand-labelled frames. Returns a row (fails the build) if daylight accuracy is missing or below the gate.
with d as (
    select * from {{ ref('rpt_detection_accuracy') }} where light = 'Daylight'
)
select 'no daylight frames labelled' as problem from (select count(*) as n from d) x where n = 0
union all
select 'daylight mean absolute error ' || cast(round(mean_abs_error, 2) as varchar) from d
where mean_abs_error > {{ var('max_daylight_mae') }}
union all
select 'daylight share within one vehicle ' || cast(round(share_within_one, 2) as varchar) from d
where share_within_one < {{ var('min_daylight_within_one') }}
