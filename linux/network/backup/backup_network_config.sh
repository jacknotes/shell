#!/bin/sh
# backup network files.
# date: 202407311745

export PATH=/root/.pyenv/plugins/pyenv-virtualenv/shims:/root/.pyenv/shims:/root/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/axel/bin:/usr/local/go/bin:/root/bin
DIRNAME=/var/lib/tftpboot
BACKUPDIR=/windows/10.10.13.236/network/
DATETIME=`date +'%Y%m%d%H%M%S'`
LOGFILE=/var/log/custom_logs.txt
COMMAND_LIST=('/shell/network/huawei-ssh.sh 10.10.10.252 DSW3' '/shell/network/huawei-ssh.sh 10.10.10.253 DSW4' '/shell/network/huawei-ssh.sh 10.10.105.2 HX-CSW' '/shell/network/huawei-ssh.sh 10.10.16.254 HJ-DSW' '/shell/network/huawei-ssh.sh 10.10.16.251 ASW1' '/shell/network/huawei-ssh.sh 10.10.16.252 ASW2' '/shell/network/huawei-ssh.sh 10.10.16.253 ASW3' '/shell/network/huasan-telnet-password.sh 192.168.2.31 UA-ASW01' '/shell/network/huasan-telnet-password.sh 192.168.2.32 UA-ASW02' '/shell/network/huasan-telnet-password.sh 192.168.2.33 UA-ASW03' '/shell/network/huasan-telnet-password.sh 192.168.2.34 UA-ASW04' '/shell/network/huasan-telnet-password.sh 192.168.2.35 UA-ASW05' '/shell/network/huasan-telnet-password.sh 192.168.2.36 UA-ASW06' '/shell/network/huasan-telnet-user-password.sh 192.168.2.37 UA-ASW07' '/shell/network/cisco-telnet.sh 10.10.102.7 MSW' '/shell/network/huawei-firewall-ssh.sh 10.10.103.9 HUAWEI-FW02' '/shell/network/huawei-firewall-ssh.sh 10.10.103.10 HUAWEI-FW01' )

# backup file
for i in ${!COMMAND_LIST[*]};do
	backup_ipaddress=`echo "${COMMAND_LIST[$i]}" | awk '{printf("%s-%s",$3,$2)}'`
	backup_filename_prefix=`echo "${COMMAND_LIST[$i]}" | awk -v dt=${DATETIME} '{printf("%s-%s",$3,dt)}'`
	eval ${COMMAND_LIST[$i]} ${DATETIME} && test -f ${DIRNAME}/${backup_filename_prefix}*
	if [ $? == 0 ];then
		echo "`date +'%Y-%m-%d %T: ' `backup network files from ${backup_ipaddress} successful." >> ${LOGFILE}
	else 
		echo "`date +'%Y-%m-%d %T: ' `backup network files from ${backup_ipaddress} failure." >> ${LOGFILE}
	fi
	sleep 1
done

# test file size 
sleep 10
cd ${DIRNAME}
backup_filename=`ls -lt *SW* *FW* | grep $(date +'%Y%m%d') | awk '{print $9}'`
for i in ${backup_filename};do
	file_size=`ls -l ${i} | awk '{ print $5 }'`
	standard_file_size=$((1*1))
	if [ ${file_size} -lt ${standard_file_size} ];then
		echo "`date +'%Y-%m-%d %T: ' `backup network files ${i} size less than ${standard_file_size} byte. backup failed" >> ${LOGFILE} 	
	fi
done

# copy file to backup
\cp -af ${DIRNAME}/*${DATETIME}* ${BACKUPDIR} && echo "`date +'%Y-%m-%d %T: ' `copy new backup network files successful." >> ${LOGFILE} || echo "`date +'%Y-%m-%d %T: ' `copy new backup network files failure." >> ${LOGFILE}

# delete old files
find ${DIRNAME} -name "*SW*" -mtime +7 -exec rm -f {} \;
find ${DIRNAME} -name "*FW*" -mtime +7 -exec rm -f {} \;
