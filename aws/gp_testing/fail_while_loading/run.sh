cd /home/gpadmin/tpcds
TIMESTAMP=$(date "+%Y.%m.%d-%H.%M.%S");
bash ./tpcds.sh > tpch-${TIMESTAMP}.log
