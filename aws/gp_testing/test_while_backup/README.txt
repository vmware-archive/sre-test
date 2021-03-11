#Below are the commands to be executed in order to run the tests in this module


nohup sh fail_mirror_while_backup.sh > fail_mirror_while_backup.log 2>&1 &
nohup sh network_fail_vm_while_backup.sh > network_fail_vm_while_backup.log 2>&1 &
nohup sh backup_to_clouds3_kill_primary_pid.sh > backup_to_clouds3_kill_primary_pid.log 2>&1 &
nohup sh locks_while_backup.sh > locks_while_backup.log 2>&1 &
nohup sh disk_full_while_backup.sh > disk_full_while_backup.log 2>&1 &
nohup sh fail_segment_vm_while_backup.sh > fail_segment_vm_while_backup.log 2>&1 &

