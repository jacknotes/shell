#!/bin/sh

ELK_INDICES_LIST='sangfor-af sangfor-ac sangfor-atrust huawei-af switch hosts-windows hosts-linux nginx-access nginx-error'
ELK_SERVER_ADDRESS='http://10.10.2.199:9200'
ELK_USERNAME='filebeat'
ELK_PASSWORD='SRGZL7Pd830UO2MeTZxS'
ELK_INDICES_GREP_STATEMENT="curl -su ${ELK_USERNAME}:${ELK_PASSWORD} ${ELK_SERVER_ADDRESS}/_cat/indices"
ELK_DELETE_INDICES_STATEMENT="curl -su ${ELK_USERNAME}:${ELK_PASSWORD} -X DELETE ${ELK_SERVER_ADDRESS}/"
ELK_RETAIN_DAYS=185
ELK_HOST_RETAIN_DAYS=30
DATETIME='date +"%Y-%m-%d %H-%M-%S"'
ROOT_LOGFILE='/mydata/logs'
LOGFILE="${ROOT_LOGFILE}/opsaudit.log"
TMPLOGFILE="${ROOT_LOGFILE}/log.tmp"


for i in ${ELK_INDICES_LIST};do
	if [[ ! "$i" =~ host.* ]];then
		TMP_INDICES_COUNT=`${ELK_INDICES_GREP_STATEMENT} | grep ${i} | wc -l`	
		TMP_INDICES_DELETE_COUNT=`echo "${TMP_INDICES_COUNT}-${ELK_RETAIN_DAYS}" | bc`
		if [ ${TMP_INDICES_DELETE_COUNT} -gt 0 ];then
			for j in `${ELK_INDICES_GREP_STATEMENT} | grep ${i}| awk '{print $3}' | sort -k 1 | head -n ${TMP_INDICES_DELETE_COUNT}`;do
				${ELK_DELETE_INDICES_STATEMENT}${j} $> /dev/null ;echo
				if [ $? != 0 ];then
					echo "`eval ${DATETIME}`: index ${j} delete failure." >> ${LOGFILE}
				else
					echo "`eval ${DATETIME}`: index ${j} delete successful." >> ${LOGFILE}
				fi
			done
		else
			echo "`eval ${DATETIME}`: this index ${i} count number is lower ${ELK_RETAIN_DAYS}, not change." >> ${LOGFILE}
		fi
	elif [[ "$i" =~ host.* ]];then
		TMP_INDICES_COUNT=`${ELK_INDICES_GREP_STATEMENT} | grep ${i} | wc -l`	
		TMP_INDICES_DELETE_COUNT=`echo "${TMP_INDICES_COUNT}-${ELK_HOST_RETAIN_DAYS}" | bc`
		if [ ${TMP_INDICES_DELETE_COUNT} -gt 0 ];then
			for j in `${ELK_INDICES_GREP_STATEMENT} | grep ${i}| awk '{print $3}' | sort -k 1 | head -n ${TMP_INDICES_DELETE_COUNT}`;do
				${ELK_DELETE_INDICES_STATEMENT}${j} $> /dev/null ;echo
				if [ $? != 0 ];then
					echo "`eval ${DATETIME}`: index ${j} delete failure." >> ${LOGFILE}
				else
					echo "`eval ${DATETIME}`: index ${j} delete successful." >> ${LOGFILE}
				fi
			done
		else
			echo "`eval ${DATETIME}`: this index ${i} count number is lower ${ELK_HOST_RETAIN_DAYS}, not change." >> ${LOGFILE}
		fi
		
	fi
done

# opsaudit
echo 'HOST: 10.10.13.236' >> ${TMPLOGFILE}
echo 'ELKNAME: opsaudit' >> ${TMPLOGFILE}
echo "DATETIME: `date +'%F-%T'`" >> ${TMPLOGFILE}
grep `date +'%Y-%m-%d'` ${LOGFILE} >> ${TMPLOGFILE}
echo ''  >> ${TMPLOGFILE}

# clog
echo 'HOST: 10.10.13.236' >> ${TMPLOGFILE}
echo 'ELKNAME: clog' >> ${TMPLOGFILE}
echo "DATETIME: `date +'%F-%T'`" >> ${TMPLOGFILE}
grep `date +'%Y-%m-%d'` "${ROOT_LOGFILE}/clog.log" >> ${TMPLOGFILE}
echo ''  >> ${TMPLOGFILE}

# hlog
echo 'HOST: 10.10.13.196' >> ${TMPLOGFILE}
echo 'ELKNAME: hlog' >> ${TMPLOGFILE}
echo "DATETIME: `date +'%F-%T'`" >> ${TMPLOGFILE}
ssh root@10.10.13.196 'tail -n 5 /shell/shell.log' >> ${TMPLOGFILE}

#send mail
cat ${TMPLOGFILE} | mail -s "everyday elk job" jack.li@homsom.com
[ $? == 0 ] && rm -rf ${TMPLOGFILE}


