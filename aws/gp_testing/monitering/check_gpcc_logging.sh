#!/bin/bash

echo -e '\n==================== Start of test ==================\n'

source /usr/local/greenplum-cc-6.3.0/gpcc_path.sh

ps -ef| grep gpcc| grep -v grep

echo -e '==================== Check the logging ==================\n'
psql gpperfmon -c "select distinct(ctime) from gpmetrics.gpcc_system_history order by 1 desc limit 10;"

gpcc stop

sleep 100

echo -e '\n\n==================== Recover gpcc by starting gpcc ========================\n'

gpcc start

sleep 100

echo -e '\n\n==================== Check if gpcc process started and check the DB last log ================\n'

ps -ef| grep gpcc| grep -v grep

psql gpperfmon -c "select distinct(ctime) from gpmetrics.gpcc_system_history order by 1 desc limit 10;"

echo -e '\n\n======================== End of test ====================\n'
