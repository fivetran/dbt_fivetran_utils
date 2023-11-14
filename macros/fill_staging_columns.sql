{% macro fill_staging_columns(source_columns, staging_columns) -%}

{%- set source_column_names = source_columns|map(attribute='name')|map('lower')|list -%}

{%- set json_columns = [] -%}
{% if target.type == 'bigquery' %}
    {%- set json_columns = fivetran_utils.get_json_columns_in_relation(source_columns) -%}
    {{ log(json_columns|lower, info=true)}}
{% endif %}

{%- for column in staging_columns %}
    {% if column.name|lower in source_column_names -%}
        {%- if column.name|lower in json_columns|lower -%}
            TO_JSON_STRING( {{ fivetran_utils.quote_column(column) }} )
        {%- else -%}
            {{ fivetran_utils.quote_column(column) }} 
        {%- endif %}
        as {%- if 'alias' in column %} {{ column.alias }} {% else %} {{ fivetran_utils.quote_column(column) }} {%- endif -%}
    {%- else -%}
        cast(null as {{ column.datatype }})
        {%- if 'alias' in column %} as {{ column.alias }} {% else %} as {{ fivetran_utils.quote_column(column) }} {% endif -%}
    {%- endif -%}
    {%- if not loop.last -%} , {% endif -%}
{% endfor %}

{% endmacro %}


{% macro quote_column(column) %}
    {% if 'quote' in column %}
        {% if column.quote %}
            {% if target.type in ('bigquery', 'spark', 'databricks') %}
            `{{ column.name }}`
            {% elif target.type == 'snowflake' %}
            "{{ column.name | upper }}"
            {% else %}
            "{{ column.name }}"
            {% endif %}
        {% else %}
        {{ column.name }}
        {% endif %}
    {% else %}
    {{ column.name }}
    {% endif %}
{% endmacro %}