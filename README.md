# Fivetran Utilities for dbt

This package includes macros that are used in Fivetran's dbt packages.

## Macros

#### fill_staging_columns ([source](macros/fill_staging_columns.sql))

This macro is used to generate the correct SQL for package staging models. It takes a list of columns that are expected/needed (`staging_columns`) and compares it with columns in the source (`source_columns`). `source_columns` should come from the `get_columns_in_relation` method, as used below.

**N.B.**: The argument passed to `get_columns_in_relation` needs to be a `ref()` or `source()`. It can't be a `var()`. This seems to be because of how the `var()` is parsed. If users are defining tables using variables, we should create `_tmp` models that simply do a `select *` from the variable. the `_tmp` models cannot be ephemeral because of how the `get_columns_in_relation` method works.

The `staging_columns` argument expects an array with dictionaries in the following format: 

```yml
{"name": "cancelled_at", "datatype": dbt_utils.type_timestamp(), "alias": "cancelled_timestamp"}
```
`name` and `datatype` are required. `alias` is optional.

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

----

#### generate_columns_macro ([source](macros/generate_columns_macro.sql))

This macro is used to generate the macros used in `fill_staging_columns` to list all the expected columns. It takes a `table_name`, `schema_name` and `database_name`. `database_name` is optional. If missing, the macro will assume the source data is in the `target.database`.

The macro should be run using dbt's `run-operation` functionality, as used below. It will print out the macro text, which can be copied and pasted into the relevant macro file in the package.

Usage:
```
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "promoted_tweet_report", "schema_name": "twitter_ads", "database_name": "dbt-package-testing"}'
```
----

#### columns_setup.sh ([source](columns_setup.sh))

This bash file can be used to setup or update packages to use the `fill_staging_columns` macro above. The bash script does the following three things:

* Creates a `.sql` file in the `macros` directory for a source table and fills it with all the columns from the table.
* Creates a `..._tmp.sql` file in the `models/tmp` directory and fills it with a `select * from {{ var('table_name') }}` where `table_name` is the name of the source table.
* Creates or updates a `.sql` file in the `models` directory and fills it with the filled out version of the `fill_staging_columns` macro as shown above. You can then write whatever SQL you want around the macro to finishing off the staging file.

The usage is as follows, assuming you are in a dbt project directory that has already imported this repo as a dependency:
```bash
source dbt_modules/fivetran_utils/columns_setup.sh "path/to/directory" file_prefix database_name schema_name table_name
```

As an example, assuming we are in a dbt project in an adjacent folder to `dbt_marketo_source`:
```bash
source dbt_modules/fivetran_utils/columns_setup.sh "../dbt_marketo_source" stg_marketo "digital-arbor-400" marketo_v3 deleted_program_membership
```

In that example, it will:
* Create a `get_deleted_program_membership_columns.sql` file in the `macros` directory, with the necessary macro within it.
* Create a `stg_marketo__deleted_program_membership_tmp.sql` file in the `models/tmp` directory, with `select * from {{ var('deleted_program_membership') }}` in it.
* Create or update a `stg_marketo__deleted_program_membership.sql` file in the `models` directory with the pre-filled out `fill_staging_columns` macro.