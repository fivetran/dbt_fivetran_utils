{%- macro quote(thing) -%}

{{ return(adapter.dispatch('quote', 'fivetran_utils')(thing)) }}

{%- endmacro -%}

{%- macro default__quote(thing)  -%}
{# bigquery, spark, databricks #}
    `{{ thing }}`
{%- endmacro -%}

{%- macro snowflake__quote(thing)  -%}
    "{{ thing | upper }}"
{%- endmacro -%}

{%- macro redshift__quote(thing)  -%}
    "{{ thing }}"
{%- endmacro -%}

{%- macro postgres__quote(thing)  -%}
    "{{ thing }}"
{%- endmacro -%}