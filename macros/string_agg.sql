
{% macro string_agg(field_to_agg, delimiter) -%}

{{ adapter.dispatch('string_agg', packages = fivetran_utils._get_utils_namespaces()) (field_to_agg, delimiter) }}

{%- endmacro %}

{% macro default__string_agg(field_to_agg, delimiter) %}
    string_agg({{ field_to_agg }}, {{ delimiter }})

{% endmacro %}

{% macro snowflake__string_agg(field_to_agg, delimiter) %}
    listagg({{ field_to_agg }}, {{ delimiter }})

{% endmacro %}

{% macro redshift__string_agg(field_to_agg, delimiter) %}
    listagg({{ field_to_agg }}, {{ delimiter }})

{% endmacro %}