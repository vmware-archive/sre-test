#!/bin/bash
#this test is to remove one disk mount use umount and mount.
echo '========================Start of test===================='


echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

gpssh -h sdw1_ipv4 "sudo umount -l /data1"

gpstate

gpssh -h sdw1_ipv4 "sudo mount /dev/nvme1n1 /data1"

sleep 60

gpstop -arf

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

gprecoverseg -a

sleep 60

gprecoverseg -ar

echo '====================== Start the backup and this will fail as no space is left on sdw1 /data1  ======================'

#gpbackup --dbname gpadmin

gpstate

echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'



sleep 60

gpstate

echo '====================== Start the backup and this will complete sucessfuly ======================'

#gpbackup --dbname gpadmin

echo '========================end of test===================='
