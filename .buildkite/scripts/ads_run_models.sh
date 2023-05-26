#!/bin/bash

## remove failure for testing
set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps ## Install all packages needed

shift ## Skips the first argument (warehouse) and moves to only looking at the data model arguments

for model in "$@" ## Iterates over all non warehouse arguments
do
    echo -e "\ncompiling "$model"\n"
    cd dbt_packages/$model/integration_tests/
    dbt deps
    cp ../../../packages_ft_utils_override.yml packages.yml
    dbt deps
    if [$model = "linkedin"]; then
        value_to_replace=$(grep ""$model"_ads_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    else
        value_to_replace=$(grep ""$model"_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    fi
    dbt seed --target "$db"
    dbt run --target "$db"
    dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
    cd ../../../
done