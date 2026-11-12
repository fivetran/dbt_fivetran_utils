{% macro union_connections(connection_dictionary, single_source_name, single_table_name, default_identifier=single_table_name) %}

{{ adapter.dispatch('union_connections', 'fivetran_utils') (connection_dictionary, single_source_name, single_table_name, default_identifier) }}

{%- endmacro %}

{% macro default__union_connections(connection_dictionary, single_source_name, single_table_name, default_identifier=single_table_name) %}

{%- set exception_warning = "\n\nPlease be aware: The " ~ single_source_name|upper ~ "." ~ single_table_name|upper ~ " table was not found in your schema(s). The Fivetran Data Model will create a completely empty staging model as to not break downstream transformations. To turn off these warnings, set the `fivetran__remove_empty_table_warnings` variable to TRUE (see https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_connections-source for details).\n"%}
{%- set using_empty_table_warnings = (execute and not var('fivetran__remove_empty_table_warnings', false)) %}
{%- set connections = var(connection_dictionary, []) %}
{%- set using_unioning = connections | length > 0 %}
{%- set identifier_var = single_source_name + "_" + single_table_name + "_identifier" %}
{#- dbt v2 renders every model once before the run with no live warehouse access, so get_relation returns
    none even for tables that exist. In that pass, list_schemas also returns no schemas. Only warn when the warehouse
    returns at least one schema, so the warning fires in the real run pass only. dbt v1 always warns as before. -#}
{%- set is_dbt_v2 = dbt_version.split(".")[0] | int >= 2 %}

{%- if using_unioning %}
{# For unioning #}
    {%- set relations = [] -%}
    {%- for connection in connections -%}

        {% if var('has_defined_sources', false) %}
            {%- set database = source(connection.name, single_table_name).database %}
            {%- set schema = source(connection.name, single_table_name).schema %}
            {%- set identifier = source(connection.name, single_table_name).identifier %}
        {%- else %}
            {%- set database = connection.database if connection.database else target.database %}
            {%- set schema = connection.schema if connection.schema else single_source_name %}
            {%- set identifier = var(identifier_var, default_identifier) %}
        {%- endif %}
        
        {%- set relation=adapter.get_relation(
            database=database,
            schema=schema,
            identifier=identifier
            )
        -%}

        {%- if relation is not none -%}
            {%- do relations.append(relation) -%}
        {%- endif -%}

        -- ** Values passed to adapter.get_relation:
        {{ '-- database: ' ~ database }}
        {{ '-- schema: ' ~ schema }}
        {{ '-- identifier: ' ~ identifier ~ '\n' }}

    {%- endfor -%}

    {%- if relations | length > 0 -%}
        {{ dbt_utils.union_relations(relations, source_column_name='_dbt_source_relation', include_table_in_source_column=false) }}

    {%- else -%}
        {%- if using_empty_table_warnings %}
            {%- set first_connection = connections[0] %}
            {%- set canary_database = source(first_connection.name, single_table_name).database if var('has_defined_sources', false) else (first_connection.database if first_connection.database else target.database) %}
            {{ exceptions.warn(exception_warning) if not is_dbt_v2 or adapter.list_schemas(canary_database) | length > 0 }}
        {%- endif %}

        select
            cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
        limit {{ '0' if target.type != 'redshift' else '1' }}
    {%- endif -%}

{% else %}
{# Not unioning #}

    {%- set database = source(single_source_name, single_table_name).database %}
    {%- set schema = source(single_source_name, single_table_name).schema %}
    {%- set identifier = var(identifier_var, default_identifier) %}

    {%- set relation=adapter.get_relation(
        database=database,
        schema=schema,
        identifier=identifier
        )
    -%}

    -- ** Values passed to adapter.get_relation:
    {{ '-- full-identifier_var: ' ~ identifier_var }}
    {{ '-- database: ' ~ database }}                            
    {{ '-- schema: ' ~ schema }}
    {{ '-- identifier: ' ~ identifier ~ '\n' }}

    {% if relation is not none -%}
        select
            {{ dbt_utils.star(from=source(single_source_name, single_table_name)) }}
        from {{ source(single_source_name, single_table_name) }} as source_table

    {% else %}
        {{ exceptions.warn(exception_warning) if using_empty_table_warnings and (not is_dbt_v2 or adapter.list_schemas(database) | length > 0) }}

        select
            cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
        limit {{ '0' if target.type != 'redshift' else '1' }}
    {%- endif -%}
{% endif -%}

{%- endmacro %}
