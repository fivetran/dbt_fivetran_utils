{% macro json_extract(string, string_path) -%}

{{ adapter.dispatch('json_extract', 'fivetran_utils') (string, string_path) }}

{%- endmacro %}

{% macro default__json_extract(string, string_path) %}

  json_extract_path_text({{string}}, {{ "'" ~ string_path ~ "'" }} )
 
{% endmacro %}

{% macro redshift__json_extract(string, string_path) %}

  json_extract_path_text({{string}}, {{ "'" ~ string_path ~ "'" }} )
 
{% endmacro %}

{% macro bigquery__json_extract(string, string_path) %}

  json_extract_scalar({{string}}, {{ "'$." ~ string_path ~ "'" }} )

{% endmacro %}

{% macro postgres__json_extract(string, string_path) %}

  {{string}}::json->>{{"'" ~ string_path ~ "'" }}

{% endmacro %}
