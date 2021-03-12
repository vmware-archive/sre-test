#Use below commands to run scripts in this module
nohup sh fail_segment_loading_ops.sh > fail_segment_loading_ops.log 2>&1
nohup sh kill_primary_pid_spill_loading_ops.sh > kill_primary_pid_spill_loading_ops.log 2>&1 &
nohup sh vmem_failure_loading_ops.sh > vmem_failure_loading_ops.log 2>&1 &
nohup sh kill_primary_pid_loading_ops.sh > kill_primary_pid_loading_ops.log 2>&1 &
nohup sh kill_mirror_pid_loading_ops.sh > kill_mirror_pid_loading_ops.log 2>&1 &
