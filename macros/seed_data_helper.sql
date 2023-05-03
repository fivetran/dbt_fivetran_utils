{% macro seed_data_helper(seed_name, warehouses, name_type=none) %}


{{ log('hi', info=true) }} 


{% if name_type == 'identifier' %}  

  {% if target.type in warehouses %}
    {% for w in warehouses %}
        {% if target.type == w %}
            {# {{ return(seed_name ~ "_" ~ w ~ "") }} #}

            {%- set relation=adapter.get_relation(
                    database=source('zendesk', seed_name).database,
                    schema=source('zendesk', seed_name).schema,
                    identifier=source('zendesk', seed_name).identifier
                ) -%}
            
            {{ log(relation, info=true) }}     
            {{ return(relation) }}
        {% endif %}
    {% endfor %}
   {% else %}
            {%- set relation=adapter.get_relation(
                    database=source('zendesk', 'brand').database,
                    schema=source('zendesk', 'brand').schema,
                    identifier=source('zendesk', 'brand').identifier
            ) -%}
            {{ log(relation, info=true) }}     
            {{ return(relation) }}
   {# {{ return(seed_name) }} #}
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