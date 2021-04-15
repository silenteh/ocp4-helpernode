#!/bin/bash
#
## This is the startup script for the LoadBalancer container

#
## Variables for DHCP
dhcpConfig=/etc/dhcp/dhcpd.conf
dhcp6Config=/etc/dhcp/dhcpd6.conf
dhcpConfigTemplate=/usr/local/src/dhcpd.conf.j2
dhcp6ConfigTemplate=/usr/local/src/dhcpd6.conf.j2
helperPodYaml=/usr/local/src/helperpod.yaml
ansibleLog=/var/log/helperpod_ansible_run.log

#
## Make sure the HELPERPOD_CONFIG_YAML env var has size
[[ ${#HELPERPOD_CONFIG_YAML} -eq 0 ]] && echo "FATAL: HELPERPOD_CONFIG_YAML env var not set!!!" && exit 254

#
## Take the HELPERPOD_CONFIG_YAML env variable and write out the YAML file.
echo ${HELPERPOD_CONFIG_YAML} | base64 -d > ${helperPodYaml}

#
## Create dhcpd.conf based on the template and yaml passed in.
ansible localhost -c local -e @${helperPodYaml} -m template -a "src=${dhcpConfigTemplate} dest=${dhcpConfig}" > ${ansibleLog} 2>&1

## Create dhcpd6.conf
ansible localhost -c local -e @${helperPodYaml} -m template -a "src=${dhcp6ConfigTemplate} dest=${dhcp6Config}" > ${ansibleLog} 2>&1

#
## Test for the validity of the config file. Run the DHCP process if it passes
if ! /usr/sbin/dhcpd -6 -t -cf ${dhcp6Config} ; then
        echo "=========================="
        echo "FATAL: Invalid DHCP6 config"
        echo "=========================="
        exit 254
else
        echo "========================"
        echo "Starting DHCP6 service..."
        echo "========================"
        /usr/sbin/dhcpd -f -6 -cf ${dhcp6Config} -user dhcpd -group dhcpd --no-pid
fi


if ! /usr/sbin/dhcpd -t -cf ${dhcpConfig} ; then
	echo "=========================="
	echo "FATAL: Invalid DHCP config"
	echo "=========================="
	exit 254
else
	echo "========================"
	echo "Starting DHCP service..."
	echo "========================"
	/usr/sbin/dhcpd -f -cf ${dhcpConfig} -user dhcpd -group dhcpd --no-pid
fi
##
##
