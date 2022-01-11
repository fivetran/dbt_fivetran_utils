#!/bin/bash
mkdir -p $1/macros
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "'$5'", "schema_name": "'$4'", "database_name":"'$3'"}' | tail -n +2 > $1/macros/get_$5_columns.sql
