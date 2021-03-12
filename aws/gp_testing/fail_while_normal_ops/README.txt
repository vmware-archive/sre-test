#Below are the commands to be executed in order to run the tests in this module


nohup sh fail_segment_vm_normal_ops.sh > fail_segment_vm_normal_ops.log 2>&1 &
nohup sh kill_primary_pid_spill_normal_ops.sh > kill_primary_pid_spill_normal_ops.log 2>&1 &
nohup sh vmem_failure_normal_ops.sh > vmem_failure_normal_ops.log 2>&1 &
nohup sh kill_mirror_pid_normal_ops.sh > kill_mirror_pid_normal_ops.log 2>&1 &
nohup sh kill_primary_pid_normal_ops.sh > kill_primary_pid_normal_ops.log 2>&1 &
