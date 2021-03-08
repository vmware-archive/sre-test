#!/bin/bash
#this script is to test the running backup state while mirror segment is brought down
echo -e '\n==================== Start of test ==================\n'


echo -e '==================== Strat the backup and connect to sdw1 and kill one primary segment ======================\n'

nohup gpbackup --dbname gpadmin > backup_fail_mirror.log 2>&1 &

gpssh -h sdw1_ipv4 "ps -ef| grep 'mirror/gpseg9'| grep -v grep| awk {'print $2'}| xargs kill"

sleep 100

echo -e '\n\n====================== Check the failed segment ======================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n==================== Recover failed segment incremental ========================\n'

gprecoverseg -a

sleep 100

echo -e '\n\n==================== Check if all segments are up and go ahead to rebalance ================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== End of test ====================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"


