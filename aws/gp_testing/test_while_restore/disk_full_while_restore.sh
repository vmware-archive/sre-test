#!/bin/bash

echo -e '\n==================== Start of test ==================\n'


echo -e '====================== Connect to sdw1 and fill /data1 to 100% ======================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

dropdb gpadmin_test

availableSize=$(gpssh -h sdw1_ipv4 "df -h /dev/nvme1n1"| awk 'NR == 2 {print $5}')

echo "Available Space: $availableSize"

length=${#availableSize}
endindex=$(expr $length - 1)
size=${availableSize:0:$endindex}
fileSize=$(( ${size} - 1))


gpssh -h sdw1_ipv4 "fallocate -l ${fileSize}G /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

echo -e '\n\n====================== Start the restore and this will fail as no space is left on sdw1 /data1  ======================\n'

gprestore --timestamp 20210309091654 --create-db

echo -e '\n\n====================== Connect to sdw1 and remove the file from /data1 ======================\n'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

dropdb gpadmin_test

sleep 60

echo -e '\n\n====================== Start the restore and this will complete sucessfuly ======================\n'

gprestore --timestamp 20210309091654 --create-db

echo -e '\n\n======================== End of test ====================\n'


