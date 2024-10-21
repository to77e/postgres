#!/bin/bash

wget -O /tmp/thai_small.tar.gz https://storage.googleapis.com/thaibus/thai_small.tar.gz
cd /tmp
tar -xf thai_small.tar.gz
psql -U $POSTGRES_USER -d $POSTGRES_DB -f thai.sql