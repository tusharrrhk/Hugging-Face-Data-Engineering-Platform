-- MACRO: generate_surrogate_key                             
-- Creates a unique hash key from one or more columns        
-- Usage: {{ generate_surrogate_key(['col1', 'col2']) }}     

{% macro generate_surrogate_key(column_names) %}

    {# 
       This macro creates a MD5 hash from concatenated column values.
       MD5 is fast and creates a fixed-length key regardless of input.
       
       column_names: list of column name strings
       Example: generate_surrogate_key(['model_id', 'date'])
       Produces: md5(cast(model_id as varchar) || '-' || cast(date as varchar))
    #}

    md5(
        concat_ws(
            '-',   {# Separator between values #}
            {% for col in column_names %}
                cast({{ col }} as varchar)
                {% if not loop.last %},{% endif %}   {# Jinja loop : no comma after last item #}
            {% endfor %}
        )
    )

{% endmacro %}