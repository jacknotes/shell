#!/bin/sh

OPS_DIRECTORY="/var/log/ops"
HARBOR_LOG_FILE="${OPS_DIRECTORY}/harbor.log"

grep -A 100000 "DATETIME: `date +'%F'`" ${HARBOR_LOG_FILE} | mail -s "harbor clear status" user@domain.com
