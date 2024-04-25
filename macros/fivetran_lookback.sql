{% macro fivetran_lookback(from_date, datepart, interval, safety_date='2010-01-01') %}

{{ adapter.dispatch('fivetran_lookback', 'fivetran_utils') (from_date, datepart, interval, safety_date='2010-01-01') }}

{%- endmacro %}

{% macro default__fivetran_lookback(from_date, datepart, interval, safety_date='2010-01-01')  %}

    {% set sql_statement %}
        select coalesce({{ from_date }}, {{ "'" ~ safety_date ~ "'" }})
        from {{ this }}
    {%- endset -%}

    {%- set result = dbt_utils.get_single_value(sql_statement) %}

    {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp="cast('" ~ result ~ "' as date)") }}

{% endmacro %}