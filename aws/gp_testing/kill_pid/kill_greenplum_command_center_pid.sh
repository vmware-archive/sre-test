#!/bin/bash
# this test is to check kill GPCC process and recover back
echo '====================Start of test=================='


echo '====================kill gpcc pid on mdw======================'

source /usr/local/greenplum-cc-6.3.0/gpcc_path.sh

ps -ef| grep gpcc| grep -v grep

ps -ef| grep gpcc| grep -v grep| awk {'print $2'}| xargs kill


echo '======================check the gpcc process id and last log in gpperfmon db======================'

ps -ef| grep gpcc| grep -v grep

psql gpperfmon -c "select max(ctime) from gpmetrics.gpcc_system_history;"
sleep 100

echo '====================Recover gpcc by starting gpcc========================'

gpcc start

sleep 100

echo '====================Check if gpcc process started and check the DB last log================'

ps -ef| grep gpcc| grep -v grep

psql gpperfmon -c "select max(ctime) from gpmetrics.gpcc_system_history;"


echo 'End of test'


