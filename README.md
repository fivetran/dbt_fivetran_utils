# Fivetran Utilities for dbt

This package includes macros that are used in Fivetran's dbt packages.

## Macros
### _get_utils_namespaces ([source](macros/_get_utils_namespaces.sql))
This macro allows for namespacing macros throughout a dbt project. The macro currently consists of two namespaces:
- `dbt_utils`
- `fivetran_utils`

----
### array_agg ([source](macros/array_agg.sql))
This macro allows for cross database field aggregation. The macro contains the database specific field aggregation function for 
BigQuery, Snowflake, Redshift, and Postgres. By default a comma `,` is used as a delimiter in the aggregation.

**Usage:**
```sql
{{ fivetran_utils.array_agg(field_to_agg="teams") }}
```
**Args:**
* `field_to_agg` (required): Field within the table you are wishing to aggregate.

----
### dummy_coalesce_value ([source](macros/dummy_coalesce_value.sql))
This macro creates a dummy coalesce value based on the data type of the field. See below for the respective data type and dummy values:
- String    = 'DUMMY_STRING'
- Boolean   = null
- Int       = 999999999
- Float     = 999999999.99
- Timestamp = cast("2099-12-31" as timestamp)
- Date      = cast("2099-12-31" as date)
**Usage:**
```sql
{{ fivetran_utils.dummy_coalesce_value(column="user_rank") }}
```
**Args:**
* `column` (required): Field you are applying the dummy coalesce.

----
### enabled_vars ([source](macros/enabled_vars.sql))
This macro references a specified boolean variable and returns the declared value. Typically this macro is used to enable or disable models if a user sets 
the variable to either `True` or `False` respectively. 

**Usage:**
```sql
{{ fivetran_utils.enabled_vars(vars="using_department_table") }}
```
**Args:**
* `vars` (required): Variable you are referencing to return the declared variable value.

----
### fill_staging_columns ([source](macros/.sql))
This macro is used to generate the correct SQL for package staging models. It takes a list of columns that are expected/needed (`staging_columns`) 
and compares it with columns in the source (`source_columns`). 

