{% macro apply_source_relation(package_name, use_package_prefix=true) -%}

{{ adapter.dispatch('apply_source_relation', 'fivetran_utils') (package_name, use_package_prefix) }}

{%- endmacro %}

{% macro default__apply_source_relation(package_name, use_package_prefix=true) -%}

{% set sources_var = package_name ~ '_sources' %}
{% set database_var = package_name ~ '_database' %}
{% set schema_var = package_name ~ '_schema' %}

{% if use_package_prefix %}
    {% set union_schemas_var = package_name ~ '_union_schemas' %}
    {% set union_databases_var = package_name ~ '_union_databases' %}
{% else %}
    {% set union_schemas_var = 'union_schemas' %}
    {% set union_databases_var = 'union_databases' %}
{% endif %}

{% if var(sources_var, []) != [] %}
, _dbt_source_relation as source_relation
{% elif var(union_schemas_var, []) != [] or var(union_databases_var, []) != [] %}
{{ fivetran_utils.source_relation() }}
{% else %}
{% set database = var(database_var, target.database) %}
{% set schema = var(schema_var, package_name) %}
, '{{ database ~ "." ~ schema }}' as source_relation
{% endif %}

{%- endmacro %}
