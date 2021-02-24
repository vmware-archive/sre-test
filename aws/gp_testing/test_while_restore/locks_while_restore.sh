#!/bin/bash

echo '========================Start of test===================='


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


echo '====================== Start the backup while try running DDL on the same DB it should create a lock ======================'

nohup gprestore --timestamp 20210224123825 --plugin-config /home/gpadmin/test_s3_backup/s3-test-config.yaml --create-db > gprestore.log 2>&1 &

sleep 10

echo '========================DDL statement to test for lock===================='

nohup psql -f ddl_statement.sql > ddl_statement.log 2>&1 &

psql -c "select * from pg_stat_activity where waiting = 't';"

echo '========================end of test===================='

