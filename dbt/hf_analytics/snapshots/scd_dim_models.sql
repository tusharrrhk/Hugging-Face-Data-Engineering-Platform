-- SNAPSHOT = SCD TYPE 2 implementation in dbt               
-- dbt automatically manages valid_from/valid_to/is_current

{% snapshot scd_dim_models %}

{{
    config(
        target_schema='snapshots',
        unique_key='model_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

-- Source query: what we want to track over time
select
    model_id,
    model_name,
    author,
    pipeline_tag,
    library_name,
    downloads_count,
    likes_count,
    popularity_tier,
    domain_group,
    created_at,
    updated_at
from {{ ref('int_models_tagged') }}

{% endsnapshot %}

