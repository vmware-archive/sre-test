#!/bin/bash

echo '========================Start of test===================='


source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

nohup sh /home/gpadmin/tpcds/run.sh 2>&1 &

psql -c "select * from public.process_vw;"

nohup psql -f mem_query.sql >> mem_query.log 2>&1 &
nohup psql -f mem_query.sql >> mem_query.log 2>&1 &
nohup psql -f mem_query.sql >> mem_query.log 2>&1 &

psql -c "select * from public.process_vw;"

sleep 100

 psql -c "select * from public.process_vw;"

