{% macro slugify_sql(field) %}
regexp_replace(regexp_replace(regexp_replace(lower({{ field }}), '^[0-9]', '_' || substring(lower({{ field }}), 2)), '[^a-z0-9_]+', ''), '[ -]+', '_')
{% endmacro %}