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

# Postgres runs in a disposable local container instead of a shared, credentialed
# instance -- avoids cross-build connection contention on the shared CI instance.
# Requires the docker socket to be mounted into this step's container, and this
# step's container to be joined to the "fivetran_utils_pg_ci" docker network (set
# via the `network` option on the docker#v3.13.0 plugin in pipeline.yml), so the
# sibling postgres container below is reachable by name over that network.
install_docker_cli() {
    # The docker.io apt package on Debian bookworm ships a client too old
    # (API 1.41) for the CI host's Docker daemon (requires API >= 1.44).
    # Install a current static client instead -- it negotiates the API
    # version with whatever daemon it talks to, so this isn't version-pinned
    # to the host.
    command -v docker > /dev/null 2>&1 && return
    arch="$(uname -m)"
    curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-27.3.1.tgz" -o /tmp/docker.tgz
    tar -xzf /tmp/docker.tgz -C /tmp
    mv /tmp/docker/docker /usr/local/bin/docker
    rm -rf /tmp/docker /tmp/docker.tgz
}

start_postgres_container() {
    install_docker_cli
    container_name="pg_ci_${BUILDKITE_JOB_ID:-local}"
    echo "Starting containerized Postgres (${container_name})..."
    docker run -d --name "$container_name" \
        --network fivetran_utils_pg_ci \
        -e POSTGRES_HOST_AUTH_METHOD=trust \
        postgres:15

    echo "Waiting for Postgres to become ready..."
    for _ in $(seq 1 30); do
        if docker exec "$container_name" pg_isready -U postgres > /dev/null 2>&1; then
            echo "Postgres container is ready"
            perl -i -pe "s/(host: ).*/\1$container_name/" ~/.dbt/profiles.yml
            perl -i -pe "s/(user: ).*/\1postgres/" ~/.dbt/profiles.yml
            perl -i -pe 's/(pass: ).*/\1""/' ~/.dbt/profiles.yml
            perl -i -pe "s/(dbname: ).*/\1postgres/" ~/.dbt/profiles.yml
            return 0
        fi
        sleep 1
    done

    echo "ERROR: Postgres container did not become ready in time"
    docker logs "$container_name" || true
    exit 1
}

stop_postgres_container() {
    docker rm -f "$container_name" > /dev/null 2>&1 || true
}

if [ "$db" = "postgres" ]; then
    start_postgres_container
    trap stop_postgres_container EXIT
fi

echo `pwd`
cd integration_tests

## Point every fivetran hub package in packages.yml to its MagicBot/duckdb-support branch instead of the published version, so this run tests against the in-progress DuckDB support code.
perl -0777 -i -pe 's/^([ ]*)- package: fivetran\/(\S+)\n\s*version: \[.*?\]/$1- git: https:\/\/github.com\/fivetran\/dbt_$2.git\n$1  revision: MagicBot\/duckdb-support/mg' packages.yml

dbt deps ## Install all packages needed

shift ## Skips the first argument (warehouse) and moves to only looking at the package arguments

for package in "$@" ## Iterates over all non warehouse arguments
do
    echo -e "\ncompiling "$package"\n"
    cd dbt_packages/$package/integration_tests/
    dbt deps
    ## Post dbt 1.7.0 we need to edit the package-lock.yml instead of the packages.yml
    awk '/name: fivetran_utils/ {print "  - local: ../../../../\n    name: fivetran_utils"; skip=1; next} skip && /^  -/ {skip=0} !skip' package-lock.yml > temp.yml && mv temp.yml package-lock.yml
    dbt deps
    fivetran_utils_version=$(grep "^version:" dbt_packages/fivetran_utils/dbt_project.yml | awk '{print $2}')
    echo -e "\nUsing fivetran_utils version: "$fivetran_utils_version"\n"
    cat package-lock.yml  # before and after the awk, diff the two TEMP

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
    dbt seed --target "$db" --full-refresh
    if [ "$package" = "ad_reporting" ]; then
        dbt run --target "$db" --vars '{ad_reporting__facebook_ads_enabled: true, facebook_ads__using_demographics_country: true, facebook_ads__using_demographics_region: true, ad_reporting__google_ads_enabled: true, ad_reporting__amazon_ads_enabled: false, ad_reporting__apple_search_ads_enabled: false, ad_reporting__linkedin_ads_enabled: true, ad_reporting__microsoft_ads_enabled: false, ad_reporting__pinterest_ads_enabled: false, ad_reporting__reddit_ads_enabled: false, ad_reporting__snapchat_ads_enabled: false, ad_reporting__tiktok_ads_enabled: false, ad_reporting__twitter_ads_enabled: false}'
    else
        dbt run --target "$db"
    fi
    dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
    cd ../../../
done