{% macro lookback(from_date, datepart, interval, default_start_date) %}

{{ adapter.dispatch('lookback', 'fivetran_utils') (from_date, datepart, interval, default_start_date) }}

{%- endmacro %}

{% macro default__lookback(from_date, datepart='day', interval=7, default_start_date='2010-01-01')  %}

coalesce(
    (select {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp=from_date) }} 
        from {{ this }}), 
    {{ "'" ~ default_start_date ~ "'" }}
    )

{% endmacro %}