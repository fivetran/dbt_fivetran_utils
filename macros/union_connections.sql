{% macro union_connections(connection_dictionary, single_source_name, single_table_name, default_identifier=single_table_name) %}

{{ adapter.dispatch('union_connections', 'fivetran_utils') (connection_dictionary, single_source_name, single_table_name, default_identifier) }}

{%- endmacro %}

{% macro default__union_connections(connection_dictionary, single_source_name, single_table_name, default_identifier=single_table_name) %}

{%- set exception_warning = "\n\nPlease be aware: The " ~ single_source_name|upper ~ "." ~ single_table_name|upper ~ " table was not found in your schema(s). The Fivetran Data Model will create a completely empty staging model as to not break downstream transformations. To turn off these warnings, set the `fivetran__remove_empty_table_warnings` variable to TRUE (see https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_connections-source for details).\n"%}
{%- set using_empty_table_warnings = (execute and not var('fivetran__remove_empty_table_warnings', false)) %}
{%- set connections = var(connection_dictionary, []) %}
{%- set using_unioning = connections | length > 0 %}
{%- set identifier_var = single_source_name + "_" + single_table_name + "_identifier" %}
{%- set dbt_major_version = 'v2' if dbt_version.split(".")[0] | int >= 2 else 'v1' %}

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
        {{ fivetran_utils.union_relations_custom(relations, source_column_name='_dbt_source_relation') }}

    {%- else -%}
        {%- if using_empty_table_warnings %}
        {#- On v2 (Fusion), warn_empty_tables_on_run_end raises this warning instead, to skip compile-phase false positives. #}
        {{ '-- fivetran_utils_empty_table: ' ~ single_source_name|upper ~ '.' ~ single_table_name|upper if dbt_major_version == 'v2' else exceptions.warn(exception_warning) }}
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
        {%- if using_empty_table_warnings %}
        {#- On v2 (Fusion), warn_empty_tables_on_run_end raises this warning instead, to skip compile-phase false positives. #}
        {{ '-- fivetran_utils_empty_table: ' ~ single_source_name|upper ~ '.' ~ single_table_name|upper if dbt_major_version == 'v2' else exceptions.warn(exception_warning) }}
        {%- endif %}

        select
            cast(null as {{ dbt.type_string() }}) as _dbt_source_relation
        limit {{ '0' if target.type != 'redshift' else '1' }}
    {%- endif -%}
{% endif -%}

{%- endmacro %}
