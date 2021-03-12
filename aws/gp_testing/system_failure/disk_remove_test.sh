#!/bin/bash
#this test is to remove one disk mount use umount and mount.
echo -e '\n==================== Start of test ==================\n'


echo -e '====================== Connect to sdw1 and remove /data1 ======================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

gpssh -h sdw1_ipv4 "sudo umount -l /data1"

gpstate

echo -e '\n\n====================== Connect to sdw1 and re-attach /data1 ======================\n'

gpssh -h sdw1_ipv4 "sudo mount /dev/nvme1n1 /data1"

sleep 60

echo -e '\n\n====================== Restart the cluster and recover the failed segments ======================\n'

gpstop -arf

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

gprecoverseg -a

sleep 60

echo -e '\n\n====================== Rebalance the cluster once all segments are recovered and re-synced ======================\n'

gprecoverseg -ar

gpstate

echo -e '\n\n======================== End of test ====================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
