#!/bin/bash
# this script need to be run from smdw
echo '====================Start of test=================='

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo '==================== connect to mdw and reboot server ======================'

gpssh -h mdw_ipv4 "nohup psql gpadmin -f /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance.sql > /home/gpadmin/workspace/sre-test/aws/gp_testing/failure_while_mainteance/catalog_tables_mainteance_fail_mdw.log 2>&1 &"

gpssh -h mdw_ipv4 "sudo reboot"

sleep 100

echo '====================== check if GP DB is ======================'

gpssh -h mdw_ipv4 "gpstate"

echo '==================== strat the master ========================'


gpssh -h mdw_ipv4 "gpstart -a"

sleep 60

echo '====================Check if db is up and running normal with smdw as================'


gpssh -h mdw_ipv4 "gpstate"

echo '====================End of test=================='

gpssh -h mdw_ipv4 "psql -c 'create table tab1 as select generate_series(1,1000000);'"
gpssh -h mdw_ipv4 "psql -c 'select count(*), gp_segment_id from  tab1 group by 2;'"
gpssh -h mdw_ipv4 "psql -c 'drop table tab1;'"


