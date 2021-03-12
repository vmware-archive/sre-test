#!/bin/bash
#this script we do full recovery of failed segments assuming incremental recovery failed

echo -e '\n======================== Start of test ====================\n'


echo -e '\n\n====================== Connect to sdw1 and reboot it  ======================\n'

gpssh -h sdw1_ipv4 "sudo reboot"

sleep 100

echo -e '\n\n======================= check the failed segment ====================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== Do full Recover failed segment ==========================\n'

gprecoverseg -aF

sleep 100

echo -e '\n\n================================ Check if all segments are up and go ahead to rebalance ===========================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar
sleep 100

echo -e '\n\n================End of test================\n'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

