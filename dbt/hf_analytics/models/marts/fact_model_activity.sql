-- FACT TABLE — The heart of the Star Schema                   
-- Grain: One row per model per ingestion day                
-- Materialization: INCREMENTAL (process only new data)        

{{
    config(
        materialized='incremental',
        unique_key='activity_id',
        on_schema_change='append_new_columns'
    )
}}

with models as (
    select * from {{ ref('int_models_tagged') }}

    -- INCREMENTAL LOGIC:
    -- On first run: processes ALL records
    -- On subsequent runs: only processes records newer than the
    -- latest record already in the fact table
    -- is_incremental() is a dbt built-in Jinja function
    {% if is_incremental() %}
        where ingested_at > (
            select max(ingested_at) from {{ this }}
        )
        -- Add a dummy condition to ensure a clean finish if the subquery returns null
        and ingested_at is not null 
    {% endif %}
),

dim_models as (
    select model_key, model_id from {{ ref('dim_models') }}
),

dim_authors as (
    select author_key, author_name from {{ ref('dim_authors') }}
),

dim_tasks as (
    select task_key, pipeline_tag from {{ ref('dim_tasks') }}
),

dim_date as (
    select date_key, full_date from {{ ref('dim_date') }}
),

final as (
    select
        -- Surrogate Key 
        -- Unique ID for each fact row: model + date
        {{ generate_surrogate_key(["cast(m.model_id as string)", "cast(m.ingested_at as string)"]) }} as activity_id,

        -- Foreign Keys (join to dimensions) 
        dm.model_key,
        da.author_key,
        dt.task_key,
        dd.date_key as activity_date_key,

        -- Degenerate Dimensions (no separate table needed) 
        m.model_id,
        m.author,
        m.pipeline_tag,
        m.library_name,
        m.popularity_tier,

        -- Measures (the numeric facts) 
        m.downloads_count,
        m.likes_count,
        m.likes_per_1k_downloads,
        m.model_age_days,

        -- Timestamps 
        cast(m.ingested_at as date) as activity_date,
        m.ingested_at

    from models m
    left join dim_models dm on m.model_id = dm.model_id
    left join dim_authors da on m.author = da.author_name
    left join dim_tasks dt on m.pipeline_tag = dt.pipeline_tag
    left join dim_date dd on cast(m.ingested_at as date) = dd.full_date
)

 select * from final