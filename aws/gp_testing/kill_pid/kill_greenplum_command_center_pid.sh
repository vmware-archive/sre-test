#!/bin/bash
# this test is to check kill GPCC process and recover back
echo -e '\n==================== Start of test ==================\n'

echo -e '==================== Kill gpcc pid on mdw ======================\n'

source /usr/local/greenplum-cc-6.3.0/gpcc_path.sh

ps -ef| grep gpcc| grep -v grep

ps -ef| grep gpcc| grep -v grep| awk {'print $2'}| xargs kill


echo -e '\n\n====================== Check the gpcc process id and last log in gpperfmon db ======================\n'

ps -ef| grep gpcc| grep -v grep

psql gpperfmon -c "select max(ctime) from gpmetrics.gpcc_system_history;"
sleep 100

echo -e '\n\n==================== Recover gpcc by starting gpcc ========================\n'

gpcc start

sleep 100

echo -e '\n\n==================== Check if gpcc process started and check the DB last log ================\n'

ps -ef| grep gpcc| grep -v grep

psql gpperfmon -c "select max(ctime) from gpmetrics.gpcc_system_history;"


echo -e '\n\n================ End of test ================\n'



