{% macro timestamp_diff(first_date, second_date, datepart) %}
  {{ adapter.dispatch('datediff', packages = zendesk._get_utils_namespaces())(first_date, second_date, datepart) }}
{% endmacro %}


{% macro default__timestamp_diff(first_date, second_date, datepart) %}

    datediff(
        {{ datepart }},
        {{ first_date }},
        {{ second_date }}
        )

{% endmacro %}


{% macro bigquery__timestamp_diff(first_date, second_date, datepart) %}

    timestamp_diff(
        {{second_date}},
        {{first_date}},
        {{datepart}}
    )

{% endmacro %}