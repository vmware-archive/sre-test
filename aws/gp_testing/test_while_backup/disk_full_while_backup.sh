#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

echo -e '====================== Connect to sdw1 and fill /data1 to 100% ======================\n'

availableSize=$(gpssh -h sdw1_ipv4 "df -h /dev/nvme1n1"| awk 'NR == 2 {print $5}')

echo "Available Space: $availableSize"

length=${#availableSize}
endindex=$(expr $length - 1)
size=${availableSize:0:$endindex}
fileSize=$(( ${size} - 1))


gpssh -h sdw1_ipv4 "fallocate -l ${fileSize}G /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

echo -e '\n\n====================== Start the backup and this will fail as no space is left on sdw1 /data1  ======================\n'

gpbackup --dbname gpadmin --no-compression


echo -e '\n\n====================== Connect to sdw1 and remove data from /data1 ======================\n'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

echo -e '\n\n====================== Start the backup and this will complete sucessfuly ======================\n'

gpbackup --dbname gpadmin

echo -e '\n\n======================== End of test ====================\n'

