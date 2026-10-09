select
    frame_file,
    camera_id,
    cast(cars as integer)        as predicted_cars,
    cast(trucks as integer)      as predicted_trucks,
    cast(buses as integer)       as predicted_buses,
    cast(motorcycles as integer) as predicted_motorcycles,
    cast(cars as integer) + cast(trucks as integer) + cast(buses as integer) + cast(motorcycles as integer) as predicted_vehicles,
    cast(sun_elevation as double) as sun_elevation,
    model
from {{ source('raw_cloverleaf', 'eval_predictions') }}
