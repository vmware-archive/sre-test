#Below are the commands to be executed in order to run the tests in this module


nohup sh fail_mdw_vm.sh > fail_mdw_vm.log 2>&1 &
nohup sh fail_smdw_vm.sh > fail_smdw_vm.log 2>&1 &
nohup sh fail_segment_vm.sh > fail_segment_vm.log 2>&1 &
