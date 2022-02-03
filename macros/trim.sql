{% macro trim(field, characters) -%}

    {{ adapter.dispatch('trim', 'fivetran_utils') (field, characters) }}

{% endmacro %}

{% macro default__trim(field, characters) %}

    trim({{ field }},{{ characters }})

{% endmacro %}

{% macro postgres__trim(field, characters) %}

    trim({{ characters }} from {{ field }})

{% endmacro %}