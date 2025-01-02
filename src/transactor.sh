#!/usr/bin/env bash


mkdir log/ 2>/dev/null
mkdir data/ 2>/dev/null


sed s'|$PWD|'$(pwd)'|g' transactor.properties > transactor.out.properties
# ^^ Needed because the transactor startup script changes current working directory
# and thus we need to provide the full path

transactor "$(pwd)/transactor.out.properties"

