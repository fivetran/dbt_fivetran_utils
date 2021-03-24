{% macro seed_data_helper(seed_name, warehouse) %}

{% if target.type == "" ~ warehouse ~ "" %}
{{ return(ref(seed_name ~ "_" ~ warehouse ~ "")) }}
{% else %}
{{ return(ref(seed_name)) }}
{% endif %}

{% endmacro %}