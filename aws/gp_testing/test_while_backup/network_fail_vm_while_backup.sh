#!/bin/bash

echo '====================Start of test=================='

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo '====================Start backup and connect to sdw1 disconnect it from network======================'


nohup gpbackup --dbname gpadmin --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml > backup_fail_network.log 2>&1 &


gpssh -h sdw1_ipv4 "sudo iptables -A INPUT -s mdw_ipv4 -j DROP"

sleep 100

echo '======================check the failed segment======================'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo '====================End of test=================='

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
