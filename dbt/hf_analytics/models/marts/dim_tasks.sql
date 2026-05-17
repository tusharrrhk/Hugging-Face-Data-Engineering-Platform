{{ config(materialized='table') }}

with tasks as (
    select * from {{ ref('int_models_tagged') }}
),

-- One row per unique task type
task_agg as (
    select
        pipeline_tag,
        domain_group,
        count(distinct model_id) as model_count,
        sum(downloads_count) as total_downloads,
        avg(downloads_count) as avg_downloads,
        sum(likes_count) as total_likes
    from tasks
    where pipeline_tag is not null
    group by pipeline_tag, domain_group
),

-- Join with seed file for display names
task_categories as (
    select * from {{ ref('task_categories') }}  -- dbt seed
),  

final as (
    select
        {{ generate_surrogate_key(['t.pipeline_tag']) }} as task_key,
        t.pipeline_tag,
        coalesce(tc.display_name, t.pipeline_tag) as task_display_name,
        t.domain_group,
        coalesce(tc.description, 'No description') as task_description,
        t.model_count,
        t.total_downloads,
        round(t.avg_downloads, 0) as avg_downloads,
        t.total_likes
    from task_agg t
    left join task_categories tc
        on t.pipeline_tag = tc.pipeline_tag
)

select * from final