{% macro pivot_json_extract(json, list_of_properties) %}

{% for property in list_of_properties -%}
    replace( {{ fivetran_utils.json_extract(string = json, string_path = property) }}, '"', '')
        as {{ property | replace(' ', '_') | lower }}

{%- if not loop.last -%},{%- endif %}
{% endfor -%}

{% endmacro %}