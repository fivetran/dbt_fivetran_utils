{% macro add_pass_through_columns(base_columns, pass_through_var) %}

  {% if pass_through_var %}

    {% for column in pass_through_var %}

      {% do base_columns.append({ "name": column.name, "alias": column.alias }) if column.alias else base_columns.append({ "name": column.name }) %}

    {% endfor %}

  {% endif %}

{% endmacro %}