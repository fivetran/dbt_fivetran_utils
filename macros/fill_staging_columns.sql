{% macro fill_staging_columns(source_columns, staging_columns) -%}

{%- set source_column_names = source_columns|map(attribute='name')|map('lower')|list -%}
{%- set using_mdls = var('using_fivetran_mdls', false) %}

{%- for column in staging_columns %}
    {%- if column.name|lower in source_column_names -%}
        {{ adapter.quote(column.name) if using_mdls else fivetran_utils.quote_column(column) }}
    {%- else -%}
        cast(null as {{ column.datatype }})
    {%- endif %}
    as {{ column.alias if 'alias' in column else fivetran_utils.quote_column(column) }},
{%- endfor %}
    {{ fivetran_utils.apply_source_relation() }}
{%- endmacro %}

{%- macro quote_column(column) %}
    {%- if ('quote' in column and column.quote) or using_mdls %}
        {{ adapter.quote(column.name|upper if target.type == 'snowflake' else column.name) }}
    {%- else %}
        {{ column.name }}
    {%- endif %}
{%- endmacro %}