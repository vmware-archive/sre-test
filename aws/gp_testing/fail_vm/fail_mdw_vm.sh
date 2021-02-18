#!/bin/bash

echo '====================Start of test=================='


echo '====================connect to mdw and reboot server======================'

gpssh -h mdw_ipv4 "sudo reboot"

sleep 100

echo '====================== check if GP DB is ======================'

gpssh -h mdw_ipv4 "gpstate"

echo '==================== activate the standby master as acting master========================'

export PGPORT=5432
gpactivatestandby -ad /data1/gpdb/master/gpseg-1

sleep 60

echo '====================Check if db is up and running normal with smdw as================'

gpssh -h mdw_ipv4 "mv /data1/gpdb/master/gpseg-1 /data1/gpdb/master/bkp_gpseg-1"

gpinitstandby -as mdw_ipv4

sleep 60

gpstate

psql -c "create table tab1 as select generate_series(1,1000000);"
psql -c "select count(*), gp_segment_id from  tab1 group by 2;"
psql -c "drop table tab1;"


echo '==================== Recover back to orginal configuration ================'

gpstop -am

gpssh -h mdw_ipv4 "export PGPORT=5432;gpactivatestandby -ad $MASTER_DATA_DIRECTORY"

mv /data1/gpdb/master/gpseg-1 /data1/gpdb/master/bkp_gpseg-1

gpssh -h mdw_ipv4 "gpinitstandby -as smdw_ipv4"

gpssh -h mdw_ipv4 "gpstate"


echo '====================Check if all segments are up and go ahead to rebalance================'

echo 'End of test'

gpssh -h mdw_ipv4 "psql -c 'create table tab1 as select generate_series(1,1000000);'"

gpssh -h mdw_ipv4 "psql -c 'select count(*), gp_segment_id from  tab1 group by 2;'"

gpssh -h mdw_ipv4 "psql -c 'drop table tab1;'"

