{% macro fill_staging_columns(source_columns, staging_columns) -%}

{%- set using_source_casing = var('fivetran_using_source_casing', false) %}
{%- set source_column_names = source_columns|map(attribute='name')|map('lower')|list -%}
{%- do staging_columns.append({'name': 'source_relation', 'datatype': dbt.type_string()})   %}

{%- for column in staging_columns %}
    {%- set column_name = column.name %}
    {%- set column_alias = column.alias if 'alias' in column else column.name %}

    {%- if column.name|lower in source_column_names %}
        -- Preserve the original casing of the column name from the source but uppercase the alias in Snowflake since Snowflake folds unquoted identifiers to uppercase.
        {% if using_source_casing %} 
        {{ adapter.quote(column_name) }} -- always quote but don't change case
        {%- else  %}
        {{ fivetran_utils.quote_column(column, column_name) }}
        {%- endif %}
    {%- else %}
        cast(null as {{ column.datatype }})
    {%- endif %}
    as {{ fivetran_utils.quote_column(column, column_alias) }},
{%- endfor %}
{%- endmacro %}


{% macro quote_column(column, column_name=column.name) %}
    {% if ('quote' in column and column.quote) or using_source_casing %}
        {{ adapter.quote(column_name|upper if target.type == 'snowflake' else column_name) }}
    {% else %}
        {{ column_name }}
    {% endif %}
{% endmacro %}
