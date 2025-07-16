#!/bin/bash
# description: output server cidr network mac address 
# author: jackli
# date: 2025-07-15
# email: username@test.com

user='username'
password='password'
instance_name=$(hostname)
label="network_interface_mac_address"
PushgatewayServer="127.0.0.1:9091"
metrics_file='/usr/local/pushgateway/network-metrics.txt'

## TYPE ${push_label} gauge
echo "#HELP ${label} value is always 1" > ${metrics_file}
echo "#TYPE ${label} gauge" >> ${metrics_file}

## output metrics
/sbin/arp -en | grep -E '192.168' | grep ether | awk -v push_label="${label}" '{print push_label"{ip=\""$1"\",mac=\""$3"\"} 1"}' >> ${metrics_file}

## push to pushgateway
cat ${metrics_file} | curl --data-binary @- http://${PushgatewayServer}/metrics/job/pushgateway/instance/${instance_name}
