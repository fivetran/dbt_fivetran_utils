{% macro max_bool(boolean_field) -%}

{{ adapter.dispatch('max_bool', packages = fivetran_utils._get_utils_namespaces()) (boolean_field) }}

{%- endmacro %}

--Default max_bool calculation
{% macro default__first_value(boolean_field)  %}

    bool_or( {{ boolean_field }} )

{% endmacro %}

--max_bool calculation specific to Snowflake
{% macro snowflake__first_value(boolean_field)  %}

    max( {{ boolean_field }} )

{% endmacro %}

--max_bool calculation specific to BigQuery
{% macro bigquery__first_value(boolean_field)  %}

    max( {{ boolean_field }} )

{% endmacro %}