#!/bin/bash
set -e

PGHOME=$(getent passwd postgres | cut -d: -f6)

cat >> $PGHOME/.pgpass << EOL
$POSTGRES_PRIMARY_HOST:$POSTGRES_PORT:*:$POSTGRES_REPLICA_USER:$POSTGRES_REPLICA_PASSWORD
EOL

chmod 600 $PGHOME/.pgpass

export PGPASSFILE="$PGHOME/.pgpass"
