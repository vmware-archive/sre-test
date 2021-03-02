#!/bin/bash

echo '========================Start of test===================='


echo '====================== Make sure all segments are up and running ======================'

gpssh -f /home/gpadmin/gp_all_hosts_ipv4 "date"



gpstart -a

sleep 100

echo '======================== GPDB is started =========================='

#gprecoverseg -a

sleep 100

echo '================================Check if all segments are up and go ahead to rebalance==========================='

gpstate
psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

#gprecoverseg -ar

sleep 60

gpstate
psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"


echo '================End of test================'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
