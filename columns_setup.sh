#!/bin/bash
mkdir -p $1/macros
mkdir -p $1/models/tmp
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "'$5'", "schema_name": "'$4'", "database_name":"'$3'"}' | tail -n +2 > $1/macros/get_$5_columns.sql
echo "select *\nfrom {{ var('$5') }}" > $1/models/tmp/$2_$5_tmp.sql
echo "        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('$2_$5_tmp')),
                staging_columns=get_$5_columns()
            )
        }}"
