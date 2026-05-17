{{ config(materialized='table') }}
 
with int_models as (
    select * from {{ ref('int_models_tagged') }}
),
 
-- Aggregate to author level (one row per author)
author_stats as (
    select
        author,
        author_type,
        count(distinct model_id) as total_models,
        sum(downloads_count) as total_downloads,
        sum(likes_count) as total_likes,
        avg(downloads_count) as avg_downloads_per_model,
        max(downloads_count) as max_model_downloads,
        min(created_at) as first_model_date,
        max(updated_at) as last_activity_date
    from int_models
    where author is not null
    group by author, author_type
),
 
-- Find primary task per author (most frequent pipeline_tag)
-- FIXED: Use ROW_NUMBER() instead of MODE() — works on all Snowflake versions
author_top_task as (
    select
        author,
        pipeline_tag as primary_task,
        row_number() over (
            partition by author
            order by count(*) desc
        ) as task_rank
    from int_models
    where author is not null
      and pipeline_tag is not null
    group by author, pipeline_tag
    qualify task_rank = 1 -- keep only the #1 most frequent task
),
 
-- Find primary library per author (same approach)
author_top_library as (
    select
        author,
        library_name as primary_library,
        row_number() over (
            partition by author
            order by count(*) desc
        ) as lib_rank
    from int_models
    where author is not null
      and library_name is not null
    group by author, library_name
    qualify lib_rank = 1
),
 
final as (
    select
        {{ generate_surrogate_key(['a.author']) }} as author_key,
        a.author as author_name,
        a.author_type,
        a.total_models,
        a.total_downloads,
        a.total_likes,
        round(a.avg_downloads_per_model, 0) as avg_downloads_per_model,
        a.max_model_downloads,
        a.first_model_date,
        a.last_activity_date,
        coalesce(t.primary_task,    'Unknown') as primary_task,
        coalesce(l.primary_library, 'Unknown') as primary_library,
        case
            when a.total_downloads >= 100000000 then 'Tier 1 - Major'
            when a.total_downloads >= 10000000 then 'Tier 2 - Notable'
            when a.total_downloads >= 1000000 then 'Tier 3 - Growing'
            else 'Tier 4 - Emerging'
        end as author_tier
    from author_stats a
    left join author_top_task t on a.author = t.author
    left join author_top_library l on a.author = l.author
)
 
select * from final