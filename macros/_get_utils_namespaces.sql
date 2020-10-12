-- macro is necessary for cross-db compatibility to work
{% macro _get_utils_namespaces() %}
  {% set override_namespaces = var('dbt_utils_dispatch_list', []) %}
  {% do return(override_namespaces + ['dbt_utils', 'fivetran_utils']) %}
{% endmacro %}
