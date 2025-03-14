#!/bin/sh
#date: 20210226-15:40
#description: get xenserver snapshot status.

VM_HOST_PREFIX="192.168.13."
VM_HOST_SUBFIX="60 61 240 241 243 245 246 248 249"
LOGFILE="/tmp/xenserver-snapshot-status.log"
JOB_FILE="/tmp/job-xenserver.txt"
CRON_HOST="192.168.13.236"

echo "HOST: ${CRON_HOST}" > ${LOGFILE}
echo "DATETIME: `date +'%Y-%m-%d-%T'`" >> ${LOGFILE}
echo "XENSERVER SNAPSHOT STATUS:" >> ${LOGFILE}
for i in ${VM_HOST_SUBFIX};do
	echo "---------BEGIN----------" >> ${LOGFILE}
	REMOTE_HOSTNAME=`ssh root@${VM_HOST_PREFIX}${i} 'hostname'`
	ssh root@${VM_HOST_PREFIX}${i} "cat /tmp/snapshot-${REMOTE_HOSTNAME}.log" >> ${LOGFILE}
	echo "----------END-----------" >> ${LOGFILE}
done

#send mail
#/shell/xenserver/send_mail_xenserver.sh
for i in ${LOGFILE};do
	dos2unix ${i} >& /dev/null
	cat ${i} >> ${JOB_FILE}
	echo "" >> ${JOB_FILE}
done

cat ${JOB_FILE} | mail -s "xenserver snapshot status" jack.li@homsom.com
[ $? == 0 ] && rm -rf ${JOB_FILE}

