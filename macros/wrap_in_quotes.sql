{%- macro wrap_in_quotes(thing) -%}

{{ return(adapter.dispatch('wrap_in_quotes', 'fivetran_utils')(thing)) }}

{%- endmacro -%}

{%- macro default__wrap_in_quotes(thing)  -%}
{# bigquery, spark, databricks #}
    `{{ thing }}`
{%- endmacro -%}

{%- macro snowflake__wrap_in_quotes(thing)  -%}
    "{{ thing | upper }}"
{%- endmacro -%}

{%- macro redshift__wrap_in_quotes(thing)  -%}
    "{{ thing }}"
{%- endmacro -%}

{%- macro postgres__wrap_in_quotes(thing)  -%}
    "{{ thing }}"
{%- endmacro -%}