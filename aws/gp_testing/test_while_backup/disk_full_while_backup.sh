#!/bin/bash

echo '========================Start of test===================='


echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

gpssh -h sdw1_ipv4 "fallocate -l 481G /data1/data_file"

nohup gpbackup --dbname gpadmin > backup_disk_full01.log 2>&1 &

#gpssh -h sdw1_ipv4 "fallocate -l 481G /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

echo '====================== Start the backup and this will fail as no space is left on sdw1 /data1  ======================'

gpbackup --dbname gpadmin


echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

echo '====================== Start the backup and this will complete sucessfuly ======================'

 nohup gpbackup --dbname gpadmin > backup_disk_full01.log 2>&1 &

echo '========================end of test===================='
