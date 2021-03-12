#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

nohup sh run.sh > tpcd_vmem_failure_loading_ops.log 2>&1 &

sleep 60

echo -e '\n\n==================== Along with normal opertation processes, starting memory intense processes  ==================\n'

psql -c "create view public.process_vw as
SELECT pid,sess_id,datname,rrrsqname queue,  substring(query for 50) QUERY,(now() - query_start) AS QUERY_TIME,usename,waiting,client_addr, application_name FROM pg_stat_activity, gp_toolkit.gp_resq_role where rrrolname = usename and length(query) > 6 ORDER BY QUERY_TIME desc;"


psql -c "select * from public.process_vw;"

nohup psql -f mem_query.sql >> mem_query.log 2>&1 &
nohup psql -f mem_query.sql >> mem_query.log 2>&1 &
nohup psql -f mem_query.sql >> mem_query.log 2>&1 &

psql -c "select * from public.process_vw;"

sleep 100

echo -e '\n\n==================== One or more memory intense process will be killed by the greenplum optimizer ==================\n'

psql -c "select * from public.process_vw;"

echo -e '\n\n======================== End of test ====================\n'


