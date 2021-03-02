#!/bin/bash

echo '========================Start of test===================='


echo '====================== Reboot all GP cluster segments hosts ======================'

gpssh -f /home/gpadmin/gp_all_hosts_ipv4 "sudo reboot"

