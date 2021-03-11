#!/bin/bash
# this script need to be run from smdw
echo -e '\n==================== Start of test ==================\n'


echo -e '==================== Connect to mdw and reboot server ======================\n'

gpssh -h mdw_ipv4 "sudo reboot"

sleep 100

echo -e '\n\n====================== Check if GP DB is up and running ======================\n'

gpssh -h mdw_ipv4 "gpstate"

echo -e '\n\n==================== Activate the standby master as acting master ========================\n'

export PGPORT=5432
gpactivatestandby -ad /data1/gpdb/master/gpseg-1

sleep 60

echo -e '\n\n==================== Check if db is up and running normal with smdw acting as master ================\n'

gpssh -h mdw_ipv4 "mv /data1/gpdb/master/gpseg-1 /data1/gpdb/master/bkp_gpseg-1"

gpinitstandby -as mdw_ipv4

sleep 60

gpstate

psql -c "create table tab1 as select generate_series(1,1000000);"
psql -c "select count(*), gp_segment_id from  tab1 group by 2;"
psql -c "drop table tab1;"


echo -e '\n\n==================== Recover back to orginal configuration ================\n'

gpstop -am

gpssh -h mdw_ipv4 "export PGPORT=5432;gpactivatestandby -ad $MASTER_DATA_DIRECTORY"

mv /data1/gpdb/master/gpseg-1 /data1/gpdb/master/bkp_gpseg-1

gpssh -h mdw_ipv4 "gpinitstandby -as smdw_ipv4"

echo -e '\n\n==================== Check if all segments are up and go ahead to rebalance ================\n'

gpssh -h mdw_ipv4 "gpstate"

echo -e '\n\n======================== End of test ====================\n'

gpssh -h mdw_ipv4 "psql -c 'create table tab1 as select generate_series(1,1000000);'"

gpssh -h mdw_ipv4 "psql -c 'select count(*), gp_segment_id from  tab1 group by 2;'"

gpssh -h mdw_ipv4 "psql -c 'drop table tab1;'"


