{% macro median(median_field, partition_field, percent=0.5) -%}

{{ adapter.dispatch('median', packages = fivetran_utils._get_utils_namespaces()) (median_field, partition_field, percent) }}

{%- endmacro %}

--Default median calculation
{% macro default__median(median_field, partition_field) %}

    median( 
        {{ median_field }})
        over (partition by {{ partition_field }}    
        )

{% endmacro %}

--Median calculation specific to BigQuery
{% macro bigquery__median(median_field, partition_field, percent=0.5)  %}

    percentile_cont( 
        {{ median_field }}, 
        {{ percent }}) 
        over (partition by {{ partition_field }}    
        )

{% endmacro %}