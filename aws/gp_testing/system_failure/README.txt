#Below are the commands to be executed in order to run the tests in this module


nohup sh disk_full_while_backup.sh > disk_full_while_backup.log 2>&1 &
nohup sh full_cluster_failure_part1.sh > full_cluster_failure_part1.log 2>&1 &
nohup sh full_cluster_failure_part2.sh > full_cluster_failure_part2.log 2>&1 &
nohup sh fail_segment_vm.sh > fail_segment_vm.log 2>&1 &
nohup sh fail_multiple_segment_vm.sh > fail_multiple_segment_vm.log 2>&1 &
nohup sh disk_remove_test.sh > disk_remove_test.log 2>&1 &
