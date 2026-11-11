# Fivetran Utility Macros for dbt

# Who are the intended users of this package?
- The Fivetran team to leverage across Fivetran dbt packages
- We do not recommend using this package outside of the Fivetran dbt packages

# What does this dbt package do?
This package includes macros that are used across Fivetran's dbt packages. This package is comprised primarily of cross database compatible macros and macros specific for dbt package maintenance. See the **Contents** below for the macros available within this package.

# How do I use the dbt package?
## Step 1: Installing the Package
Include the following fivetran_utils package version in your `packages.yml` if you do not have any other Fivetran dbt package dependencies. This package is installed by default within **all** Fivetran dbt packages.
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/fivetran_utils
    version: [">=0.4.0", "<0.5.0"]
```
## Step 2: Using the Macros
Call any of the below listed macros within the **Contents** section in your models. See the specific details for each macro below.

Additionally, in order to use macros from this package with other utility packages, you can set a [`dispatch` config](https://docs.getdbt.com/reference/project-configs/dispatch-config) in your root `dbt_project.yml`. For example:

```yml
dispatch:
  - macro_namespace: fivetran_utils
    search_order: ['spark_utils', 'fivetran_utils']
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'fivetran_utils', 'dbt_utils']
```

----
# Contents

- [Fivetran Utility Macros for dbt](#fivetran-utility-macros-for-dbt)
- [Who are the intended users of this package?](#who-are-the-intended-users-of-this-package)
- [What does this dbt package do?](#what-does-this-dbt-package-do)
- [How do I use the dbt package?](#how-do-i-use-the-dbt-package)
  - [Step 1: Installing the Package](#step-1-installing-the-package)
  - [Step 2: Using the Macros](#step-2-using-the-macros)
- [Contents](#contents)
  - [Tests and helpers](#tests-and-helpers)
  - [Cross-database compatibility](#cross-database-compatibility)
    - [json\_parse (source)](#json_parse-source)
    - [pivot\_json\_extract (source)](#pivot_json_extract-source)
    - [wrap\_in\_quotes (source)](#wrap_in_quotes-source)
  - [SQL and field generators](#sql-and-field-generators)
    - [add\_pass\_through\_columns (source)](#add_pass_through_columns-source)
    - [drop\_schemas\_automation (source)](#drop_schemas_automation-source)
    - [fill\_pass\_through\_columns (source)](#fill_pass_through_columns-source)
    - [fill\_staging\_columns (source)](#fill_staging_columns-source)
    - [persist\_pass\_through\_columns (source)](#persist_pass_through_columns-source)
    - [source\_relation (source)](#source_relation-source)
    - [apply\_source\_relation (source)](#apply_source_relation-source)
    - [partition\_by\_source\_relation (source)](#partition_by_source_relation-source)
    - [union\_connections (source)](#union_connections-source)
      - [Union Connections Defined Sources Configuration](#optional-union-connections-defined-sources-configuration)
    - [union\_data (source)](#union_data-source)
      - [Union Data Defined Sources Configuration](#union-data-defined-sources-configuration)
  - [Variable Checks](#variable-checks)
    - [empty\_variable\_warning (source)](#empty_variable_warning-source)
- [Does this package have dependencies?](#does-this-package-have-dependencies)
- [How is this package maintained and can I contribute?](#how-is-this-package-maintained-and-can-i-contribute)
  - [Package Maintenance](#package-maintenance)
  - [Contributions](#contributions)
- [Are there any resources available?](#are-there-any-resources-available)

----

## Tests and helpers
These macros help run or assist tests.
## Cross-database compatibility
These macros allow functions to prevail across different databases. 
### json_parse ([source](macros/json_parse.sql))
This macro allows for cross database use of the json extract function, specifically used to parse and extract a nested value from a json object.
The data is returned by the path you provide as the list within the `string_path` argument. The json_parse macro is compatible with BigQuery, Redshift, Postgres, Snowflake, DuckDB, and Databricks.

**Usage:**
```sql
{{ fivetran_utils.json_parse(string="receipt", string_path=["charges","data",0,"balance_transaction","exchange_rate"]) }}
```
**Args:**
* `string` (required): Name of the field which contains the json object.
* `string_path`  (required): List of item(s) that derive the path in the json object which you want to extract the data from.

----
### pivot_json_extract ([source](macros/pivot_json_extract.sql))
This macro builds off of the [`json_parse`](#json_parse-source) macro to extract a list of top-level fields from a JSON object and pivot the fields out into columns. The `pivot_json_extract` macro is compatible with every warehouse that `json_parse` supports.

**Usage:**
```sql
{{ fivetran_utils.pivot_json_extract(string="json_value", list_of_properties=["field 1", "field 2"]) }}
```
**Args:**
* `string` (required): Name of the field which contains the json object.
* `list_of_properties`  (required): List of the fields that you want to extract from the json object and pivot out into columns.

----
### wrap_in_quotes ([source](macros/wrap_in_quotes.sql))
This macro takes a single SQL object name (for example, a database, schema, or column) and returns it wrapped in your warehouse's quote characters using `adapter.quote`. On Snowflake, the macro uppercases the name before quoting it so it matches Snowflake's default uppercase identifiers. Pass one name at a time, not a full `database.schema.table` path.

**Usage:**
```sql
{{ fivetran_utils.wrap_in_quotes(object_to_quote="reserved_keyword_mayhaps") }}
```
**Args:**
* `object_to_quote` (required): SQL object you want to quote.
----
## SQL and field generators
These macros create SQL or fields to be included when running the package.
### add_pass_through_columns ([source](macros/add_pass_through_columns.sql))
This macro creates the proper name, datatype, and aliasing for user defined pass through column variable. This
macro allows for pass through variables to be more dynamic and allow users to alias custom fields they are 
bringing in. This macro is typically used within staging models of a fivetran dbt source package to pass through
user defined custom fields. Works for older and newer versions of passthrough columns.

**Usage:**
```sql
{{ fivetran_utils.add_pass_through_columns(base_columns=columns, pass_through_var=var('hubspot__deal_pass_through_columns')) }}
```
**Args:**
* `base_columns` (required): The name of the variable where the base columns are contained. This is typically `columns`.
* `pass_through_var` (required): The variable which contains the user defined pass through fields.

----

### drop_schemas_automation ([source](macros/drop_schemas_automation.sql))
This macro was created to help clean up the schemas in our integration test environments. It drops schemas that are `like` the `target.schema`. By default it will drop the target schema as well but this can be configured.

**Usage:**
At the end of a Buildkite integration test job in `.buildkite/scripts/run_models.sh`:
```sh
# do all the setup, dbt seed, compile, run, test steps beforehand...
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
```

As a Fivetran Transformation job step in a `deployment.yml`:
```yml
jobs:
 - name: cleanup
   schedule: '0 0 * * 0' # The example will run once a week at 00:00 on Sunday.
   steps:
    - name: drop schemas but leave target
      command: dbt run-operation fivetran_utils.drop_schemas_automation --vars '{"drop_target_schema": False}'
    - name: drop schemas including target
      command: dbt run-operation fivetran_utils.drop_schemas_automation
