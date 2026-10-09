-- How every capture was accounted for, per day: valid, or the first rule it failed.
select
    f.local_date,
    coalesce(f.exclusion_reason, 'valid')   as outcome,
    coalesce(q.rule_name, 'Valid')          as outcome_name,
    coalesce(q.priority, 0)                 as priority,
    count(*)                                as captures
from {{ ref('fct_captures') }} f
left join {{ ref('qc_rules') }} q on q.rule_id = f.exclusion_reason
group by 1, 2, 3, 4
