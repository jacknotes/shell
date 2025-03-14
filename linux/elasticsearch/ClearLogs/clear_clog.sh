#!/bin/sh
LOG_FILE=/mydata/logs/clog.log
DATETIME='date +"%Y-%m-%d %H:%M:%S"'
ES_ADDRESS='http://clog.domain.com:9200/clog'
DAYS=7

echo "`eval ${DATETIME}`: start clear ${ES_ADDRESS} ${DAYS} day before data... " >> ${LOG_FILE}
curl -s -H'Content-Type:application/json' -d'{
  "query": {
    "bool": {
      "must": [
        {
          "match_all": {}
        }
      ],
      "filter": {
        "range": {
          "time": {
            "time_zone": "+08:00",
            "lt":"now-'${DAYS}'d"
          }
        }
      }
    }
  }
}
' -XPOST "${ES_ADDRESS}/_delete_by_query?scroll_size=3000"


echo "`eval ${DATETIME}`: clear ${ES_ADDRESS} ${DAYS} day before data finished... " >> ${LOG_FILE}
echo '' >> ${LOG_FILE}
