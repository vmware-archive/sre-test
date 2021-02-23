#!/bin/bash

echo '========================Start of test===================='


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


echo '====================== Start the backup while try running DDL on the same DB it should create a lock ======================'

nohup gpbackup --dbname gpadmin > backup.log 2>&1 &

sleep 30

echo '========================DDL statement to test for lock===================='

nohup psql -f drop_tab.sql > drop_tab.log 2>&1 &

psql -c "select * from pg_stat_activity where waiting = 't';"

echo '========================end of test===================='

