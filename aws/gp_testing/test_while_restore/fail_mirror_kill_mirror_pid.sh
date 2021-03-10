#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

echo -e '==================== Start the restore process ==================\n'

dropdb gpadmin_test

nohup gprestore --timestamp 20210309091654 --create-db > gprestore_fail_mirror.log 2>&1 &

echo -e '\n\n====================connect to sdw1 and kill one mirror segment======================\n'

gpssh -h sdw1_ipv4 "ps -ef| grep 'mirror/gpseg9'| grep -v grep| awk {'print $2'}| xargs kill"

sleep 10

echo -e '\n\n====================== Check the failed segment ======================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n==================== Recover failed segment incremental ========================\n'

gprecoverseg -a

sleep 10

echo -e '\n\n==================== Check if all segments are up and running ================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== End of test ====================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"


