{% macro staging_models_automation(package, source_schema, source_database, tables) %}

{% set package = ""~ package ~"" %}
{% set source_schema = ""~ source_schema ~"" %}
{% set source_database = ""~ source_database ~"" %}

{% set zsh_command_columns = "source dbt_packages/fivetran_utils/generate_columns.sh '../dbt_"""~ package ~"""_source' stg_"""~ package ~""" """~ source_database ~""" """~ source_schema ~""" " %}
{% set zsh_command_models = "source dbt_packages/fivetran_utils/generate_models.sh '../dbt_"""~ package ~"""_source' stg_"""~ package ~""" """~ source_database ~""" """~ source_schema ~""" " %}

{%- set columns_array = [] -%}
{%- set models_array = [] -%}

{% for t in tables %}
    {% set help_command = zsh_command_columns + t %}
    {{ columns_array.append(help_command) }}

    {% set help_command = zsh_command_models + t %}
    {{ models_array.append(help_command) }}

{% endfor %}

{{ log(columns_array|join(' && \n') + ' && \n' + models_array|join(' && \n'), info=True) }}

{% endmacro %} 