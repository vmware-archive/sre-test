cd /home/gpadmin/tpcds/
TIMESTAMP=$(date "+%Y.%m.%d-%H.%M.%S"); bash ./tpcds.sh 2>&1 | tee /home/gpadmin/workspace/sre-test/aws/gp_testing/fail_while_loading/tpch-${TIMESTAMP}.log
