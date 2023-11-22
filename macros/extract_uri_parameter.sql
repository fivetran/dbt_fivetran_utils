{% macro extract_uri_parameter(field, uri_parameter) -%}

{{ adapter.dispatch('extract_uri_parameter', 'fivetran_utils') (field, uri_parameter) }}

{% endmacro %}


{% macro default__extract_uri_parameter(field, uri_parameter) -%}

{{ dbt_utils.get_url_parameter(field, uri_parameter) }}

{%- endmacro %}


{% macro databricks__extract_uri_parameter(field, uri_parameter) -%}

{%- set formatted_uri_parameter = "'" + uri_parameter + "=([^&]+)'" -%}
nullif(regexp_extract({{ field }}, {{ formatted_uri_parameter }}, 1), '')

{%- endmacro %}