```
**Args:**
* `drop_target_schema` (optional): Boolean that is `true` by default. If `false`, the target schema will not be dropped.

----

### fill_pass_through_columns ([source](macros/fill_pass_through_columns.sql))
This macro is used to generate the correct sql for package staging models for user defined pass through columns. Works for older and newer versions of passthrough columns.

**Usage:**
```sql
{{ fivetran_utils.fill_pass_through_columns(pass_through_variable='hubspot__contact_pass_through_columns') }}
```
**Args:**
* `pass_through_variable` (required): Name of the variable which contains the respective pass through fields for the staging model.

----
### fill_staging_columns ([source](macros/fill_staging_columns.sql))
This macro generates the correct SQL for package staging models. It takes a list of expected columns (`staging_columns`) and compares them with the columns present in the source (`source_columns`). Missing columns are cast to `null` with the correct datatype.

**Usage:**
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
**Args:**
* `source_columns` (required): Calls [get_columns_in_relation](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter/#get_columns_in_relation) and requires a `ref()` or `source()` pointing to the `_tmp` staging model.
* `staging_columns` (required): The list of expected columns, typically returned by the package's `get_<table>_columns()` macro.

**Variables:**
* `fivetran_using_source_casing` (optional): Boolean variable, defaults to `false`. When `true`, the macro quotes lowercase column names as defined in the package's `get_*_columns` macros. For Snowflake targets, the alias is uppercased to match Snowflake identifier conventions.

> **Important:** `fivetran_using_source_casing` was added specifically to support Fivetran's MDLs feature where the Polaris engine lowercases column names in Snowflake destinations. It does not generically preserve source casing — it mainly handles the lowercase-in-Snowflake case. If Polaris's behavior changes in the future, a different approach may be required. See the [DECISIONLOG](DECISIONLOG.md) for full details.

----
### persist_pass_through_columns ([source](macros/persist_pass_through_columns.sql))
This macro is used to persist pass through columns from the staging model to the **transform** package. This is particularly helpful when a `select *` is not feasible.

**Usage:**
```sql
{{ fivetran_utils.persist_pass_through_columns(pass_through_variable='hubspot__contact_pass_through_columns', identifier='cte_name', transform='') }}
```
**Args:**
* `pass_through_variable` (required): Name of the variable which contains the respective pass through fields for the model.
* `identifier` (optional): Relation-identifier to prefix (followed by `'.'`) each column with (ie in case of ambiguous column join errors).
* `transform` (optional): SQL function you would like to apply to the passed through columns.

----
### source_relation ([source](macros/source_relation.sql))
This macro creates a new column that signifies with database/schema a record came from when using the `union_data` macro above. 
It should be added to all non-tmp staging models when using the `union_data` macro. 

**Usage:**
```sql
{{ fivetran_utils.source_relation() }}
```

**Args:**
* `union_schema_variable` (optional): The name of the union schema variable. By default the macro will look for `union_schemas`.
* `union_database_variable` (optional): The name of the union database variable. By default the macro will look for `union_databases`.

----
### apply_source_relation ([source](macros/apply_source_relation.sql))
This macro generates the `source_relation` column in non-tmp staging models. It automatically selects the right approach based on how a package is configured for unioning:
- If `{package_name}_sources` is set (new-style `union_connections`): returns `database.schema` from `_dbt_source_relation`. It removes quote characters and drops the table name, so it works with either value `dbt_utils.union_relations` returns: `database.schema` (with `include_table_in_source_column=false`, as `union_connections` calls it) or the default `"database"."schema"."table"`.
- If `{package_name}_union_schemas` or `{package_name}_union_databases` is set: calls `fivetran_utils.source_relation()` with the appropriate variable names.
- If none of the above: generates a static `database.schema` string cast as `source_relation`.

**Usage:**
```sql
{{ fivetran_utils.apply_source_relation(package_name='jira') }}
```
**Args:**
* `package_name` (required): The name of the package. Used to derive the variable names for sources, database, schema, and union schemas/databases.
* `use_package_prefix` (optional): Boolean, defaults to `true`. When `true`, prefixes the union variable names with `package_name` (e.g., `jira_union_schemas`). When `false`, uses generic variable names (`union_schemas`, `union_databases`).

----
### partition_by_source_relation ([source](macros/partition_by_source_relation.sql))
This macro conditionally generates a `partition by source_relation` or `, source_relation` addition to a window function's partition clause. It returns an empty string when not unioning, so you can include it in every model without needing conditional logic in your SQL.

**Usage:**
```sql
-- Adding source_relation to an existing partition clause
select
    id,
    first_value(amount) over (partition by id {{ fivetran_utils.partition_by_source_relation('jira') }} order by created_at) as first_amount
