#!/bin/bash

echo -e '\n==================== Start of test ==================\n'


echo '====================== Reboot all GP cluster segments hosts ======================\n'

gpssh -f /home/gpadmin/gp_all_hosts_ipv4 "sudo reboot"

