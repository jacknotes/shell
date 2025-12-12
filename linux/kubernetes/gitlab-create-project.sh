#!/bin/bash
# Descrption: create gitlab project, create argocd k8s project.

# total arguments check
if [ $# != 5 ];then
	echo "用法: $0 命令 项目类型 域名 健康检查地址 应用ID"
	echo "例如：./gitlab-create-project.sh (local|aliyun|create_gitlab_project|create_argocd_project_for_local|create_argocd_project_for_aliyun) java DFlightRFlightMaster.service.hs.com /doc.html 1344"
	echo "例如：./gitlab-create-project.sh (local|aliyun|create_gitlab_project|create_argocd_project_for_local|create_argocd_project_for_aliyun) dotnet tripapplicationform.api.hs.com /index.html 1298"
	echo "例如：./gitlab-create-project.sh (local|aliyun|create_gitlab_project|create_argocd_project_for_local|create_argocd_project_for_aliyun) frontend vccoperation.hs.com /NO-PATH 1312"
	exit 1
fi

PROJECT_COMMAND=$1
PROJECT_TYPE=$2
PROJECT_DOMAIN=$3
PROJECT_HEALTH_PATH=$4
PROJECT_APPID=$5


check() {
    # 1. 检查 PROJECT_COMMAND: 只允许指定部署位置
    if ! [[ "$PROJECT_COMMAND" =~ ^(local|aliyun|create_gitlab_project|create_argocd_project_for_local|create_argocd_project_for_aliyun)$ ]]; then
        echo "[ERROR] 部署位置只能是 (local|aliyun|create_gitlab_project|create_argocd_project) 其中之一，当前值: '$PROJECT_COMMAND'"
        exit 2
    fi

    # 2. 检查 PROJECT_TYPE: 只允许指定项目类型
    if ! [[ "$PROJECT_TYPE" =~ ^(java|dotnet|frontend)$ ]]; then
        echo "[ERROR] 项目类型只能是 (java|dotnet|frontend) 其中之一，当前值: '$PROJECT_TYPE'"
        exit 2
    fi

    # 3. 检查 PROJECT_DOMAIN: 包含至少一个 '.'，且符合域名基本格式
    if [[ "$PROJECT_DOMAIN" != *"."* ]]; then
        echo "❌ 错误: 域名必须包含 '.'，当前值: '$PROJECT_DOMAIN'"
        exit 2
    fi
    # 检查 PROJECT_DOMAIN: 是否只包含字母、数字、点、连字符
    if ! [[ "$PROJECT_DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo "❌ 错误: 域名包含非法字符，只允许字母、数字、'.' 和 '-'，当前值: '$PROJECT_DOMAIN'"
        exit 2
    fi

    # 4. 检查 PROJECT_HEALTH_PATH: 必须以 '/' 开头
    if [[ "$PROJECT_HEALTH_PATH" != /* ]]; then
        echo "❌ 错误: 健康检查路径必须以 '/' 开头，当前值: '$PROJECT_HEALTH_PATH'"
        exit 2
    fi

    # 5. 检查 PROJECT_APPID: 必须是正整数
    if ! [[ "$PROJECT_APPID" =~ ^[1-9][0-9][0-9][0-9]$ ]]; then
        echo "❌ 错误: 应用ID必须是4位正整数，当前值: '$PROJECT_APPID'"
        exit 2
    fi

    echo "[INFO] 所有参数校验通过"
    #exit 1
}

create_gitlab_project(){
	source /root/.gitlab.key
	GITLAB_PROJECT_NAME="${PROJECT_TYPE}-${PROJECT_DOMAIN}"

	echo "[INFO] create gitlab project name is $GITLAB_PROJECT_NAME"
    	#echo "例如：./gitlab-create-project.sh [ java-testv1.business.service.hs.com | java-testv1-business-service-hs-com ]"
	/usr/local/bin/gitlab-create-project -token "$GITLAB_TOKEN" -project "$GITLAB_PROJECT_NAME" -webhook-url "$WEBHOOK_URL" -webhook-token "$WEBHOOK_TOKEN" -username "$GITLAB_USERNAME" -password "$GITLAB_PASSWORD" -add-project -add-project-webhook 
	if [ $? != 0 ];then
		echo "[ERROR] create gitlab project $GITLAB_PROJECT_NAME and add project webhook failure!"
		exit 1
	fi
}

create_argocd_project_for_local(){
	/root/k8s/argocd/shell/argocd-project-create.sh replace $PROJECT_TYPE $PROJECT_DOMAIN $PROJECT_HEALTH_PATH $PROJECT_APPID
}

create_argocd_project_for_aliyun(){
	/root/k8s/argocd/shell/argocd-project-create-aliyun.sh replace $PROJECT_TYPE $PROJECT_DOMAIN $PROJECT_HEALTH_PATH $PROJECT_APPID
}

case $PROJECT_COMMAND in
	local)
		check
		echo "[INFO] start create gitlab project and local project"
		create_gitlab_project
		create_argocd_project_for_local
		echo "[INFO] create gitlab project and local project successful"
		
		;;
	aliyun)
		check
		echo "[INFO] start create gitlab project and aliyun project"
		create_gitlab_project
		create_argocd_project_for_aliyun
		echo "[INFO] create gitlab project and aliyun project successful"

		;;
	create_gitlab_project)
		check
		echo "[INFO] start create gitlab project"
		create_gitlab_project
		echo "[INFO] create gitlab project successful"
		;;
	create_argocd_project_for_local)
		check
		echo "[INFO] start create local argocd project"
		create_argocd_project_for_local
		echo "[INFO] create local argocd project successful"
		;;
	create_argocd_project_for_aliyun)
		check
		echo "[INFO] start create aliyun argocd project"
		create_argocd_project_for_aliyun
		echo "[INFO] create aliyun argocd project successful"
		;;
	*)
		echo "Usage: $0 { local | aliyun | create_gitlab_project | create_argocd_project_for_local | create_argocd_project_for_aliyun }"
                exit 2
		;;
esac
