#!/bin/bash

echo '====================Start of test=================='

source /usr/local/greenplum-cc-6.3.0/gpcc_path.sh

ps -ef| grep gpcc| grep -v grep

echo '====================check the logging=================='
psql gpperfmon -c "select distinct(ctime) from gpmetrics.gpcc_system_history order by 1 desc limit 10;"

gpcc stop

sleep 100

echo '====================Recover gpcc by starting gpcc========================'

gpcc start

sleep 100

echo '====================Check if gpcc process started and check the DB last log================'

ps -ef| grep gpcc| grep -v grep

 psql gpperfmon -c "select distinct(ctime) from gpmetrics.gpcc_system_history order by 1 desc limit 10;"

echo 'End of test'


