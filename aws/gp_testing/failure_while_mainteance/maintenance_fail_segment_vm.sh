#!/bin/bash

echo '========================Start of test===================='


echo '======================start the mainteance script and connect to sdw1 and reboot segment host======================'

nohup psql gpadmin -f /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance.sql > /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance.log 2>&1 &

gpssh -h sdw1_ipv4 "sudo reboot"

sleep 100

echo '=======================check the failed segment===================='

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo '========================Recover failed segment incremental=========================='

gprecoverseg -a

sleep 100

echo '================================Check if all segments are up and go ahead to rebalance==========================='

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar

echo '================End of test================'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
