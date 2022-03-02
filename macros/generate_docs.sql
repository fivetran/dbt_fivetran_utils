{% macro generate_docs(package) %}

{% set package = ""~ package ~"" %}

{% set zsh_command = "source dbt_packages/fivetran_utils/generate_docs.sh '../dbt_"""~ package ~""""+"'" %}

{{ log (zsh_command, info=True) }}

{% endmacro %} 