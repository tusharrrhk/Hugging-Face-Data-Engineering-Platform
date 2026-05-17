
-- STAGING LAYER — Silver                                      

with source as (
    select * from {{ source('raw', 'hf_models_raw') }}
),

parsed as (
    select
        --  Identity     
        -- Snowflake VARIANT access syntax: raw_data:field::TYPE
        raw_data:modelId::varchar(500) as model_id,
        raw_data:id::varchar(500) as model_name,

        --  Author / Organization 
        raw_data:author::varchar(200) as author,

        --  Task / Domain 
        raw_data:pipeline_tag::varchar(200) as pipeline_tag,

        --  Library 
        raw_data:library_name::varchar(100) as library_name,

        --  Engagement Metrics 
        -- COALESCE replaces NULLs with 0 — models with no downloads
        -- return null from API, but 0 is more useful downstream
        coalesce(raw_data:downloads::integer, 0) as downloads_count,
        coalesce(raw_data:likes::integer, 0) as likes_count,

        --  Tags (stored as JSON array) 
        raw_data:tags as tags_raw,

        --  Timestamps 
        -- TRY_TO_TIMESTAMP safely parses; returns NULL on failure
        try_to_timestamp(raw_data:createdAt::string) as created_at,
        try_to_timestamp(raw_data:lastModified::string) as updated_at,

        --  Metadata 
        ingested_at,
        source_file,

        --  Audit Column (added by macro) 
        {{ audit_columns() }}
    from source
),

-- Apply business filter: exclude noise (< 100 downloads)
-- var('min_downloads') comes from dbt_project.yml vars section
filtered as (
    select *
    from parsed
    where downloads_count >= {{ var('min_downloads') }} and model_id is not null
)

select * from filtered
