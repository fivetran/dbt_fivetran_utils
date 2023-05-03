{% macro identifier_seed_data(seed_name) %}

{{ return(ref(seed_name)) }}

{% endmacro %}