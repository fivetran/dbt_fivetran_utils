#!/bin/bash
ORIG_DIR=$(echo $PWD)
PKG=$(echo $1)
cd ${PKG}/integration_tests
dbt clean && dbt deps && dbt seed
dbt docs generate
FILES=('catalog.json' 'index.html' 'manifest.json' 'run_results.json')

{
    rm -r "../docs"
} || {
    echo "Directory does not yet exist. Creating directory ..."
}

mkdir "../docs"
for file in ${FILES[@]}; do 
    mv "target/"$file "../docs/"
done

dbt clean 

cd $ORIG_DIR