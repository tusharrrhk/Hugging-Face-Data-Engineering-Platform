-- Date dimension is fundamental — every fact table joins to it

{{ config(materialized='table') }}
 
with date_spine as (
    -- CORRECT: macro expands to a plain SELECT (no nested WITH)
    -- Compiled output will look like:
    --   select dateadd(day, row_number() over (order by seq4()) - 1,
    --                  '2020-01-01'::date) as date_day
    --   from table(generator(rowcount => 10000))
    --   qualify date_day <= current_date()::date
 
    {{ generate_date_spine(
        start_date = "'2020-01-01'",
        end_date   = "current_date()"
    ) }}
),
 
enriched as (
    select
        -- Surrogate key: compact integer YYYYMMDD (fast joins, readable)
        to_number(to_char(date_day, 'YYYYMMDD')) as date_key,
        date_day as full_date,
        year(date_day) as year,
        quarter(date_day) as quarter,
        month(date_day) as month,
        to_char(date_day, 'MMMM') as month_name,
        day(date_day) as day_of_month,
        dayofweek(date_day) as day_of_week,
        to_char(date_day, 'DY') as day_name_short,
        weekofyear(date_day) as week_of_year,
        case
            when dayofweek(date_day) in (0, 6) then false
            else true
        end as is_weekday,
        to_char(date_day, 'YYYY-MM') as year_month,
        concat('Q', quarter(date_day), '-', year(date_day)) as quarter_label
    from date_spine
)
 
select * from enriched