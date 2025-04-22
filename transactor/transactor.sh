#!/usr/bin/env bash

sed s'|$PWD|'$(pwd)'|g' "$(pwd)/transactor/transactor.properties" > "$(pwd)/transactor/transactor.out.properties"
# ^^ Needed because the transactor startup script changes current working directory
# and thus we need to provide the full path

echo $PATH | tr ':' '\n' | sort | grep 'datomic-transactor-' | grep -v 'nix-shell' | sed 's|/bin||g'

ls -l "$(echo $PATH | tr ':' '\n' | sort | grep 'datomic-transactor-' | grep -v 'nix-shell' | sed 's|/bin||g')/lib"

#transactor "$(pwd)/transactor/transactor.out.properties"

