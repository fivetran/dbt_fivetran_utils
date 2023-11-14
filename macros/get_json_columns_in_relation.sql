{% macro get_json_columns_in_relation(source_columns) %}

{{ adapter.dispatch('get_json_columns_in_relation', 'fivetran_utils') (source_columns) }}

{%- endmacro %}

-- currently only need this for bigquery, so for everything else do nothing and just return an empty list
{% macro default__get_json_columns_in_relation(source_columns) %}
{{ return([]) }}
{% endmacro %}

-- we will return the columns that are of JSON type
{% macro bigquery__get_json_columns_in_relation(source_columns) %}

{% set json_columns = [] %}

{% set sc = source_columns|list %}

{% for col_index in range(sc|length) %}

    {% if sc[col_index].dtype|lower == 'json' %}
        {% do json_columns.append(sc[col_index].name) %}
        
    {% endif %}
{% endfor %}

{{ return(json_columns) }}

{% endmacro %}