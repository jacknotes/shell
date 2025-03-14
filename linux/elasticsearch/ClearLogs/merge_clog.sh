#!/bin/sh
LOG_FILE=/mydata/logs/clog.log
DATETIME='date +"%Y-%m-%d %H:%M:%S"'
ES_ADDRESS='http://clog.domain.com:9200/clog'

echo "`eval ${DATETIME}`: start merge ${ES_ADDRESS} data... " >> ${LOG_FILE}

curl -s -H'Content-Type:application/json' -XPOST "${ES_ADDRESS}/_forcemerge?only_expunge_deletes=true&max_num_segments=1"

echo "`eval ${DATETIME}`: merge ${ES_ADDRESS} data finished... " >> ${LOG_FILE}
echo '' >>${LOG_FILE}
