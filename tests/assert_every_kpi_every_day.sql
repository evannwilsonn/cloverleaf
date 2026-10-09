select local_date, count(distinct kpi_id) as kpis
from {{ ref('rpt_kpi_daily') }}
group by 1
having count(distinct kpi_id) <> (select count(*) from {{ ref('kpi_catalog') }})
