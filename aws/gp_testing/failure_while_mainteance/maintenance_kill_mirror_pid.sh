#!/bin/bash
#This test is to check if any impact on the maintenance script if mirror segment goes down, expected behavior is there should not be any impact on maintenance script running.

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo -e '\n==================== Start of test ==================\n'

echo -e '==================== Start the catalog table maintenance process and kill the mirror pid ======================\n'

nohup psql gpadmin -f /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance.sql > /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance_mirror_pid_kill.log 2>&1 &

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

echo -e '\n\n================ End of test ================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

