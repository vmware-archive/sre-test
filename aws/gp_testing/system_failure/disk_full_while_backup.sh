#!/bin/bash
#this test is fill one of the data disk in segment host 100% while some load operations and see if it bring down any segments.
echo '========================Start of test===================='


echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

gpssh -h sdw1_ipv4 "df -h| grep data1"

var1=`gpssh -h sdw1_ipv4 "df -h| grep data1"| awk {'print $5'}`
var2="${var1::-1}"
var3="$(($var2-1))"
var4="$var3"G

gpssh -h sdw1_ipv4 "fallocate -l $var4 /data1/data_file"


gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 100

echo '====================== Start the backup and this will fail as no space is left on sdw1 /data1  ======================'

#gpbackup --dbname gpadmin

gpstate

echo '====================== Connect to sdw1 and fill /data1 to 100% ======================'

gpssh -h sdw1_ipv4 "rm /data1/data_file"

gpssh -h sdw1_ipv4 "df -h| grep data1"

sleep 60

gpstate

echo '====================== Start the backup and this will complete sucessfuly ======================'

#gpbackup --dbname gpadmin

echo '========================end of test===================='
