
-- INTERMEDIATE LAYER — Business Logic Layer                       
-- Purpose: Classify models into high-level domain groups

-- ref() tracks lineage between models
-- dbt compiles this to: HF_ANALYTICS.STAGING.STG_HF_MODELS
with models as (
    select * from {{ ref('stg_hf_models') }}
),

enriched as (
    select
        *,
        --  Domain Classification via Jinja case statement 
        -- Jinja lets us write reusable SQL logic
        case
            when pipeline_tag in ('text-generation', 'text-classification',
                                  'token-classification', 'question-answering',
                                  'summarization', 'translation', 'fill-mask',
                                  'zero-shot-classification', 'sentence-similarity')
                then 'NLP'
            when pipeline_tag in ('image-classification', 'object-detection',
                                  'image-segmentation', 'image-to-text',
                                  'text-to-image', 'depth-estimation')
                then 'Computer Vision'
            when pipeline_tag in ('automatic-speech-recognition',
                                  'audio-classification', 'text-to-speech')
                then 'Audio'
            when pipeline_tag in ('reinforcement-learning', 'robotics')
                then 'RL & Robotics'
            when pipeline_tag in ('tabular-classification', 'tabular-regression')
                then 'Tabular'
            when pipeline_tag = 'feature-extraction'
                then 'Embeddings'
            else 'Other'
        end as domain_group,

        -- Popularity Tier 
        -- Macro call: generate_surrogate_key() creates a hash key
        case
            when downloads_count >= 1000000 then 'Mega'
            when downloads_count >= 100000 then 'Popular'
            when downloads_count >= 10000 then 'Growing'
            else 'Emerging'
        end as popularity_tier,

        -- Author Type 
        case
            when author in ('meta-llama', 'google', 'microsoft', 'facebook',
                            'bigscience', 'EleutherAI', 'stabilityai',
                            'mistralai', 'openai', 'deepseek-ai')
                then 'Major Lab'
            when author like '%university%' or author like '%academic%'
                then 'Academic'
            else 'Community'
        end as author_type,

        -- Age in Days (derived metric) 
        datediff('day', created_at, current_timestamp()) as model_age_days,

        -- Engagement Ratio 
        -- How "liked" a model is relative to downloads
        -- Safely handle division by zero with NULLIF
        round(
            likes_count / nullif(downloads_count, 0) * 1000, 
            4
        ) as likes_per_1k_downloads

    from models
)

select * from enriched