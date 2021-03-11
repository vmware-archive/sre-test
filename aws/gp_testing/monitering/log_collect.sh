#!/bin/bash
#used gpmt and gplogfilter cmds to check collect/check the logs

source /usr/local/greenplum-db-6.13.0/greenplum_path.sh

/home/gpadmin/gpmt gp_log_collector -start 2021-02-02

gplogfilter -t -n 3 -b '2021-03-01 14:33' > logfile01.log

gplogfilter -d :10 > logfile02.log

gplogfilter -f 'ERROR' -F 'insert' -F 'INSERT' -b '2021-03-10 00:33' > logfile04.log
