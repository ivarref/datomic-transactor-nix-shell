#!/usr/bin/env bash

set -euo pipefail

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

TRANSACTOR_PROPERTIES="$(pwd)/transactor/transactor.properties"
TRANSACTOR_OUT_PROPERTIES="$(pwd)/transactor/transactor.out.properties"

if [ ! -e "$TRANSACTOR_PROPERTIES" ]; then
  # https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr#23550347
  >&2 echo "File ./transactor/transactor.properties ($TRANSACTOR_PROPERTIES) does not exist. Exiting."
  exit 1
fi

sed s":\$PWD:$(pwd):g" "$TRANSACTOR_PROPERTIES" > "$TRANSACTOR_OUT_PROPERTIES"
# ^^ Needed because the transactor startup script changes current working directory
# and thus we need to provide the full path

#echo "sqlite3 is: $(which sqlite3)"
# Taken from https://github.com/filipesilva/datomic-pro-sqlite/blob/master/image/start.sh
# Create sqlite db if it doesn't exist
if [ ! -f "./transactor/storage/sqlite.db" ]; then
  echo "Creating sqlite database at ./transactor/storage/sqlite.db"
  sqlite3 ./transactor/storage/sqlite.db "
-- same as Rails 8.0
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA mmap_size = 134217728; -- 128 megabytes
PRAGMA journal_size_limit = 67108864; -- 64 megabytes
PRAGMA cache_size = 2000;

-- datomic schema
CREATE TABLE datomic_kvs (
    id TEXT NOT NULL,
    rev INTEGER,
    map TEXT,
    val BYTEA,
    CONSTRAINT pk_id PRIMARY KEY (id)
);
" > /dev/null
fi

#echo $PATH | tr ':' '\n' | sort

#echo $PATH | tr ':' '\n' | sort | grep 'datomic-transactor-' | grep -v 'nix-shell' | sed 's|/bin||g'

#ls -l "$(echo $PATH | tr ':' '\n' | sort | grep 'datomic-transactor-' | grep -v 'nix-shell' | sed 's|/bin||g')/lib" | grep sqlite

echo "shell is: $(which shell)"
echo "nc is: $(which nc)"
echo "kill is: $(which kill)"

#shell

transactor "$TRANSACTOR_OUT_PROPERTIES" &
TRANSACTOR_PID="$!"

# wait max five minutes
ATTEMPTS=3000
echo "Waiting for 127.0.0.1:4334 (datomic transactor) to open ..."

while [ ! "$ATTEMPTS" -eq 0 ]; do
  if nc -z 127.0.0.1 4334 > /dev/null 2>&1; then
    break
  else
    sleep 0.1 # wait for 1/10 of the second before check again
    ((ATTEMPTS--))
    if ! kill -0 "$TRANSACTOR_PID" > /dev/null 2>&1; then
      echo "Waiting for 127.0.0.1:4334 (datomic transactor) to open ... ERROR!"
      echo "Datomic transactor unexpectedly exited. Exiting."
      exit 1
    fi
    if [[ "$ATTEMPTS" == "0" ]]; then
      echo "Waiting for 127.0.0.1:4334 (datomic transactor) to open ... TIMEOUT!"
      echo "Timed out waiting for datomic transactor to start. Exiting."
      exit 1
    fi
  fi
done

echo "Waiting for 127.0.0.1:4334 (datomic transactor) to open ... OK!"

wait "$(jobs -p)"