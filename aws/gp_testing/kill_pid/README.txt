#Below are the commands to be executed in order to run the tests in this module


nohup sh kill_primary_pid.sh > kill_primary_pid.log 2>&1 &
nohup sh kill_mirror_pid.sh > kill_mirror_pid.log 2>&1 &
nohup sh kill_greenplum_command_center_pid.sh > kill_greenplum_command_center_pid.log 2>&1 &
nohup sh fail_primary.sh > fail_primary.log 2>&1 &
nohup sh fail_mirror.sh > fail_mirror.log 2>&1 &

