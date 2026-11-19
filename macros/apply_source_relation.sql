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

{% if var(sources_var, []) | length > 0 %}
, _dbt_source_relation as source_relation
{% elif var(union_schemas_var, []) | length > 0 or var(union_databases_var, []) | length > 0 %}
{{ fivetran_utils.source_relation(union_schema_variable=union_schemas_var, union_database_variable=union_databases_var) }}
{% else %}
{% set database = var(database_var, target.database) %}
{% set schema = var(schema_var, package_name) %}
, cast('{{ database ~ "." ~ schema }}' as {{ dbt.type_string() }}) as source_relation
{% endif %}

{%- endmacro %}
