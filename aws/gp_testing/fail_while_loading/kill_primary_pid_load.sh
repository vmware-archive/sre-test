#!/bin/bash

echo '========================Start of test===================='


echo '======================Connect to sdw1 and kill one primary segment======================'

gpssh -h sdw1_ipv4 "ps -ef| grep 'primary/gpseg0'| grep -v grep| awk {'print $2'}| xargs kill"

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
