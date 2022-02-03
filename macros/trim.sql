{% macro trim(field, characters) -%}

    {{ adapter.dispatch('trim', packages = fivetran_utils._get_utils_namespaces()) (field, characters) }}

{% endmacro %}

{% macro default__trim(field, characters) %}

    trim({{ field }},{{ characters }})

{% endmacro %}

{% macro postgres__json_parse(string, string_path) %}

    trim({{ characters }} from {{ field }})

{% endmacro %}