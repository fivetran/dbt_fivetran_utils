# Decision Log

## Why `fivetran_using_source_casing` quotes lowercase column names instead of preserving source casing

The `fivetran_using_source_casing` variable in `fill_staging_columns` was added to support Fivetran's Managed Data Lake Service, where column names are stored as lowercase in the Iceberg layer. When querying these tables from Snowflake via the Polaris catalog, which treats unquoted identifiers as uppercase by default, those lowercase column names must be quoted to be referenced correctly.

When `fivetran_using_source_casing` is set to `true`, the macro quotes column names as defined in the package's `get_*_columns` macros (which use lowercase). For Snowflake targets, the alias is uppercased to match Snowflake's identifier conventions. For all other warehouses, the lowercase alias is used as-is.

This variable does not truly preserve source casing — it specifically handles the lowercase-in-Snowflake case introduced by Polaris. This approach made the most sense at the time given that Polaris's future plans are unknown. If Polaris begins writing quoted uppercase column names in Snowflake in the future, a different approach will be required.
