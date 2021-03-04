{% macro ceiling(num) -%}

{{ adapter.dispatch('ceiling', packages = zendesk._get_utils_namespaces()) (num) }}

{%- endmacro %}

{% macro default__ceiling(num) %}
    ceiling({{ num }})

{% endmacro %}

{% macro snowflake__ceiling(num) %}
    ceil({{ num }})

{% endmacro %}
