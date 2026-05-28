{% macro apply_source_relation(package_name) -%}

{{ adapter.dispatch('apply_source_relation', 'fivetran_utils') (package_name) }}

{%- endmacro %}

{% macro default__apply_source_relation(package_name) -%}

{% if var(package_name ~ '_sources', []) != [] %}
, _dbt_source_relation as source_relation
{% else %}
, '{{ var(package_name ~ "_database", target.database) }}' || '.'|| '{{ var(package_name ~ "_schema", package_name) }}' as source_relation
{% endif %}

{%- endmacro %}