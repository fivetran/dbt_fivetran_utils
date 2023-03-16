{{
    config(
        materialized='incremental',
        partition_by = {'field': 'date_day', 'data_type': 'date'}
            if target.type not in ['spark', 'databricks'] else ['date_day'],
        unique_key='issue_day_id',
        incremental_strategy = 'merge' if target.type not in ('snowflake', 'postgres', 'redshift') else 'delete+insert',
        file_format = 'delta'
    )
}}

with spine as (

    {% if execute %}
    {% set first_date_query %}
    -- start at the first created issue
        select  min( created ) as min_date from {{ var ('issue') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
    {% else %} {% set first_date = "2016-01-01" %}
    {% endif %}


    select * 
    from (
        {{
            dbt_utils.date_spine(
                datepart = "day", 
                start_date =  "cast('" ~ first_date[0:10] ~ "' as date)", 
                end_date = dbt.dateadd("week", 1, dbt.current_timestamp_in_utc_backcompat())
            )   
        }} 
    ) as date_spine

    {% if is_incremental() %}
    -- compare to the earliest possible open_until date so that if a resolved issue is updated after a long period of inactivity, we don't need a full refresh
    -- essentially we need to be able to backfill
    where cast( date_day as date) >= (select min(earliest_open_until_date) from {{ this }} )
    {% endif %}
),

issue_dates as (

    select
        issue_id,
        cast( {{ dbt.date_trunc('day', 'created_at') }} as date) as created_on,

        -- resolved_at will become null if an issue is marked as un-resolved. if this sorta thing happens often, you may want to run full-refreshes of the field_history models often
        -- if it's not resolved include everything up to today. if it is, look at the last time it was updated 
        cast({{ dbt.date_trunc('day', 'case when resolved_at is null then ' ~ dbt.current_timestamp_in_utc_backcompat() ~ ' else updated_at end') }} as date) as open_until

    from {{ var('issue') }}

),

issue_spine as (

    select 
        cast(spine.date_day as date) as date_day,
        issue_dates.issue_id,
        -- will take the table-wide min of this in the incremental block at the top of this model
        min(issue_dates.open_until) as earliest_open_until_date

    from spine 
    join issue_dates on
        issue_dates.created_on <= spine.date_day
        and {{ dbt.dateadd('month', var('jira_issue_history_buffer', 1), 'issue_dates.open_until') }} >= spine.date_day
        -- if we cut off issues, we're going to have to do a full refresh to catch issues that have been un-resolved

    group by 1,2
),

surrogate_key as (

    select 
        date_day,
        issue_id,
        {{ dbt_utils.generate_surrogate_key(['date_day','issue_id']) }} as issue_day_id,
        earliest_open_until_date

    from issue_spine

    where date_day <= cast( {{ dbt.date_trunc('day',dbt.current_timestamp_in_utc_backcompat()) }} as date)
)

select * from surrogate_key 