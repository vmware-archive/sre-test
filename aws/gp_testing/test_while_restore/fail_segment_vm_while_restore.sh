#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

echo -e '==================== Start the restore process ==================\n'

dropdb gpadmin_test

nohup gprestore --timestamp 20210309122003 --create-db > gprestore_fail_segment_vm.log 2>&1 &

echo -e '\n\n====================== Connect to sdw1 and reboot segment host ======================\n'

gpssh -h sdw1_ipv4 "sudo reboot"

sleep 100

echo -e '\n\n======================= Check the failed segment ====================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== Recover failed segment incremental ==========================\n'

gprecoverseg -a

sleep 150

echo -e '\n\n================================ Check if all segments are up and go ahead to rebalance ===========================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar

echo -e '\n\n======================== End of test ====================\n'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

