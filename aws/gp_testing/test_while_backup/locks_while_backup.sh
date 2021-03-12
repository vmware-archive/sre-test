#!/bin/bash
#Create this table (create table public.tab_lock as select * from generate_series (1,100000000);), before running this script
echo -e '\n==================== Start of test ==================\n'


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


echo -e '====================== Start the backup while try running DDL on the same DB it should create a lock ======================\n'

nohup gpbackup --dbname gpadmin > backup_lock_test.log 2>&1 &

sleep 10

echo -e '\n\n======================== DDL statement to test for lock ====================\n'

nohup psql -c "drop table public.tab_lock;" > tab_lock.log 2>&1 &

psql -c "select * from pg_stat_activity where waiting = 't';"

echo -e '\n\n======================== End of test ====================\n'


