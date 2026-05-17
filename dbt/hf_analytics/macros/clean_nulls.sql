-- MACRO: clean_string                                       
-- Clean and standardize string columns                     
-- Usage: {{ clean_string('column_name') }}                 

{% macro clean_string(column_name, default_value="'Unknown'") %}

    {#
       Applies a standard cleaning pipeline to any string column:
       1. NULLIF: treat empty strings as NULL
       2. TRIM: remove leading/trailing whitespace
       3. LOWER: standardize case
       4. COALESCE: replace NULL with a default
    #}

    coalesce(
        nullif(trim(lower({{ column_name }})), ''),
        {{ default_value }}
    )

{% endmacro %}