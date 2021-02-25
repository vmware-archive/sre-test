#!/bin/bash

echo '====================Start of test=================='

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo '====================Start backup after the  network issue is resumed and segments are recovered and rebalaned======================'

gprecoverseg -a

sleep 100

echo '================================Check if all segments are up and go ahead to rebalance==========================='

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

gprecoverseg -ar

sleep 60

nohup gpbackup --dbname test1 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml > backup_success_network.log 2>&1 &


gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo '====================End of test=================='

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
