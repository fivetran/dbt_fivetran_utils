{% macro fill_staging_columns(source_columns, staging_columns) -%}

{%- set source_column_names = source_columns|map(attribute='name')|map('lower')|list -%}
{%- set using_source_casing = var('fivetran_using_source_casing', false) -%}

{%- for column in staging_columns %}

    {%- if column.name|lower in source_column_names -%}
        
        {% if using_source_casing -%}
        {%- set column_alias = column.alias if 'alias' in column else column.name -%}
        {{ adapter.quote(column.name) }} as {{ adapter.quote(column_alias|upper if target.warehouse == 'snowflake' else column_alias) }} 
        
        {%- else %}
        {{ fivetran_utils.quote_column(column) }} as
        {%- if 'alias' in column %} {{ column.alias }} {% else %} {{ fivetran_utils.quote_column(column) }} {%- endif -%}
        
        {%- endif %}
    
    {%- else -%}
        cast(null as {{ column.datatype }}) as
        {%- if 'alias' in column %} {{ column.alias }} {% else %} {{ fivetran_utils.quote_column(column) }} {% endif -%}

    {%- endif -%}{{ ',' if not loop.last }}

{%- endfor %}

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