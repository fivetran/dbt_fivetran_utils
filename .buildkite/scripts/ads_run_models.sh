#!/bin/bash

## remove failure for testing
# set -euo pipefail

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

packages=('twitter_ads')

for model in "${packages[@]}"
do
    cd dbt_packages/$model/integration_tests
    dbt deps
    cp ../../../packages_ft_utils_override.yml packages.yml
    echo "compiling "$model""
    dbt seed --target "$db"
    dbt compile --target "$db"
    dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
    cd ../../../
done
