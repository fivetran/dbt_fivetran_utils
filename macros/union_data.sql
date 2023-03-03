{%- macro union_data(table_identifier, database_variable, schema_variable, default_database, default_schema, default_variable, column_macro=[{}], union_schema_variable='union_schemas', union_database_variable='union_databases') -%}

{{ adapter.dispatch('union_data', 'fivetran_utils') (
    table_identifier, 
    database_variable, 
    schema_variable, 
    default_database, 
    default_schema, 
    default_variable,
    column_macro,
    union_schema_variable,
    union_database_variable
    ) }}

{%- endmacro -%}

{%- macro default__union_data(
    table_identifier, 
    database_variable, 
    schema_variable, 
    default_database, 
    default_schema, 
    default_variable,
    column_macro,
    union_schema_variable,
    union_database_variable
    ) -%}

{%- if var(union_schema_variable, none) -%}

    {%- set relations = [] -%}
    
    {%- if var(union_schema_variable) is string -%}
    {%- set trimmed = var(union_schema_variable)|trim('[')|trim(']') -%}
    {%- set schemas = trimmed.split(',')|map('trim'," ")|map('trim','"')|map('trim',"'") -%}
    {%- else -%}
    {%- set schemas = var(union_schema_variable) -%}
    {%- endif -%}

    {%- for schema in var(union_schema_variable) -%}
    {%- set relation=adapter.get_relation(
        database=source(schema, table_identifier).database if var('has_defined_sources', false) else var(database_variable, default_database),
        schema=source(schema, table_identifier).schema if var('has_defined_sources', false) else schema,
        identifier=source(schema, table_identifier).identifier if var('has_defined_sources', false) else table_identifier
    ) -%}
    
    {%- set relation_exists=relation is not none -%}

    {%- if relation_exists -%}
        {%- do relations.append(relation) -%}
    {%- endif -%}

    {%- endfor -%}
    
    {%- if relations != [] -%}
        {{ dbt_utils.union_relations(relations) }}
    {%- else -%}
    select 
        {% if column_macro != [{}] %}{{ fivetran_utils.fill_staging_columns(source_columns=[], staging_columns=column_macro) }},{% endif -%} 
        cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
    {%- endif -%}

{%- elif var(union_database_variable, none) -%}

    {%- set relations = [] -%}

    {%- for database in var(union_database_variable) -%}
    {%- set relation=adapter.get_relation(
        database=source(schema, table_identifier).database if var('has_defined_sources', false) else database,
        schema=source(schema, table_identifier).schema if var('has_defined_sources', false) else var(schema_variable, default_schema),
        identifier=source(schema, table_identifier).identifier if var('has_defined_sources', false) else table_identifier
    ) -%}

    {%- set relation_exists=relation is not none -%}

    {%- if relation_exists -%}
        {%- do relations.append(relation) -%}
    {%- endif -%}

    {%- endfor -%}

    {%- if relations != [] -%}
        {{ dbt_utils.union_relations(relations) }}
    {%- else -%}
    select 
        {% if column_macro != [{}] %}{{ fivetran_utils.fill_staging_columns(source_columns=[], staging_columns=column_macro) }},{% endif -%}
        cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
    {%- endif -%}

{%- else -%}
    {%- set relation=adapter.get_relation(
        database=var(database_variable, default_database),
        schema=var(schema_variable, default_schema),
        identifier=var(default_schema ~ '_' ~ table_identifier ~ '_' ~ 'identifier', table_identifier)) -%}

{%- set table_exists=relation is not none -%}

{%- if table_exists -%}
    select * 
    from {{ var(default_variable) }}
{%- else -%}
    select 
        {% if column_macro != [{}] %}{{ fivetran_utils.fill_staging_columns(source_columns=[], staging_columns=column_macro) }},{% endif -%}
        cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
{%- endif -%}
{%- endif -%}

{%- endmacro -%}
