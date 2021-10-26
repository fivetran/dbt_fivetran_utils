{% macro source_relation() -%}

{{ adapter.dispatch('source_relation', 'fivetran_utils') () }}

{%- endmacro %}

{% macro default__source_relation() %}

{% if var('union_schemas', none)  %}
, case
    {% for schema in var('union_schemas') %}
    when lower(replace(replace(_dbt_source_relation,'"',''),'`','')) like '%.{{ schema|lower }}.%' then '{{ schema|lower }}'
    {% endfor %}
  end as source_relation
{% elif var('union_databases', none) %}
, case
    {% for database in var('union_databases') %}
    when lower(replace(replace(_dbt_source_relation,'"',''),'`','')) like '%{{ database|lower }}.%' then '{{ database|lower }}'
    {% endfor %}
  end as source_relation
{% else %}
, '' as source_relation
{% endif %}

{% endmacro %}
