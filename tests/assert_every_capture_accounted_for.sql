-- Every raw capture ends up in fct_captures exactly once and in the data-quality report.
select 'fct_captures' as model, (select count(*) from {{ ref('fct_captures') }}) as n,
       (select count(*) from {{ ref('stg_captures') }}) as expected
union all
select 'rpt_data_quality', (select sum(captures) from {{ ref('rpt_data_quality') }}),
       (select count(*) from {{ ref('stg_captures') }})
except
select m, e, e from (select 'fct_captures' as m, (select count(*) from {{ ref('stg_captures') }}) as e
                     union all select 'rpt_data_quality', (select count(*) from {{ ref('stg_captures') }})) x
