#!/bin/bash

# Pushgateway 地址
PUSHGATEWAY_URL="http://192.168.13.236:9091"
JOB_NAME="raid_monitor"
HOST=`/sbin/ip a s eth0 | /bin/grep -oP '(?<=inet\s)\d+(\.\d+){3}'`

# 临时指标文件
METRICS_FILE="/tmp/raid_metrics.prom"

## init raid_status metric help
echo "#HELP raid_status 0(active) 1(degraded) 2(unknow)" > ${METRICS_FILE}
echo "#TYPE raid_status gauge" >> ${METRICS_FILE}

# 遍历所有 md 设备
for md_device in /dev/md*; do
    [ -e "$md_device" ] || continue
    dev_name=$(basename "$md_device")

    # 获取 RAID 状态信息
    detail_output=$(mdadm --detail "$md_device" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        if echo "$detail_output" | grep 'State :' | grep -q 'degraded'; then
            raid_status=1  # 退化
        elif echo "$detail_output" | grep 'State :' | grep -qE 'active|clean'; then
            raid_status=0  # 正常
        else
            raid_status=2  # 其他异常状态
        fi
	
	raid_state=`echo "$detail_output" | grep 'State :' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_level=`echo "$detail_output" | grep 'Raid Level' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_total_devices=`echo "$detail_output" | grep 'Total Devices' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_raid_devices=`echo "$detail_output" | grep 'Raid Devices' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_active_devices=`echo "$detail_output" | grep 'Active Devices' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_failed_devices=`echo "$detail_output" | grep 'Failed Devices' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_spare_devices=`echo "$detail_output" | grep 'Spare Devices :' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_array_size=`echo "$detail_output" | grep 'Array Size' | awk -F '(' '{print $2}' | awk -F ' ' '{print $1,$2}' | xargs | sed 's/^ *//; s/ *$//'`
	raid_create_time=`echo "$detail_output" | grep 'Creation Time' | awk -F 'Creation Time :' '{print $2}' | sed 's/^ *//; s/ *$//'`
	raid_update_time=`echo "$detail_output" | grep 'Update Time' | awk -F 'Update Time :' '{print $2}' | sed 's/^ *//; s/ *$//'`
	
	if echo "$detail_output" | grep -q 'Rebuild Status :';then
		raid_rebuild_status=`echo "$detail_output" | grep 'Rebuild Status :' | awk -F ':' '{print $2}' | sed 's/^ *//; s/ *$//'`
	else
		raid_rebuild_status='No required'
	fi

    fi
	echo "raid_status{instance=\"$HOST\",raid_state=\"$raid_state\",device=\"$dev_name\",raid_level=\"$raid_level\",raid_total_devices=\"$raid_total_devices\",raid_raid_devices=\"$raid_raid_devices\",raid_active_devices=\"$raid_active_devices\",raid_failed_devices=\"$raid_failed_devices\",raid_spare_devices=\"$raid_spare_devices\",raid_array_size=\"$raid_array_size\",raid_create_time=\"$raid_create_time\",raid_update_time=\"$raid_update_time\",raid_rebuild_status=\"$raid_rebuild_status\"} $raid_status" >> "${METRICS_FILE}"

done

# 推送到 Pushgateway
curl -s --data-binary "@$METRICS_FILE" "$PUSHGATEWAY_URL/metrics/job/$JOB_NAME/instance/${HOST}"
