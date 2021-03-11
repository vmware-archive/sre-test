#!/bin/bash

echo -e '\n==================== Start of test ==================\n'


echo -e '====================== Connect to sdw1 and sdw2 and reboot them ======================\n'

gpssh -h sdw1_ipv4 -h sdw2_ipv4 "sudo reboot"

sleep 120

echo -e '\n\n======================= Check the failed segment ====================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== Restart the DB ==========================\n'

gpstop -arf

sleep 100

echo -e '\n\n======================== Recover the failed segments ==========================\n'

gprecoverseg -a

sleep 100

echo -e '\n\n================================ Check if all segments are up and go ahead to rebalance ===========================\n'

gpstate
psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar

sleep 60

gpstate
psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"


echo -e '\n\n======================== End of test ====================\n'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

