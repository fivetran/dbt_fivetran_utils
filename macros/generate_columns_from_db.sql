{% macro generate_columns_from_db(table_name, schema_name) %}

{% set query %}

select
    concat(
      '{"name": "', 
      lower(column_name), 
      '", "datatype": ',
      case
        when lower(data_type) like '%timestamp%' then 'dbt_utils.type_timestamp()' 
        when lower(data_type) = 'text' then 'dbt_utils.type_string()' 
        when lower(data_type) = 'boolean' then '"boolean"'
        when lower(data_type) = 'number' then 'dbt_utils.type_numeric()' 
        when lower(data_type) = 'float' then 'dbt_utils.type_float()' 
      end,
      '}')
from raw.information_schema.columns
where lower(table_name) = '{{ table_name }}'
and lower(table_schema) = '{{ schema_name }}'
order by 1

{% endset %}

{% set results = run_query(query) %}
{% set results_list = results.columns[0].values() %}

{% set jinja_macro=[] %}

{% do jinja_macro.append('{% macro get_' ~ table_name ~ '_columns() %}') %}
{% do jinja_macro.append('') %}
{% do jinja_macro.append('{% set columns = [') %}

{% for result in results_list %}
{% do jinja_macro.append('    ' ~ result ~ (',' if not loop.last)) %}
{% endfor %}

{% do jinja_macro.append('] %}') %}
{% do jinja_macro.append('') %}
{% do jinja_macro.append('{{ return(columns) }}') %}
{% do jinja_macro.append('') %}
{% do jinja_macro.append('{% endmacro %}') %}

{% if execute %}

    {% set joined = jinja_macro | join ('\n') %}
    {{ log(joined, info=True) }}
    {% do return(joined) %}

{% endif %}

{% endmacro %}