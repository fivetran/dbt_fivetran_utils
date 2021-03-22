{% macro staging_models_automation(package, target_schema, target_database, tables) %}

{% set package = ""~ package ~"" %}
{% set target_schema = ""~ target_schema ~"" %}
{% set target_database = ""~ target_database ~"" %}

{% set zsh_command = "source dbt_modules/fivetran_utils/columns_setup.sh '../dbt_"""~ package ~"""_source' stg_"""~ package ~""" """~ target_database ~""" """~ target_schema ~""" " %}

{% for t in tables %}
    {% if t != tables[-1] %}
        {% set help_command = zsh_command + t + " && \n" %}
    
    {% else %}
        {% set help_command = zsh_command + t %}

    {% endif %}
    {{ log(help_command, info=True) }}

{% endfor %}

{% endmacro %}