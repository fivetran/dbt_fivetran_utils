{% macro apply_source_relation(package_name) -%}

{{ adapter.dispatch('apply_source_relation', 'fivetran_utils') (package_name) }}

{%- endmacro %}

{% macro default__apply_source_relation(package_name) -%}

{% if var(var('package_name') ~ '_sources', []) | length > 0 %}
, _dbt_source_relation as source_relation
{% else %}
, '{{ target.database }}' || '.'|| '{{ target.schema }}' as source_relation
{% endif %}

{%- endmacro %}