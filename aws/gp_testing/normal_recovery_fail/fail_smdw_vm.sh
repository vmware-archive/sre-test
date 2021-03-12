#!/bin/bash
#Assuming smdw is not in sync with master after VM crash, we remove and re-intiate smdw

echo -e '\n\n====================Start of test==================\n'


echo -e '\n\n====================connect to smdw and reboot it ======================\n'

gpssh -h smdw_ipv4 "sudo reboot"

date
sleep 600
date
echo -e '\n\n======================check the failed smdw after 10 mins======================\n'

gpstate

psql -c "select * from gp_segment_configuration;"

echo -e '\n\n==================== Assuming  SMDW not getting in sync with master we remove it and reintiate it ========================\n'

gpinitstandby -r -M fast -a

gpinitstandby -s smdw_ipv4 -M fast -a

sleep 100

gpstate

echo -e '\n\n====================Check if SMDW is up and in sync with master ================\n'

psql -c "select * from gp_segment_configuration;"

echo -e '\n\n======================== End of test ====================\n'

psql -c "create table tab1 as select generate_series(1,1000000);"

psql -c "select count(*), gp_segment_id from  tab1 group by 2;"

psql -c "drop table tab1;"
