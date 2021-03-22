{% macro passthru_columns(columns=[]) %}

{% if columns != [] -%},{% endif %}
{{ columns | join(', ') }}

{% endmacro %}