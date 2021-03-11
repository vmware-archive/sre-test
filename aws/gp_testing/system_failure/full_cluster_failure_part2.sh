#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

sleep 100

echo -e '====================== Make sure all segments are up and running ======================\n'

gpssh -f /home/gpadmin/gp_all_hosts_ipv4 "date"



gpstart -a

sleep 100

echo -e '\n\n======================== GPDB is started ==========================\n'

echo -e '\n\n================================ Check if all segments are up and running ===========================\n'

gpstate

psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

echo -e '\n\n======================== End of test ====================\n'


psql -c "select * from gp_segment_configuration where role!=preferred_role or status = 'd'"

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"

