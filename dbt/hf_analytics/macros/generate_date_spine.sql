-- MACRO: generate_date_spine                              
-- Generates a table with one row per date between           
-- start_date and end_date                                  

{% macro generate_date_spine(start_date, end_date) %} 
    select
        dateadd(
            day,
            row_number() over (order by seq4()) - 1,
            {{ start_date }}::date
        ) as date_day
    from table(generator(rowcount => 10000))        -- literal integer only!
    qualify date_day <= {{ end_date }}::date
 
{% endmacro %}