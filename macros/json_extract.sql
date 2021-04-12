{% macro json_extract(string, string_path, json_type="scalar") -%}

{{ adapter.dispatch('json_extract', packages = fivetran_utils._get_utils_namespaces()) (string, string_path, json_type) }}

{%- endmacro %}

  {% macro default__json_extract(string, string_path, json_type) %}

    json_extract_path_text({{string}}, {{ "'" ~ string_path ~ "'" }} )
  
  {% endmacro %}

  {% macro bigquery__json_extract(string, string_path, json_type) %}

  {% if json_type == "array" %}

    json_extract_array({{string}}, {{ "'$" ~ string_path ~ "'" }} )
  
  {% else %}

    json_extract_scalar({{string}}, {{ "'$." ~ string_path ~ "'" }} )
  
  {% endif %}
  {% endmacro %}

  {% macro postgres__json_extract(string, string_path, json_type) %}

    {{string}}::json->>{{"'" ~ string_path ~ "'" }}  
  
  {% endmacro %}

{% endmacro %}
