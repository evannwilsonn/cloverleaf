-- How well the detector counts vehicles, measured against hand-labelled frames
-- (seeds/eval_labels.csv). Split by light, because that is what the low_light rule rests on.
with j as (
    select
        p.frame_file,
        p.camera_id,
        case when p.sun_elevation >= {{ var('min_sun_elevation') }} then 'Daylight' else 'Dark' end as light,
        l.labelled_vehicles,
        p.predicted_vehicles,
        abs(p.predicted_vehicles - l.labelled_vehicles) as abs_error,
        abs(p.predicted_vehicles - l.labelled_vehicles) * 1.0 / nullif(l.labelled_vehicles, 0) as abs_pct_error
    from {{ ref('stg_eval_predictions') }} p
    join {{ ref('eval_labels') }} l on l.frame_file = p.frame_file
)
select
    light,
    count(*)                                                    as frames,
    sum(labelled_vehicles)                                      as labelled_vehicles,
    sum(predicted_vehicles)                                     as predicted_vehicles,
    avg(abs_error)                                              as mean_abs_error,
    avg(case when abs_error <= 1 then 1.0 else 0.0 end)         as share_within_one,
    avg(abs_pct_error)                                          as mean_abs_pct_error,
    sum(predicted_vehicles) * 1.0 / nullif(sum(labelled_vehicles), 0) as count_ratio
from j
group by 1
