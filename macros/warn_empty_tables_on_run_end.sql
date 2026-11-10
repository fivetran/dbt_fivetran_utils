{% macro warn_empty_tables_on_run_end(results) %}
{#- dbt v2 (Fusion) only. union_connections skips its inline warning on v2, because the compile phase returns
    false positives. The fallback SQL that actually ran carries a marker comment, so this hook warns only for
    tables that are truly missing. -#}
{%- if execute and dbt_version.split(".")[0] | int >= 2 -%}
    {%- for res in results -%}
        {#- Fusion puts compiled_code on the result; Core puts it on the node. -#}
        {%- set compiled_code = res.compiled_code or (res.node.compiled_code if res.node is defined) or '' -%}
        {%- for table in modules.re.findall('-- fivetran_utils_empty_table: (\S+)', compiled_code) | unique -%}
            {{ exceptions.warn("\n\nPlease be aware: The " ~ table ~ " table was not found in your schema(s). The Fivetran Data Model created a completely empty staging model (" ~ res.node.name ~ ") as to not break downstream transformations. To turn off these warnings, set the `fivetran__remove_empty_table_warnings` variable to TRUE (see https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_connections-source for details).\n") }}
        {%- endfor -%}
    {%- endfor -%}
{%- endif -%}
{% endmacro %}
