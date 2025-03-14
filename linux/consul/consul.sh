#!/bin/bash
# consul registry and deregistry script


function deregistry(){
	curl -X PUT http://localhost:8500/v1/agent/service/deregister/$1
	curl -X PUT http://10.10.13.237:8500/v1/agent/service/deregister/$1
}

function registry(){
	FULL_FILENAME=`realpath $1`
	curl -X PUT -d @$FULL_FILENAME http://localhost:8500/v1/agent/service/register
	curl -X PUT -d @$FULL_FILENAME http://10.10.13.237:8500/v1/agent/service/register
}

case "$1" in
	deregistry)
		deregistry $2
		;;
	registry)
		registry $2
		;;
	*)
		echo $"Usage: $0 [ deregistry ID | registry FILENAME_PATH ]"
		exit 2
		;;
esac
