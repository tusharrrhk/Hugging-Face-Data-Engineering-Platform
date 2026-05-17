-- Test: Every fact row should have a matching model dimension

select
    f.activity_id,
    f.model_key,
    'Missing model dimension key' as failure_reason
from {{ ref('fact_model_activity') }} f
left join {{ ref('dim_models') }} d
    on f.model_key = d.model_key
where d.model_key is null
  and f.model_key is not null