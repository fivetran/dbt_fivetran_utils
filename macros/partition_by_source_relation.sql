{% macro partition_by_source_relation(package_name, has_other_partitions='yes', alias=None) %}
    {{ return(adapter.dispatch('partition_by_source_relation', package_name)(has_other_partitions, alias)) }}
{% endmacro %}

{% macro default__partition_by_source_relation(has_other_partitions='yes', alias=None) -%}

{%- set is_unioning = var(package_name ~ '_union_schemas', [])|length > 1 or var(package_name ~ '_union_databases', [])|length > 1 -%}
{%- set prefix = '' if alias is none else alias ~ '.' -%}

{%- if has_other_partitions == 'no' -%}
    {{- 'partition by ' ~ prefix ~ 'source_relation' if is_unioning else '' -}}
{%- else -%}
    {{- ', ' ~ prefix ~ 'source_relation' if is_unioning else '' -}}
{%- endif -%}

{%- endmacro %}
