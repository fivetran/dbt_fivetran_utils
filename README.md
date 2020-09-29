# Fivetran Utilities for dbt

This package includes macros that are used in Fivetran's dbt packages.

## Macros

#### fill_staging_columns ([source](macros/fill_staging_columns.sql))

Usage:
```sql
select

    {{
        fivetran_utils.fill_staging_columns(
            source_columns=adapter.get_columns_in_relation(ref('stg_twitter_ads__account_history_tmp')),
            staging_columns=get_account_history_columns()
        )
    }}

from source
```

#### generate_columns_macro ([source](macros/generate_columns_macro.sql))

Usage:
```
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "promoted_tweet_report", "schema_name": "twitter_ads", "database_name": "dbt-package-testing"}'
```