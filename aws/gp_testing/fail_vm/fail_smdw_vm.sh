#!/bin/bash

echo -e '\n==================== Start of test ==================\n'


echo -e '==================== Connect to smdw and reboot it ======================\n'

gpssh -h smdw_ipv4 "sudo reboot"

sleep 100

echo -e '\n\n====================== Check the failed standby master ======================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n==================== Recover failed standby master ========================\n'

gpinitstandby -r -M fast -a

sleep 60

gpinitstandby -s smdw_ipv4 -M fast -a

sleep 100

gpstate

echo -e '\n\n==================== Check if all standby master is up and running ================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== End of test ====================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"


