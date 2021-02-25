#!/bin/bash

echo '====================Start of test=================='

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo '====================connect to sdw1 and kill one primary segment======================'


nohup gpbackup --dbname test1 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml > backup.log 2>&1 &


gpssh -h sdw1_ipv4 "ps -ef| grep 'primary/gpseg0'| grep -v grep| awk {'print $2'}| xargs kill"

sleep 100

echo '======================check the failed segment======================'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo '====================Recover failed segment incremental========================'

gprecoverseg -a

sleep 100

gprecoverseg -ra

echo '====================Check if all segments are up and go ahead to rebalance================'

sleep 60

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gpstate


nohup gpbackup --dbname test1 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml > backup1.log 2>&1 &

echo 'End of test'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

"']'}"