from my_cte

-- Starting a new partition clause with source_relation only
select
    id,
    row_number() over ({{ fivetran_utils.partition_by_source_relation('jira', has_other_partitions='no') }} order by created_at) as row_num
from my_cte
```
**Args:**
* `package_name` (required): The name of the package. Used to derive the union variable names.
* `has_other_partitions` (optional): Defaults to `'yes'`. When `'yes'`, prepends `, source_relation` to add to an existing partition. When `'no'`, generates the full `partition by source_relation` clause.
* `alias` (optional): A CTE or relation alias to prefix `source_relation` (e.g., produces `alias.source_relation`).
* `package_prefix_union_variable` (optional): Boolean, defaults to `true`. When `true`, prefixes union variable names with `package_name`. When `false`, uses generic names (`union_schemas`, `union_databases`).

----
### union_connections ([source](macros/union_connections.sql))
This macro unions identically structured tables across multiple Fivetran connections of the same type. It reads from a connection dictionary variable (e.g. `jira_sources`) listing each connection's `database`, `schema`, and `name` (optional), and falls back to a single-connection query if the variable is empty.

If the source table is not found, `union_connections` will return a **completely** empty table (ie `limit 0`) with just one string column (`_dbt_source_relation`). A compiler warning message will be output, highlighting that the expected source table was not found and its respective staging model is empty. The compiler warning can be turned off by setting the `fivetran__remove_empty_table_warnings` variable to `True`.

For example, in `dbt_jira` the connection dictionary is set as `jira_sources`, and then can be defined in your root `dbt_project.yml`:
```yml
vars:
  jira:
    jira_sources:
      - database: connection_1_destination_name
        schema: connection_1_schema_name
        name: connection_1_source_name # optional, use only if `has_defined_sources` is true 
      - database: connection_2_destination_name
        schema: connection_2_schema_name
        name: connection_2_source_name # optional, use only if `has_defined_sources` is true
