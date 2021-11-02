{% macro source_relation() -%}

{{ adapter.dispatch('source_relation', packages = fivetran_utils._get_utils_namespaces()) (union_schema_variable='union_schemas', union_database_variable='union_databases') }}

{%- endmacro %}

{% macro default__source_relation(union_schema_variable='union_schemas', union_database_variable='union_databases') %}

{% if var(union_schema_variable, none)  %}
, case
    {% for schema in var(union_schema_variable) %}
    when lower(replace(replace(_dbt_source_relation,'"',''),'`','')) like '%.{{ schema|lower }}.%' then '{{ schema|lower }}'
    {% endfor %}
  end as source_relation
{% elif var(union_database_variable, none) %}
, case
    {% for database in var(union_database_variable) %}
    when lower(replace(replace(_dbt_source_relation,'"',''),'`','')) like '%{{ database|lower }}.%' then '{{ database|lower }}'
    {% endfor %}
  end as source_relation
{% else %}
, '' as source_relation
{% endif %}

{% endmacro %}
