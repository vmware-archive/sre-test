#!/usr/bin/env bash

set -eo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TFSTATEFILE=${CWDIR}/../terraform.tfstate

if [ ! -d ${CWDIR}/files ]; then
    mkdir ${CWDIR}/files
fi

if [ ! -f ${TFSTATEFILE} ]; then
    echo "FATAL: tfstate file (${TFSTATEFILE}) does not exist"
    exit 2
fi

jq -r '.resources[] | select(.type == "tls_private_key") | .instances[0].attributes.private_key_pem' ${TFSTATEFILE} > ${CWDIR}/../gp_dev.pem
chmod 600 ${CWDIR}/../gp_dev.pem
cp ${CWDIR}/../gp_dev.pem ${CWDIR}/files

JUMPBOX_PUBLIC_IPV4=$( jq -r '.outputs."gp_dev_jumpbox-public-IPv4".value'    ${TFSTATEFILE} )

MDW_PUBLIC_IPV4=$(     jq -r '.outputs."gp_dev_dwcoordinators-public-IPv4".value[0]' ${TFSTATEFILE} )
SMDW_PUBLIC_IPV4=$(    jq -r '.outputs."gp_dev_dwcoordinators-public-IPv4".value[1]' ${TFSTATEFILE} )
SDW1_PUBLIC_IPV4=$(    jq -r '.outputs."gp_dev_dwdatanodes-public-IPv4".value[0]' ${TFSTATEFILE} )
SDW2_PUBLIC_IPV4=$(    jq -r '.outputs."gp_dev_dwdatanodes-public-IPv4".value[1]' ${TFSTATEFILE} )

MDW_PRIVATE_IPV4=$(    jq -r '.outputs."gp_dev_dwcoordinators-private-IPv4".value[0]' ${TFSTATEFILE} )
SMDW_PRIVATE_IPV4=$(   jq -r '.outputs."gp_dev_dwcoordinators-private-IPv4".value[1]' ${TFSTATEFILE} )
SDW1_PRIVATE_IPV4=$(   jq -r '.outputs."gp_dev_dwdatanodes-private-IPv4".value[0]' ${TFSTATEFILE} )
SDW2_PRIVATE_IPV4=$(   jq -r '.outputs."gp_dev_dwdatanodes-private-IPv4".value[1]' ${TFSTATEFILE} )

MDW_PRIVATE_IPV6=$(    jq -r '.outputs."gp_dev_dwcoordinators-private-IPv6".value[0]' ${TFSTATEFILE} )
SMDW_PRIVATE_IPV6=$(   jq -r '.outputs."gp_dev_dwcoordinators-private-IPv6".value[1]' ${TFSTATEFILE} )
SDW1_PRIVATE_IPV6=$(   jq -r '.outputs."gp_dev_dwdatanodes-private-IPv6".value[0]' ${TFSTATEFILE} )
SDW2_PRIVATE_IPV6=$(   jq -r '.outputs."gp_dev_dwdatanodes-private-IPv6".value[1]' ${TFSTATEFILE} )


tee ${CWDIR}/ansible_hosts >/dev/null <<< "
all:
  vars:
    ansible_user: centos
    ansible_ssh_private_key_file: files/gp_dev.pem
    pivnet_api_token: ${pivnet_api_token}
  children:
    jumpbox:
      hosts:
        jumpbox_ipv4:
          ansible_host: ${JUMPBOX_PUBLIC_IPV4}
    dwcoordinators:
      hosts:
        mdw_ipv4:
          ansible_host: ${MDW_PUBLIC_IPV4}
        smdw_ipv4:
          ansible_host: ${SMDW_PUBLIC_IPV4}
    dwdatanodes:
      hosts:
        sdw1_ipv4:
          ansible_host: ${SDW1_PUBLIC_IPV4}
        sdw2_ipv4:
          ansible_host: ${SDW2_PUBLIC_IPV4}"

cat ${CWDIR}/ansible_hosts

tee ${CWDIR}/files/etchosts >/dev/null <<< "
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${MDW_PRIVATE_IPV4}  mdw_ipv4
${SMDW_PRIVATE_IPV4} smdw_ipv4
${SDW1_PRIVATE_IPV4} sdw1_ipv4
${SDW2_PRIVATE_IPV4} sdw2_ipv4

${MDW_PRIVATE_IPV6}  mdw_ipv6
${SMDW_PRIVATE_IPV6} smdw_ipv6
${SDW1_PRIVATE_IPV6} sdw1_ipv6
${SDW2_PRIVATE_IPV6} sdw2_ipv6"

cat ${CWDIR}/files/etchosts

tee ${CWDIR}/files/gp_all_hosts_ipv4 >/dev/null <<EOF
mdw_ipv4
smdw_ipv4
sdw1_ipv4
sdw2_ipv4
EOF

cat ${CWDIR}/files/gp_all_hosts_ipv4

tee ${CWDIR}/files/gp_segment_hosts_ipv4 >/dev/null <<EOF
sdw1_ipv4
sdw2_ipv4
EOF

cat ${CWDIR}/files/gp_segment_hosts_ipv4

tee ${CWDIR}/files/gp_all_hosts_ipv6 >/dev/null <<EOF
mdw_ipv6
smdw_ipv6
sdw1_ipv6
sdw2_ipv6
EOF

cat ${CWDIR}/files/gp_all_hosts_ipv6

tee ${CWDIR}/files/gp_segment_hosts_ipv6 >/dev/null <<EOF
sdw1_ipv6
sdw2_ipv6
EOF

cat ${CWDIR}/files/gp_segment_hosts_ipv6