```

**Usage:**
```sql
-- in _tmp model
{{
    fivetran_utils.union_connections(
        connection_dictionary='jira_sources',
        single_source_name='jira',
        single_table_name='issue'
    )
}}
```
**Args:**
* `connection_dictionary`: The name of the variable containing the list of connection objects to union. Each object supports `database` (defaults to `target.database`), `schema` (defaults to `single_source_name`), and `name` (required only if `has_defined_sources` is true).
* `single_source_name`: The source name to use when not unioning (i.e. when `connection_dictionary` is empty).
* `single_table_name`: The name of the table to query.
* `default_identifier` (optional): Override for the table identifier. Defaults to `single_table_name`.

#### Optional: Union Connections Defined Sources Configuration
By default, packages using this macro define one single-connection source which will be disabled if you are unioning multiple connections. This means your DAG will not include your sources, though the package will run successfully.

To incorporate all of your connections into your project's DAG:

1. Define each of your sources in a `.yml` file in your project. Copy the table and column-level definitions from the package's `src_<package>.yml` file into the `tables:` key below. **Important:** Make sure to remove any enable/disable configs from the `.yml` file to avoid errors.

```yml
# in a root-project schema.yml file (ex. models/src_jira.yml)
version: 2

sources:
  - name: connection_source # must match name in <package>_sources
    schema: connection_schema
    database: connection_database
    loader: Fivetran
    loaded_at_field: _fivetran_synced
    freshness: # feel free to adjust to your liking
      warn_after: {count: 72, period: hour}
      error_after: {count: 168, period: hour}
    tables: # copy and paste from <package>/models/staging/src_<package>.yml
```

**Note:** If there are source tables you do not have, you may still include them as long as you disable the relevant variables by setting them to `false`.

2. Set `has_defined_sources` to `true` in your `dbt_project.yml`:

```yml
# dbt_project.yml
vars:
  <package_name>:
    has_defined_sources: true
