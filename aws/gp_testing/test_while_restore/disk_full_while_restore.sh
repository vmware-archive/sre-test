#!/bin/bash

echo '========================Start of test===================='


echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


gpssh -h sdw1_ipv4 "fallocate -l 477G /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

echo '====================== Start the restore and this will fail as no space is left on sdw1 /data1  ======================'

gprestore --timestamp 20210224165521 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml --create-db

echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

dropdb test1

sleep 60

echo '====================== Start the restore and this will complete sucessfuly ======================'

gprestore --timestamp 20210224165521 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml --create-db

echo '========================end of test===================='

