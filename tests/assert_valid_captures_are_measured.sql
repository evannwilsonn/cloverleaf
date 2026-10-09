-- A capture that passed every rule must carry traffic measurements, and an excluded one must not.
select run_id, camera_id from {{ ref('fct_captures') }}
where (is_valid and vehicles_per_min is null) or (not is_valid and vehicles_per_min is not null)
