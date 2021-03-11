#Below are the commands to be executed in order to run the tests in this module


nohup sh fail_mirror_kill_mirror_pid.sh > fail_mirror_kill_mirror_pid.log 2>&1 &
nohup sh disk_full_while_restore.sh > disk_full_while_restore.log 2>&1 &
nohup sh restore_to_clouds3_kill_primary_pid.sh > restore_to_clouds3_kill_primary_pid.log 2>&1 &
nohup sh fail_segment_vm_while_restore.sh > fail_segment_vm_while_restore.log 2>&1 &
nohup sh locks_while_restore.sh > locks_while_restore.log 2>&1 &
nohup sh network_fail_vm_while_restore.sh > network_fail_vm_while_restore.log 2>&1 &
