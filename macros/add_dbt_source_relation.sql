{% macro add_dbt_source_relation() %}
{# This is a fix for use in the xero_source package, which is the only package that uses this macro. 
To be deprecated in v0.5.0 of fivetran_utils. #}
, _dbt_source_relation

{% endmacro %}