```

----
### union_data ([source](macros/union_data.sql))
This macro unions together tables of the same structure so that users can treat data from multiple connectors as the 'source' to a package.
Depending on which macros are set, it will either look for schemas of the same name across multiple databases, or schemas with different names in the same database.

If the `var` with the name of the `schema_variable` argument is set, the macro will union the `table_identifier` tables from each respective schema within the target database (or source database if set by a variable).
If the `var` with the name of the `database_variable` argument is set, the macro will union the `table_identifier` tables from the source schema in each respective database.

When using this functionality, every `_tmp` table should use this macro as described below.

To create dependencies between the unioned model and its *sources*, you **must define** the source tables in a `.yml` file in your project and set the `has_defined_sources` variable (scoped to the source package in which the macro is being called) to `True` in your `dbt_project.yml` file. If you set `has_defined_sources` to true and do not define sources (at least adding the `name` of each table in the source), dbt will throw an error. Please see the below [Union Data Defined Sources Configuration](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union-data-defined-sources-configuration) section for details on how to configure this ability in your project.

If the source table is not found in any of the provided schemas/databases, `union_data` will return a **completely** empty table (ie `limit 0`) with just one string column (`_dbt_source_relation`). A compiler warning message will be output, highlighting that the expected source table was not found and its respective staging model is empty. The compiler warning can be turned off by the end user by setting the `fivetran__remove_empty_table_warnings` variable to `True`.

**Usage:**
```sql
-- in model.sql file
{{
    fivetran_utils.union_data(
        table_identifier='customer', 
        database_variable='shopify_database', 
        schema_variable='shopify_schema', 
        default_database=target.database,
        default_schema='shopify',
        default_variable='customer_source'
    )
}}
```
**Args:**
* `table_identifier`: The name of the table that will be unioned. This maps onto the table's `name` as it is defined in the `src.yml` file, _not_ the `identifier`.
* `database_variable`: The name of the variable that users can populate to union data from multiple databases.
* `schema_variable`: The name of the variable that users can populate to union data from multiple schemas.
* `default_database`: The default database where source data should be found. This is used when unioning schemas.
* `default_schema`: The default schema where source data should be found. This is used when unioning databases.
* `default_variable`: The name of the variable that users should populate when they want to pass one specific relation to this model (mostly used for CI)
* `union_schema_variable` (optional): The name of the union schema variable. By default the macro will look for `union_schemas`.
* `union_database_variable` (optional): The name of the union database variable. By default the macro will look for `union_databases`.

#### Union Data Defined Sources Configuration
```yml
# in root dbt_project.yml file
vars:
  shopify_source:
    has_defined_sources: true
  
  fivetran__remove_empty_table_warnings: true # false by default
```

```yml
# in a root-project schema.yml file 
version: 2

sources:
  - name: shopify_us
    schema: shopify_us
    database: "{{ var('shopify_database', target.database) }}"
    loader: Fivetran
    loaded_at_field: _fivetran_synced
    tables:
      - name: account
      - name: customer 
      ...
  
  - name: shopify_mx
    schema: shopify_mx
    database: "{{ var('shopify_database', target.database) }}"
    loader: Fivetran
    loaded_at_field: _fivetran_synced
    tables:
      - name: account
      - name: customer 
      ...
```
----

## Variable Checks
These macros tests if a variable meets given conditions.
### empty_variable_warning ([source](macros/empty_variable_warning.sql))
This macro checks a declared variable and returns an error message if the variable is empty before running the models within the `dbt_project.yml` file.

**Usage:**
```yml
on-run-start: '{{ fivetran_utils.empty_variable_warning(variable="ticket_field_history_columns", downstream_model="zendesk_ticket_field_history") }}'
```
**Args:**
* `variable`            (required): The variable you want to check if it is empty.
* `downstream_model`    (required): The downstream model that is affected if the variable is empty.

----