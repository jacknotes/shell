#!/bin/sh

ES_ADDRESS='http://10.10.13.99:9200'
ES_REPO_NAME='/_snapshot/backup'
ES_SNAPSHOT_NAME="snapshot_`date +'%Y%m%d%H%M%S'`"
DATETIME="date +'%Y-%m-%d_%H-%M-%S'"
LOG_FILE="/mydata/logs/eslog.txt"


Log(){
	echo "`eval ${DATETIME}`: $1" >> ${LOG_FILE}
}

GetRepo(){
	esRepoType=`curl -s -X GET "${ES_ADDRESS}${ES_REPO_NAME}" | jq .backup.type`
	if [ -n "${esRepoType}" ];then
		echo 1
	else
		echo 0
	fi
}

Snapshot(){
	sum=0
	count=1800
	# snapshot
	Log "start snapshot ${ES_SNAPSHOT_NAME}..."
	curl -s -X PUT "${ES_ADDRESS}${ES_REPO_NAME}/${ES_SNAPSHOT_NAME}?wait_for_completion=true" >& /dev/null

	# get snapshot state
	while [ ${sum} -lt ${count} ];do
		snapshotState=`curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/${ES_SNAPSHOT_NAME}" | jq .snapshots[].state`
		if [ ${snapshotState} == '"SUCCESS"' ];then
			Log "snapshot ${ES_SNAPSHOT_NAME} success!"
			return 0
		fi
		let sum+=1
		sleep 1
	done

	if [ ${sum} -eq ${count} ];then
		Log "snapshot ${ES_SNAPSHOT_NAME} failure!"
		exit 10
	fi
}

DeleteSnapshot(){
	# reserve snapshot number
	reserveNumber=7
	snapshotNameList=(`curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/_all" | jq .snapshots[].snapshot | sort -n`)
	snapshotNumber=`echo ${#snapshotNameList[*]}`
	if [ ${snapshotNumber} -gt ${reserveNumber} ];then
		let i=${snapshotNumber}-${reserveNumber}-1
		for j in `seq 0 $i`;do
			formatSnapshotName=`echo ${snapshotNameList[$j]} | tr -dc 'a-zA-Z0-9_'`
			Log "start delete ${formatSnapshotName}..."
			curl -s -X DELETE "${ES_ADDRESS}${ES_REPO_NAME}/${formatSnapshotName}" >& /dev/null
			curl -s -XGET "${ES_ADDRESS}${ES_REPO_NAME}/_all" | jq .snapshots[].snapshot | grep ${formatSnapshotName} && Log "delete ${formatSnapshotName} failure" || Log "delete ${formatSnapshotName} success"
		done
	fi
}

echo ' ' >> ${LOG_FILE}
if [ `GetRepo` == 1 ];then
	Snapshot
	DeleteSnapshot
else
	Log "repo not exists, snapshot failure!"
	exit 10
fi
	
