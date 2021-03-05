{% macro array_agg(field_to_agg) -%}

{{ adapter.dispatch('array_agg', packages = fivetran_utils._get_utils_namespaces()) (field_to_agg) }}

{%- endmacro %}

{% macro default__array_agg(field_to_agg) %}
    listagg({{ field_to_agg }}, ',')
{% endmacro %}

{% macro snowflake__array_agg(field_to_agg) %}
    array_agg({{ field_to_agg }})
{% endmacro %}

{% macro bigquery__array_agg(field_to_agg) %}
    array_agg({{ field_to_agg }})
{% endmacro %}