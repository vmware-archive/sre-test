#Use below commands to run the scripts in this module

nohup sh maintenance_fail_mdw_vm.sh > maintenance_fail_mdw_vm.log 2>&1 &
nohup sh maintenance_fail_segment_vm.sh > maintenance_fail_segment_vm.log 2>&1 &
nohup sh maintenance_kill_mirror_pid.sh > maintenance_kill_mirror_pid.log 2>&1 &
nohup sh maintenance_kill_primary_pid.sh > maintenance_kill_primary_pid.log 2>&1 &
