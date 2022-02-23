#!/bin/bash
FILES=('catalog.json' 'index.html' 'manifest.json' 'run_results.json')
PKG='dbt_apple_search_ads_source'
ORIG_DIR=$PWD

for file in ${FILES[@]}; do 
    echo "${PKG}/integration_tests/target"$file 
    echo "${PKG}/docs/"$file
done 

echo $ORIG_DIR