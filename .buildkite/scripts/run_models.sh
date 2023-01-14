#!/bin/bash

set -euo pipefail

# https://github.com/mikefarah/yq#on-ubuntu-1604-or-higher-from-debian-package
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
add-apt-repository ppa:rmescandon/yq
apt-get update
apt-get install libsasl2-dev
apt-get install yq -y

python3 -m venv venv
. venv/bin/activate
# brew install yq
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
yq e -i '.name = "fivetran_utils_test"' dbt_project.yml
cd integration_tests
dbt deps
dbt compile --select tag:ad_reporting
dbt compile --select tag:zendesk
dbt compile --select tag:hubspot
dbt compile --select tag:netsuite
dbt compile --select tag:jira
# yq e -i '.name = "fivetran_utils"' dbt_project.yml


