{% macro drop_schemas(schema_suffixes=[], drop_target_schema=true) %}

{% set schemas_to_drop = [target.schema] if drop_target_schema else [] %}

{% for suffix in schema_suffixes %}
{% do schemas_to_drop.append(target.schema ~ suffix) %}
{% endfor %}

{% for s in schemas_to_drop %}

{{ run_query("drop schema if exists `" ~ target.database ~ "`.`" ~ s ~ "` cascade;") }}

{# {{ print('drop schema if exists `' ~ target.database ~ '`.`' ~ s ~ '` cascade;') }} #}
{% endfor %}

{% endmacro %}