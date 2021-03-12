#!/bin/bash
#this test is fill one of the data disk in segment host 100% while some load operations and see if it bring down any segments.
echo -e '\n==================== Start of test ==================\n'


echo -e '====================== Connect to sdw1 and fill /data1 to 100% ======================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

nohup sh run.sh > tpcd_disk_full.log 2>&1 &

sleep 100

gpssh -h sdw1_ipv4 "df -h| grep data1"

availableSize=$(gpssh -h sdw1_ipv4 "df -h /dev/nvme1n1"| awk 'NR == 2 {print $5}')

echo "Available Space: $availableSize"

length=${#availableSize}
endindex=$(expr $length - 1)
size=${availableSize:0:$endindex}
fileSize=$(( ${size} - 1))


gpssh -h sdw1_ipv4 "fallocate -l ${fileSize}G /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"


sleep 100

echo -e '\n\n====================== Start the backup and this will fail as no space is left on sdw1 /data1  ======================\n'


gpstate

echo -e '\n\n====================== Connect to sdw1 and fill /data1 to 100% ======================\n'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

gpstate

echo -e '\n\n====================== Start the backup and this will complete sucessfuly ======================\n'


echo -e '\n\n======================== End of test ====================\n'

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

