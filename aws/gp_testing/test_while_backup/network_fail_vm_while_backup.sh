#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo -e '==================== Start backup and connect to sdw1 disconnect it from network ======================\n'

nohup gpbackup --dbname gpadmin > backup_fail_network.log 2>&1 &

gpssh -h sdw1_ipv4 "sudo iptables -A INPUT -s mdw_ipv4 -j DROP"

sleep 60

echo -e '\n\n====================== Check the failed segment ======================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"


echo -e '\n\n==================== Connect to SDW2 and remove the route table rule from SDW1 ==================\n'

gpssh -h sdw2_ipv4 'ssh -oStrictHostKeyChecking=no sdw1_ipv4 "sudo iptables -D INPUT -s mdw_ipv4 -j DROP"'

echo -e '\n\n==================== Start backup after the  network issue is resumed and segments are recovered and rebalaned ======================\n'

gprecoverseg -a

sleep 100

echo -e '\n\n================================ Check if all segments are up and go ahead to rebalance ===========================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar

sleep 60

nohup gpbackup --dbname gpadmin > backup_fail_network2.log 2>&1 &

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== End of test ====================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"