**Usage:**
```sql
select

    {{
        fivetran_utils.(
            source_columns=adapter.get_columns_in_relation(ref('stg_twitter_ads__account_history_tmp')),
            staging_columns=get_account_history_columns()
        )
    }}

from source
```
**Args:**
* `source_columns`  (required): Will call the [get_columns_in_relation](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#get_columns_in_relation) macro as well requires a `ref()` or `source()` argument for the staging models within the `_tmp` directory.
* `staging_columns` (required): Created as a result of running the [generate_columns_macro](https://github.com/fivetran/dbt_fivetran_utils#generate_columns_macro-source) for the respective table.

----
### first_value ([source](macros/first_value.sql))
This macro returns the value_expression for the first row in the current window frame with cross db functionality. This macro ignores null values. The default first_value calulcation within the macro is the `first_value` function. The Redshift first_value calculate is the `first_value` function, with the inclusion of a frame_clause `{{ partition_field }} rows unbounded preceding`.

**Usage:**
```sql
{{ fivetran_utils.first_value(first_value_field="created_at", partition_field="id", order_by_field="created_at", order="asc") }}
```
**Args:**
* `first_value_field` (required): The value expression which you want to determine the first value for.
* `partition_field`   (required): Name of the field you want to partition by to determine the first_value.
* `order_by_field`    (required): Name of the field you wish to sort on to determine the first_value.
* `order`             (optional): The order of which you want to partition the window frame. The order argument by default is `asc`. If you wish to get the last_value, you may change the argument to `desc`.

----
### generate_columns_macro ([source](macros/generate_columns_macro.sql))
This macro is used to generate the macro used as an argument within the [fill_staging_columns](https://github.com/fivetran/dbt_fivetran_utils#fill_staging_columns-source) macro which will list all the expected columns within a respective table. The macro output will contain `name` and `datatype`; however, you may add an optional argument for `alias` if you wish to rename the column within the macro. 

The macro should be run using dbt's `run-operation` functionality, as used below. It will print out the macro text, which can be copied and pasted into the relevant `macro` directory file within the package.

**Usage:**
```
dbt run-operation fivetran_utils.generate_columns_macro --args '{"table_name": "promoted_tweet_report", "schema_name": "twitter_ads", "database_name": "dbt-package-testing"}'
```
**Output:**
```sql
{% macro get_admin_columns() %}

{% set columns = [
    {"name": "email", "datatype": dbt_utils.type_string()},
    {"name": "id", "datatype": dbt_utils.type_string(), "alias": "admin_id"},
    {"name": "job_title", "datatype": dbt_utils.type_string()},
    {"name": "name", "datatype": dbt_utils.type_string()},
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt_utils.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
```
**Args:**
* `table_name`    (required): Name of the schema which the table you are running the macro for resides in.
* `schema_name`   (required): Name of the schema which the table you are running the macro for resides in.
* `database_name` (optional): Name of the database which the table you are running the macro for resides in. If empty, the macro will default this value to `target.database`.

----
### get_columns_for_macro ([source](macros/get_columns_for_macro.sql))
This macro returns all column names and datatypes for a specified table within a database and is used as part of the [generate_columns_macro](macros/generate_columns_macro.sql).

**Usage:**
```sql
{{ fivetran_utils.get_columns_for_macro(table_name="team", schema_name="my_teams", database_name="my_database") }}
```
**Args:**
* `table_name`    (required): Name of the table you are wanting to return column names and datatypes.
* `schema_name`   (required): Name of the schema where the above mentioned table resides.
* `database_name` (optional): Name of the database where the above mentioned schema and table reside. By default this will be your target.database.

----
### percentile ([source](macros/percentile.sql))
This macro is used to return the designated percentile of a field with cross db functionality. The percentile function stems from percentile_cont across db's. For Snowflake and Redshift this macro uses the window function opposed to the aggregate for percentile.

**Usage:**
```sql
{{ fivetran_utils.percentile(percentile_field='time_to_close', partition_field='id', percent='0.5') }}
```
**Args:**
* `percentile_field` (required): Name of the field of which you are determining the desired percentile.
* `partition_field`  (required): Name of the field you want to partition by to determine the designated percentile.
* `percent`          (required): The percent necessary for `percentile_cont` to determine the percentile. If you want to find the median, you will input `0.5` for the percent. 

----
### remove_prefix_from_columns ([source](macros/remove_prefix_from_columns.sql))
This macro removes desired prefixes from specified columns. Additionally, a for loop is utilized which allows for adding multiple columns to remove prefixes.

**Usage:**
```sql
{{ fivetran_utils.remove_prefix_from_columns(columns="names", prefix='', exclude=[]) }}
```
**Args:**
* `columns` (required): The desired columns you wish to remove prefixes.
* `prefix`  (optional): The prefix the macro will search for and remove. By default the prefix = ''.
* `exclude` (optional): The columns you wish to exclude from this macro. By default no columns are excluded.

----
### string_agg ([source](macros/string_agg.sql))
This macro allows for cross database field aggregation and delimiter customization. Supported database specific field aggregation functions include 
BigQuery, Snowflake, Redshift.

**Usage:**
```sql
{{ fivetran_utils.string_agg(field_to_agg="issues_opened", delimiter='|') }}
```
**Args:**
* `field_to_agg` (required): Field within the table you are wishing to aggregate.
* `delimiter`    (required): Character you want to be used as the delimiter between aggregates.
----
### timestamp_add ([source](macros/timestamp_add.sql))
This macro allows for cross database addition of a timestamp field and a specified datepart and interval for BigQuery, Redshift, and Snowflake.

**Usage:**
```sql
{{ fivetran_utils.timestamp_add(datepart="day", interval="1", from_timestamp="last_ticket_timestamp") }}
```
**Args:**
* `datepart`       (required): The datepart you are adding to the timestamp field.
* `interval`       (required): The interval in relation to the datepart you are adding to the timestamp field.
* `from_timestamp` (required): The timestamp field you are adding the datepart and interval.

----
### union_relations ([source](macros/union_relations.sql))
This macro unions together an array of [Relations](https://docs.getdbt.com/docs/writing-code-in-dbt/class-reference/#relation),
even when columns have differing orders in each Relation, and/or some columns are
missing from some relations. Any columns exclusive to a subset of these
relations will be filled with `null` where not present. An new column
(`_dbt_source_relation`) is also added to indicate the source for each record.

**Usage:**
```sql
{{ dbt_utils.union_relations(
    relations=[ref('my_model'), source('my_source', 'my_table')],
    exclude=["_loaded_at"]
) }}
```
**Args:**
* `relations`          (required): An array of [Relations](https://docs.getdbt.com/docs/writing-code-in-dbt/class-reference/#relation).
* `aliases`            (optional): An override of the relation identifier. This argument should be populated with the overwritten alias for the relation. If not populated `relations` will be the default.
* `exclude`            (optional): A list of column names that should be excluded from the final query.
* `include`            (optional): A list of column names that should be included in the final query. Note the `include` and `exclude` parameters are mutually exclusive.
* `column_override`    (optional): A dictionary of explicit column type overrides, e.g. `{"some_field": "varchar(100)"}`.``
* `source_column_name` (optional): The name of the column that records the source of this row. By default this argument is set to `none`.

---

## Bash Scripts
### columns_setup.sh ([source](columns_setup.sh))

This bash file can be used to setup or update packages to use the `` macro above. The bash script does the following three things:

* Creates a `.sql` file in the `macros` directory for a source table and fills it with all the columns from the table.
    * Be sure your `dbt_project.yml` file does not contain any **Warnings** or **Errors**. If warnings or errors are present, the messages from the terminal will be printed above the macro within the `.sql` file in the `macros` directory.
* Creates a `..._tmp.sql` file in the `models/tmp` directory and fills it with a `select * from {{ var('table_name') }}` where `table_name` is the name of the source table.
* Creates or updates a `.sql` file in the `models` directory and fills it with the filled out version of the `` macro as shown above. You can then write whatever SQL you want around the macro to finishing off the staging file.

The usage is as follows, assuming you are executing via a `zsh` terminal and in a dbt project directory that has already imported this repo as a dependency:
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
* Create or update a `stg_marketo__deleted_program_membership.sql` file in the `models` directory with the pre-filled out `` macro.