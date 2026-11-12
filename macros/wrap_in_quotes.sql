{%- macro wrap_in_quotes(object_to_quote) -%}

{{ return(adapter.dispatch('wrap_in_quotes', 'fivetran_utils')(object_to_quote)) }}

{%- endmacro -%}

{%- macro default__wrap_in_quotes(object_to_quote) -%}
{#- Snowflake stores unquoted identifiers in uppercase, so uppercase before quoting to match them. -#}
    {{ adapter.quote(object_to_quote | upper if target.type == 'snowflake' else object_to_quote) }}
{%- endmacro -%}
