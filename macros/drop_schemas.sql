{% macro drop_schemas(drop_target_schema=true) %}

{% set fetch_list_sql %}
select schema_name
from {{ target.database }}.INFORMATION_SCHEMA.SCHEMATA
where lower(schema_name) like '{{ target.schema | lower }}{%- if not drop_target_schema -%}_{%- endif -%}%'
{% endset %}

{% set results = run_query(fetch_list_sql) %}

{% if execute %}
{% set results_list = results.columns[0].values() %}
{% else %}
{% set results_list = [] %}
{% endif %}


{% for schema_to_drop in results_list %}

{{ run_query("drop schema if exists " ~ schema_to_drop ~ " cascade;") }}

{% endfor %}

{% endmacro %}