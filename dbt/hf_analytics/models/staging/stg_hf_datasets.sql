    with source as (
    select * from {{ source('raw', 'hf_datasets_raw') }}
    ),

parsed as (
    select
        raw_data:id::varchar(500) as dataset_id,
        raw_data:author::varchar(200) as author,
        raw_data:tags as tags_raw,
        coalesce(raw_data:downloads::integer, 0) as downloads_count,
        coalesce(raw_data:likes::integer, 0) as likes_count,
        raw_data:paperswithcode_id::varchar(200) as paper_id,
        try_to_timestamp(raw_data:createdAt::string) as created_at,
        try_to_timestamp(raw_data:lastModified::string) as updated_at,
        ingested_at,
        {{ audit_columns() }}
    from source
)

select * from parsed
where dataset_id is not null