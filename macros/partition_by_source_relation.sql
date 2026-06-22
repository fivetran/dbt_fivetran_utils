{% macro partition_by_source_relation(package_name, has_other_partitions='yes', alias=None, package_prefix_union_variable=true) %}
    {{ return(adapter.dispatch('partition_by_source_relation', 'fivetran_utils')(package_name, has_other_partitions, alias, package_prefix_union_variable)) }}
{% endmacro %}

{% macro default__partition_by_source_relation(package_name, has_other_partitions='yes', alias=None, package_prefix_union_variable=true) -%}

{%- if package_prefix_union_variable %}
    {%- set union_schemas_var = package_name ~ '_union_schemas' -%}
    {%- set union_databases_var = package_name ~ '_union_databases' -%}
{%- else %}
    {%- set union_schemas_var = 'union_schemas' -%}
    {%- set union_databases_var = 'union_databases' -%}
{%- endif -%}

{%- set is_unioning = var(union_schemas_var, [])|length > 1 or var(union_databases_var, [])|length > 1 or var(package_name ~ '_sources', [])|length > 1 -%}
{%- set prefix = '' if alias is none else alias ~ '.' -%}

{%- if has_other_partitions == 'no' -%}
    {{- 'partition by ' ~ prefix ~ 'source_relation' if is_unioning else '' -}}
{%- else -%}
    {{- ', ' ~ prefix ~ 'source_relation' if is_unioning else '' -}}
{%- endif -%}

{%- endmacro %}
