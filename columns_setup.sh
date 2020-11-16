#!/bin/bash
mkdir -p macros
mkdir -p models/tmp
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "'$1'", "schema_name": "'$2'", "database_name":"'$3'"}' | tail -n +2 >> macros/get_$1_columns.sql
echo "select *\nfrom {{ var('$1') }}" > models/tmp/$4_$1_tmp.sql
echo "        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('$4_$1_tmp')),
                staging_columns=get_$1_columns()
            )
        }}"
