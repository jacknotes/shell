#!/bin/bash

CURRENT_BRANCH=`git branch | grep '*' | awk '{print $2}'`
if [ "${CURRENT_BRANCH}" == "pro" ];then
	SRC_CURL_HOST='192.168.13.31'
elif [ "${CURRENT_BRANCH}" == "prepro" ];then
	SRC_CURL_HOST='192.168.13.90'
elif [ "${CURRENT_BRANCH}" == "test" ];then
	SRC_CURL_HOST='192.168.13.220'
fi
	
branch_copy(){
	git pull origin ${CURRENT_BRANCH} && git checkout -b $1
	if [ $? != 0 ];then
		echo "[ERROR] branch_copy"
		exit 10
	fi
}

replace(){
	if [ "$1" == "pro" ];then
		CLUSTER='https://kubernetes.default.svc'
		PROJECT='homsom'
		CURL_HOST='192.168.13.31'
	elif [ "$1" == "prepro" ];then
		CLUSTER='https://k8s-api-prepro.hs.com:6443'
		PROJECT='prepro-homsom'
		CURL_HOST='192.168.13.90'
	elif [ "$1" == "test" ];then
		CLUSTER='https://k8s-api-test.hs.com:6443'
		PROJECT='test-homsom'
		CURL_HOST='192.168.13.220'
	fi
	
	
	sed -i -e "s/name\:\ ${CURRENT_BRANCH}/name\:\ $1/g" \
		-e "s@server\:\ .*@server: ${CLUSTER}@g" \
		-e "s/project\:\ .*/project\:\ ${PROJECT}/g" \
		-e "s/targetRevision\:\ .*/targetRevision\:\ $1/g" rollout-application.yaml && \
	sed -i "s/${SRC_CURL_HOST}/${CURL_HOST}/g" README.md  && \
	sed -i 's/averageUtilization.*/averageUtilization: 200/g' deploy/04-hpa.yaml && \
	sed -i -e 's/initialDelaySeconds:.*/initialDelaySeconds: 40/g' \
		-e 's/replicas:.*/#replicas: 2/g' deploy/01-rollout.yaml
	if [ $? != 0 ];then
		echo "[ERROR] replace"
		exit 10
	fi
}

push_repo(){
	git add -A && git commit -m "update" && git push origin $1 && git branch -a
}

apply_rollout(){
	ARGOCD_CLUSTER='k8s-pro'
	ezctl checkout ${ARGOCD_CLUSTER} && \
	kubectl apply -f rollout-project.yaml -f rollout-application.yaml
	if [ $? == 0 ];then
                echo "[INFO] apply argocd rollout SUCCESSFUL"
        else
                echo "[ERROR] apply argocd rollout FAILUE"
        fi
}

case "$1" in
	pro|prepro)
		branch_copy $1
		replace $1
		push_repo $1
		apply_rollout
		;;
	*)
		echo $"Usage: $0 [pro|prepro]"
		exit 10
		;;
esac
