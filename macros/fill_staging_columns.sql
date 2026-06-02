{% macro fill_staging_columns(source_columns, staging_columns) -%}

{%- set using_source_casing = var('fivetran_using_source_casing', false) -%}
{%- set source_column_names = source_columns | map(attribute='name') | map('lower') | list -%}
{%- do staging_columns.append({'name': 'source_relation', 'datatype': dbt.type_string()}) -%}

{%- for column in staging_columns %}
    {%- set column_name = column.name -%}
    {%- set column_alias = column.alias if 'alias' in column else column_name -%}
    {%- set quote_columns = ('quote' in column and column.quote) or using_source_casing -%}

    {%- set adjusted_column_name_casing = column_name|upper if target.warehouse == 'snowflake' and not using_source_casing else column_name -%}
    {%- set adjusted_alias_casing = column_alias|upper if target.warehouse == 'snowflake' else column_alias -%}

    {%- if column_name|lower in source_column_names -%}
        {%- set rendered_column_name = adapter.quote(adjusted_column_name_casing) if quote_columns else adjusted_column_name_casing -%}
    {%- else %}
        {%- set rendered_column_name = 'cast(null as ' ~ column.datatype ~ ')' -%}
    {%- endif -%}

    {%- set rendered_alias = adapter.quote(adjusted_alias_casing) if quote_columns else adjusted_alias_casing -%}
    
    {{ rendered_column_name }} as {{ rendered_alias }}{{',' if not loop.last }}

{%- endfor %}
{%- endmacro %}