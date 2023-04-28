
with spine as (

    {% if execute %}
    {% set first_date_query %}
        select  min( transaction_date ) as min_date from {{ var ('bill') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
        {% if target.type == 'postgres' %}
            {% set first_date_adjust = "cast('" ~ first_date[0:10] ~ "' as date)" %}

        {% else %}
            {% set first_date_adjust = "'" ~ first_date[0:10] ~ "'" %}

        {% endif %}

    {% else %} {% set first_date_adjust = "'2000-01-01'" %}
    {% endif %}

    {% if execute %}
    {% set last_date_query %}
        select  max( transaction_date ) as max_date from {{ var ('bill') }}
    {% endset %}

    {% set current_date_query %}
        select current_date
    {% endset %}

    {% if run_query(current_date_query).columns[0][0]|string < run_query(last_date_query).columns[0][0]|string %}

    {% set last_date = run_query(last_date_query).columns[0][0]|string %}

    {% else %} {% set last_date = run_query(current_date_query).columns[0][0]|string %}
    {% endif %}
        
    {% if target.type == 'postgres' %}
        {% set last_date_adjust = "cast('" ~ last_date[0:10] ~ "' as date)" %}

    {% else %}
        {% set last_date_adjust = "'" ~ last_date[0:10] ~ "'" %}

    {% endif %}
    {% endif %}

    {{ dbt_utils.date_spine(
        datepart="month",
        start_date=first_date_adjust,
        end_date=dbt.dateadd("month", 1, last_date_adjust)
        )
    }}
),

general_ledger as (
    select *
    from {{ ref('quickbooks__general_ledger') }}
),

date_spine as (
    select
        cast({{ dbt.date_trunc("year", "date_month") }} as date) as date_year,
        cast({{ dbt.date_trunc("month", "date_month") }} as date) as period_first_day,
        {{ dbt.last_day("date_month", "month") }} as period_last_day,
        row_number() over (order by cast({{ dbt.date_trunc("month", "date_month") }} as date)) as period_index
    from spine
),

final as (
    select distinct
        general_ledger.account_id,
        general_ledger.source_relation,
        general_ledger.account_number,
        general_ledger.account_name,
        general_ledger.is_sub_account,
        general_ledger.parent_account_number,
        general_ledger.parent_account_name,
        general_ledger.account_type,
        general_ledger.account_sub_type,
        general_ledger.account_class,
        general_ledger.financial_statement_helper,
        general_ledger.class_id,
        date_spine.date_year,
        date_spine.period_first_day,
        date_spine.period_last_day,
        date_spine.period_index
    from general_ledger

    cross join date_spine
)

select *
from final
