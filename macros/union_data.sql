{% macro union_data(table_identifier, database_variable, schema_variable, default_database, default_schema, default_variable) -%}

{{ adapter.dispatch('union_data', packages = fivetran_utils._get_utils_namespaces()) (table_identifier, database_variable, schema_variable, default_database, default_schema, default_variable) }}

{%- endmacro %}

{% macro default__union_data(table_identifier, database_variable, schema_variable, default_database, default_schema, default_variable) %}

{% if var('shopify_union_schemas', none) %}

    {% set relations = [] %}

    {% for schema in var('shopify_union_schemas') %}

    {% set relation=adapter.get_relation(
        database=var(database_variable, default_database),
        schema=schema,
        identifier=table_identifier
    ) -%}
    
    {% set relation_exists=relation is not none %}

    {% if relation_exists %}

    {% do relations.append(relation) %}
    
    {% endif %}

    {% endfor %}

    {{ dbt_utils.union_relations(relations) }}

{% elif var('shopify_union_databases', none) %}

    {% set relations = [] %}

    {% for database in var('shopify_union_databases') %}

    {% set relation=adapter.get_relation(
        database=database,
        schema=var(schema_variable, default_schema),
        identifier=table_identifier
    ) -%}

    {% set relation_exists=relation is not none %}

    {% if relation_exists %}

    {% do relations.append(relation) %}
    
    {% endif %}

    {% endfor %}

    {{ dbt_utils.union_relations(relations) }}

{% else %}

    select * 
    from {{ var(default_variable) }}

{% endif %}

{% endmacro %}
