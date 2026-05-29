{% macro apply_source_relation() -%}
{{ adapter.dispatch('apply_source_relation', 'amazon_ads') () }}
{%- endmacro %}

{% macro default__apply_source_relation() -%}
, _dbt_source_relation as source_relation
{%- endmacro %}