#!/bin/bash

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
rm package-lock.yml
echo -e "removing package-lock.yml"

shift ## Skips the first argument (warehouse) and moves to only looking at the package arguments

for package in "$@" ## Iterates over all non warehouse arguments
do
    echo -e "\ncompiling "$package"\n"
    cd dbt_packages/$package/integration_tests/
    dbt clean
    dbt deps
    rm package-lock.yml
    echo -e "removing package-lock.yml"
    cp ../../../packages_ft_utils_override.yml packages.yml
    dbt deps
    rm package-lock.yml
    echo -e "removing package-lock.yml"
    if [ "$package" = "linkedin" ]; then
        value_to_replace=$(grep ""$package"_ads_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    elif [ "$package" = "ad_reporting" ]; then
        value_to_replace=$(grep "google_ads_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    elif [ "$package" = "app_reporting" ]; then
        value_to_replace=$(grep "google_play_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    elif [ "$package" = "shopify_holistic_reporting" ]; then
        value_to_replace=$(grep "shopify_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    elif [ "$package" = "social_media_reporting" ]; then
        perl -i -pe "s/(schema: |dataset: ).*/\1social_media_rollup_integration_tests/" ~/.dbt/profiles.yml
    elif [ "$package" = "fivetran_log" ]; then
        value_to_replace=$(grep "fivetran_platform_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    else
        value_to_replace=$(grep ""$package"_schema:" dbt_project.yml | awk '{ print $2 }')
        perl -i -pe "s/(schema: |dataset: ).*/\1$value_to_replace/" ~/.dbt/profiles.yml
    fi
    dbt seed --target "$db"
    dbt run --target "$db"
    dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
    cd ../../../
done