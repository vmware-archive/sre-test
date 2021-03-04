#!/bin/bash
#Create this table (create table public.tab_lock as select * from generate_series (1,100000000);), before running this script
echo '========================Start of test===================='


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


echo '====================== Start the backup while try running DDL on the same DB it should create a lock ======================'

nohup gpbackup --dbname gpadmin > backup_lock_test.log 2>&1 &

sleep 30

echo '========================DDL statement to test for lock===================='

nohup psql -c "drop table public.tab_lock;" > tab_lock.log 2>&1 &

psql -c "select * from pg_stat_activity where waiting = 't';"

echo '========================end of test===================='

