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
dbt deps
mv packages.yml packages_ft_pkgs.yml
mv packages_ft_utils_override.yml packages.yml
## for local testing
## mv packages.yml packages_ft_utils_override.yml && mv packages_ft_pkgs.yml packages.yml 

dbt deps
# echo 'Compiling Ad Reporting...'
# dbt compile --target "$db" --select tag:ad_reporting

# echo 'Compiling Zendesk'
# dbt compile --target "$db" --select tag:zendesk

# echo 'Compiling Hubspot'
# dbt compile --target "$db" --select tag:hubspot

echo 'Compiling Netsuite'
dbt compile --target "$db" --select tag:netsuite

echo 'Compiling Jira'
dbt compile --target "$db" --select tag:jira

