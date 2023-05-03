{% macro seed_data_helper(seed_name, warehouses, name_type=none) %}


{% if name_type == 'identifier' %}  

  {% if target.type in warehouses %}
    {% for w in warehouses %}
        {% if target.type == w %}
            {{ return(seed_name ~ "_" ~ w ~ "") }}
        {% endif %}
    {% endfor %}
   {% else %}
   {{ return(seed_name) }}
 {% endif %}


{% elif name_type == 'ref' %}
   
  {% if target.type in warehouses %}
    {% for w in warehouses %}
        {% if target.type == w %}
            {{ return(ref(seed_name ~ "_" ~ w ~ "")) }}
        {% endif %}
    {% endfor %}
   {% else %}
   {{ return(ref(seed_name)) }}
 {% endif %}

{% else %}
{{ return(seed_name) }}
{% endif %}

{% endmacro %}

{{ log(whatever_you_want, info=true) }} 