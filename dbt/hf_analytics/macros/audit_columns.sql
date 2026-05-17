-- MACRO: audit_columns                                      
-- Adds standard audit columns to every model               
-- Usage: {{ audit_columns() }}                           

{% macro audit_columns() %}
 
    {#
        IMPORTANT: Call this macro as the LAST item in your SELECT clause.
        No comma should follow it. The macro itself does NOT end with a comma.
 
        Example (correct):
            select
                model_id,
                downloads_count,
                ingested_at,
                {{ audit_columns() }}    ← last item, no comma after
            from source
 
        Example (wrong):
            select
                {{ audit_columns() }},   ← comma after = syntax error
                some_other_column
            from source
    #}
 
    current_timestamp() as _dbt_loaded_at,
    '{{ this.name }}' as _dbt_model_name
 
{% endmacro %}