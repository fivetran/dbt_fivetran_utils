#!/bin/bash
mkdir -p $1/models/tmp #  the $ number signs reference the arguments in the staging_models_automation.sql file line 8
dbt run-operation fivetran_utils.get_column_names_only --args '{"table_name": "'$5'", "schema_name": "'$4'", "database_name":"'$3'"}' | tail -n +2 > $1/models/tmp/$2__$5_columns.sql 
# dbt run-operation get_column_names_only --args '{table_name: log, schema_name: fivetran_log, database_name: dbt-package-testing}' >> fivetran_log/models/log__log_temp.sql 
echo "select * from {{ var('$5') }}" > $1/models/tmp/$2__$5_tmp.sql 
echo "" > $1/models/$2__$5.sql
echo "with base as (
    select * 
    from {{ ref('$2__$5_tmp') }}
),
fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('$2__$5_tmp')),
                staging_columns=get_$5_columns()
            )
        }}
        
    from base
),
final as (
    
    select 
    " >> $1/models/$2__$5.sql
    
sed "1p;d" $1/models/tmp/$2__$5_columns.sql >> $1/models/$2__$5.sql
    
echo "from fields
)
select * from final" >> $1/models/$2__$5.sql