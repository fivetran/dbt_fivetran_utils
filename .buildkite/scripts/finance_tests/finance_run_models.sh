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
mv packages.yml packages_ft_pkgs.yml && mv packages_ft_utils_override.yml packages.yml

## To rename files back to original names for local testing
## mv packages.yml packages_ft_utils_override.yml && mv packages_ft_pkgs.yml packages.yml 

dbt deps ## To override initial fivetran_utils package
echo 'Compiling QuickBooks'
dbt compile --target "$db" --select tag:quickbooks
