# dbt_fivetran_utils v0.3.9
## 🎉 Features 🎉 
- Addition of the `transform` argument to the `persist_pass_through_columns` macro. This argument is optional and will take in a SQL function (most likely an aggregate such as `sum`) you would like to apply to the passthrough columns ([81](https://github.com/fivetran/dbt_fivetran_utils/pull/81)).

# dbt_fivetran_utils v0.3.8
## Bug Fixes
- Adjustment within the `try_cast` macro to fix an error witch ocurred within Snowflake warehouses. ([#79](https://github.com/fivetran/dbt_fivetran_utils/pull/79))

## Under the Hood
- Removes automation macros used only by the Fivetran dbt package team when developing new dbt packages. These macros are not needed within the utility package for access by all Fivetran dbt packages. ([#79](https://github.com/fivetran/dbt_fivetran_utils/pull/79))
    - As a result of the above, these automations were removed and re-located to our Fivetran team's automations repo.

# dbt_fivetran_utils v0.3.7
- Rollback of the v0.3.6 release that introduced a bug for Snowflake users.
# dbt_fivetran_utils v0.3.6
## 🎉 Features 🎉 
- New macro `get_column_names_only` that further automates the staging model creation to prefill column fields in the final select statement. 
- Updated bash script `generate_models` to incorporate this new macro.
# dbt_fivetran_utils v0.3.5
## 🎉 Features 🎉 
- The `try_cast` macro has been added. This macro will try to cast the field to the specified datatype. If it cannot be cast, then a `null` value is provided. Please note, Postgres and Redshift destinations are only compatible with try_cast and the numeric datatype.
# dbt_fivetran_utils v0.3.4
## 🎉 Features 🎉 
Added a new macro called `generate_docs` which returns a `source` command leveraging `generate_docs.sh` to do the following:
- seeds, runs and creates documentation for integration tests models
- moves `catalog.json`, `index.html`, `manifest.json` and `run_results.json` into a `<project_name>/docs` folder

When ran, this feature will remove existing files in the `<project_name>/docs` if any exists.

# dbt_fivetran_utils v0.3.3

## Updates
([#63](https://github.com/fivetran/dbt_fivetran_utils/pull/63/files)) This release of the `dbt_fivetran_utils` package includes the following updates to the README:
- Add a Table of Contents to allow for quicker searches.
- Leverage new Categories to better organize macros.
- Update the `staging_models_automation` macro to reflect usage of the new `generate_columns.sh` and `generate_models.sh` scripts. 
- Update the `generate_models.sh` script to create the models/macros folders if empty or replace any existing content in the models/macros folders.
# dbt_fivetran_utils v0.3.2
## Fixes
- The `collect_freshness` macro was inadvertently causing non-package source freshness tests that were aliased with the `identifier` config to use the current date opposed to the loaded date. Therefore, the macro was adjusted to leverage the table identifier opposed to the name. As the identifier is the name of the table by default, this should resolve the error. ([#56](https://github.com/fivetran/dbt_fivetran_utils/pull/56))
# dbt_fivetran_utils v0.3.1
## Bug Fixes
- Updates `staging_models_automation` macro to refer to dbt_packages instead of dbt_modules re: dbt v1.0.0 updates
- Updates `staging_models_automation` macro to first create `macros/get_<table name>_columns`.sql files before creating `models/tmp` and `models/stg*`
- Incorporates fix for bignumeric data type in `get_columns_for_macro`
- Updates `README` to reflect new `.sh` files added for updated `staging_models_automation` macro

# dbt_fivetran_utils v0.3.0
## 🎉 Features 🎉
- dbt v1.0.0 compatibility release! All future release of fivetran/fivetran_utils compatible with dbt v1.0.0 will be based on the `releases/v0.3.latest`. ([#54](https://github.com/fivetran/dbt_fivetran_utils/pull/54))

## 🚨 Breaking Changes 🚨
- This release updates the dbt-utils `packages.yml` dependency to be within the `">=0.8.0", "<0.9.0"` range. If you have a dbt-utils version outside of this range then you will experience a package dependency error. ([#54](https://github.com/fivetran/dbt_fivetran_utils/pull/54))


# dbt_fivetran_utils v0.2.10
## Bug Fixes
- Added a `dbt_utils.type_string()` cast to the `source_relation` macro. There were accounts of failures occurring within Redshift where the casting was failing in downstream models. This will remedy those issues by casting on field creation if multiple schemas/databases are not provided. ([#53](https://github.com/fivetran/dbt_fivetran_utils/pull/53))

# dbt_fivetran_utils v0.2.9

## Bug Fixes
- Added a specific Snowflake macro designation for the `json_extract_path` macro. ([#50](https://github.com/fivetran/dbt_fivetran_utils/pull/50))
    - This Snowflake version of the macro includes a `try_parse_json` function within the `json_extract_path` function. This allows for the macro to succeed if not all fields are a json object that are being passed through. If a field is not a json object, then a `null` record is generated. 
- Updated the Redshift macro designation for the `json_extract_path` macro. ([#50](https://github.com/fivetran/dbt_fivetran_utils/pull/50))
    - Similar to the above, Redshift cannot parse the field if every record is not a json object. This update converts a non-json field to `null` so the function does not fail.

## Under the Hood
- Included a `union_schema_variable` and a `union_database_variable` which will allow the `source_relation` and `union_data` macros to be used with varying variable names. ([#49](https://github.com/fivetran/dbt_fivetran_utils/pull/49))
    - This allows for dbt projects that are utilizing more than one dbt package with the union source feature to have different variable names and not see duplicate errors.
    - This change needs to be applied at the package level to account for the variable name change. If this is not set, the macros looks for either `union_schemas` or `union_databases` variables.

# dbt_fivetran_utils v0.2.8

## Features
- Added this changelog to capture iterations of the package!
- Added the `add_dbt_source_relation()` macro, which passes the `dbt_source_relation` column created by `union_data()` to `source_relations()` in package staging models. See the README for more details on its appropriate usage.
