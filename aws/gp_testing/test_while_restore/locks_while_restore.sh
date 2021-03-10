#!/bin/bash

echo -e '\n==================== Start of test ==================\n'


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh


echo -e '====================== Start the restore while try running DDL on the same DB ======================\n'

dropdb gpadmin_test

nohup gprestore --timestamp 20210309124906 --create-db > gprestore_lock.log 2>&1 &

sleep 10

echo -e '\n\n======================== DDL statement to test for lock ====================\n'

nohup psql -f ddl_statement.sql > ddl_statement.log 2>&1 &

psql -c "select * from pg_stat_activity where waiting = 't';"

echo -e '\n\n======================== End of test ====================\n'


