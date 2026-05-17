{{ config(materialized='table') }}

-- dim_models is a "slowly changing dimension" type 1 (overwrites)
-- For historical tracking, see snapshots/scd_dim_models.sql (SCD Type 2)

with source as (
    select * from {{ ref('int_models_tagged') }}
),

dim_authors as (
    select author_key, author_name
    from {{ ref('dim_authors') }}
),

dim_tasks as (
    select task_key, pipeline_tag
    from {{ ref('dim_tasks') }}
),

final as (
    select
        {{ generate_surrogate_key(['m.model_id']) }} as model_key,
        m.model_id,
        m.model_name,
        m.author,
        da.author_key,
        m.pipeline_tag,
        dt.task_key,
        m.library_name,
        m.domain_group,
        m.popularity_tier,
        m.author_type,
        m.tags_raw,
        m.model_age_days,
        m.created_at,
        m.updated_at,
        m.ingested_at
    from source m
    left join dim_authors da on m.author = da.author_name
    left join dim_tasks dt on m.pipeline_tag = dt.pipeline_tag
)

select * from final