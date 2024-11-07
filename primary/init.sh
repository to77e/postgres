#!/bin/bash
set -e

cat >> $PGDATA/pg_hba.conf << EOL
host replication replicator 0.0.0.0/0 scram-sha-256
EOL

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
  CREATE USER $POSTGRES_REPLICA_USER WITH REPLICATION ENCRYPTED PASSWORD '$POSTGRES_REPLICA_PASSWORD';
  SELECT pg_create_physical_replication_slot('test');
EOSQL

wget -O /tmp/thai_small.tar.gz https://storage.googleapis.com/thaibus/thai_small.tar.gz
cd /tmp
tar -xf thai_small.tar.gz
psql -v ON_ERROR_STOP=1 -U $POSTGRES_USER -d $POSTGRES_DB -f thai.sql







