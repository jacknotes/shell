#!/bin/sh
# describe: iamge build and k8s deploy
# author: Jackli
# datetime: 2025-04-01


# init variables
Repository='harborrepo.domain.com'
Username='jenkins'
Password='jenkinsPASSWORD'
ALiYunRepository='registry.cn-shanghai.aliyuncs.com'
ALiYunUsername='test@aliyun.com'
ALiYunPassword='repoPASSWORD'
ALiYunProjectName=${DeployENV}
MirrorName=`echo ${JOB_NAME,,}`
TagNameData="v"$(date +"%Y%m%d%H%M%S")
TagNameNumber="${BUILD_NUMBER}"
TagNameGitHash=`git log -n 1 --pretty=format:'%h'`
TagName="${TagNameData}-${TagNameNumber}-${TagNameGitHash}"
shelldir="/shell"
DateFile="${shelldir}/.date"
CurrentDate=$(date +"%d")
LANGUAGE=${Language-null}
VUE=$1
# diff master
JENKINS_USER='jenkinsagent'
PUBLISH_PASSWORD='publishPASSWORD'
ProjectImageName="${PublishEnvironment}/${MirrorName}:${TagName}"
FullProjectImageName="${Repository}/${PublishEnvironment}/${MirrorName}:${TagName}"
AliyunFullProjectImageName="${ALiYunRepository}/${ALiYunProjectName}/${MirrorName}:${TagName}"
ENV_FAT='fat'
ENV_UAT='uat'
ENV_PREPRO='prepro'
ENV_PRO='pro'
ENV_domain='domain-hs'
ENV_ALIYUN='domain-aliyun'
BuildOrCopy=`echo ${BuildOrCopy-build} | tr 'A-Z' 'a-z'`
ACTION_BUILD='build'
ACTION_COPY='copy'


### k8s environment
GIT_K8S_ADDRESS_PREFIX='git@gitlab.domain.com:k8s-deploy'
[ ${LANGUAGE} == 'null' ] && LANGUAGE=frontend
[ ${LANGUAGE} == '.netCore' ] && LANGUAGE=dotnet
[ ${LANGUAGE} == 'java' ] && LANGUAGE=java
GIT_K8S_PROJECT_NAME=`echo ${MirrorName} | sed 's/\./-/g'`
GIT_K8S_PROJECT_FULLNAME=${GIT_K8S_ADDRESS_PREFIX}/${LANGUAGE}-${GIT_K8S_PROJECT_NAME}.git
GIT_K8S_ZONE_ENV=${DeployENV}
GIT_K8S_PROJECT_ENV=${PublishEnvironment}
GIT_K8S_PROJECT_BRANCH=${GIT_K8S_PROJECT_ENV}
GIT_K8S_PROJECT_BRANCH_FOR_TEST='test'
GIT_K8S_LOCAL_REPODIR='/git'
GIT_K8S_LOCAL_REPODIR_FOR_COPY='/git-copy'
GIT_K8S_PRODUCT_IMAGE_FILE='deploy/01-rollout.yaml'
DATETIME_STAMP="date +'%F %T'"

### copy image environment
PEER_ENV=''
PEER_IMAGE_VERSION=''
CURRENT_IAMGE_VERSION=''


export PATH=$PATH:/usr/local/node/bin:/usr/local/maven/bin

# log format
log_info(){
        if [ $# -lt 1 ]; then
                echo "argument less than 1"
                exit 1
        fi

        printf "`eval $DATETIME_STAMP`: [INFO] $1\n"
}

log_fail(){
        if [ $# -lt 1 ]; then
                echo "argument less than 1"
                exit 1
        fi

        printf "`eval $DATETIME_STAMP`: [ERROR] $1\n"
}


init(){
        printf "
----------------------------------
        DeployENV: ${DeployENV}
        PublishEnv: ${PublishEnvironment}
        Language: ${LANGUAGE}
        GitBrance: ${GitBranchName}
        BuildOrCopy: ${BuildOrCopy}
----------------------------------\n"

        group=`ls -l -d /shell | awk '{print $4}'`
        [ ${group} == ${JENKINS_USER} ] || (sudo /usr/bin/chgrp -R ${JENKINS_USER} ${shelldir}; sudo /usr/bin/chmod -R 770 ${shelldir})
        [ -f ${DateFile} ] || (sudo /usr/bin/touch ${DateFile}; sudo /usr/bin/chgrp ${JENKINS_USER} ${DateFile}; sudo /usr/bin/chmod 770 ${DateFile})
        [ -z ${DateFile} ] && echo $(date +"%d") > ${DateFile}
        Date=$(cat ${DateFile})

        if [[ "${DeployENV}" == "${ENV_ALIYUN}" ]] && [[ "${PublishEnvironment}" != "${ENV_PRO}" ]]; then
                log_fail "${ENV_ALIYUN} only allow ${ENV_PRO} environment!"
                exit 10
        fi

        if [[ "${DeployENV}" == "${ENV_ALIYUN}" ]] && [[ "${BuildOrCopy}" == "${ACTION_COPY}" ]]; then
                log_fail "${ENV_ALIYUN} not allow use "${ACTION_COPY}"!"
                exit 10
        fi


        if [[ "${DeployENV}" == "${ENV_HOMSOM}" ]] && [[ "${PublishEnvironment}" == "${ENV_FAT}" || "${PublishEnvironment}" == "${ENV_UAT}" ]] && [[ "${BuildOrCopy}" == "${ACTION_COPY}" ]]; then
                log_fail "${ENV_HOMSOM} only allow ${ENV_PRO}/${ENV_PREPRO} environment "${ACTION_COPY}"!"
                exit 10
        fi

        if [[ "${PublishEnvironment}" == "${ENV_PRO}" || "${PublishEnvironment}" == "${ENV_PREPRO}" ]]  && [[ "${PublishPassword}" != "${PUBLISH_PASSWORD}" ]];then
                log_fail "publish password wrong!"
                exit 10
        fi
}

compile(){
	# java 
	if [[ ${LANGUAGE} == 'java' ]];then
	        log_info 'java comple start'
	        echo "[INFO]: start build java project"
	        if [[ `head -n 1 Dockerfile | grep -i jdk21` ]];then
	                # jdk21
	                echo "[INFO]: Use jdk21 compile"
	                container_dir='/jdk21'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/jdk21-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/java/ops_jdk21-maven3_3_9:v1 mvn clean package -U -Dmaven.test.skip=true
	                if [ $? == 0 ];then
	                        echo "[INFO]: Java Project Build Succeed" 
	                else
	                        echo "[ERROE]: Java Project Build Failure" 
	                        exit 10
	                fi
	        else
	                # jdk8
	                echo "[INFO]: Use jdk8 compile"
	                mvn clean package -U -Dmaven.test.skip=true
	                if [ $? == 0 ];then
	                        echo "[INFO]: Java Project Build Succeed" 
	                else
	                        echo "[ERROE]: Java Project Build Failure" 
	                        exit 10
	                fi
	        fi
	        log_info 'java comple end'
	fi
	
	# build vue frontend project
	if [[ ${VUE} == "vue" ]];then
		log_info 'vue comple start'
		echo "[INFO]: start build vue frontend project"
	        if [[ `head -n 1 Dockerfile | grep -i node18` ]];then
	                # node18
	                echo "[INFO]: Use node18 compile"
	                container_dir='/node18'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node18-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:18.0.0-buster npm install && npm run build
	                #sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node18-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:18.19.0-buster npm install && npm run build
	        elif [[ `head -n 1 Dockerfile | grep -i node20` ]];then
	                # node20
	                echo "[INFO]: Use node20 compile"
	                container_dir='/node20'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node20-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:20.8.0-buster npm install && npm run build
	        elif [[ `head -n 1 Dockerfile | grep -i node21` ]];then
	                # node21
	                echo "[INFO]: Use node21 compile"
	                container_dir='/node21'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node21-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:21.7.3-alpine npm install && npm run build
	        elif [[ `head -n 1 Dockerfile | grep -i node22` ]];then
	                # node22
	                echo "[INFO]: Use node22 compile"
	                container_dir='/node22'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node22-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:22.12.0-alpine npm install && npm run build
	                #sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node22-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:22.13.0-alpine3.21 npm install && npm run build
	        elif [[ `head -n 1 Dockerfile | grep -i node23` ]];then
	                # node23
	                echo "[INFO]: Use node23 compile"
	                container_dir='/node23'
	                sudo docker run --privileged --rm --workdir "${container_dir}" -v /data/node23-root:/root -v `pwd`:${container_dir} harborrepo.hs.com/base/node:23.7.0-alpine npm install && npm run build
	        else
	                # node16
	                echo "[INFO]: Use node16 compile"
			DIR='node_modules/tiptap-extensions/node_modules'
			[ -d "${DIR}-" ] && rm -rf "${DIR}-"
			npm install && [ -d ${DIR} ] && mv -f ${DIR} ${DIR}-
			npm run build
	        fi
	
		if [ $? == 0 ];then
		        echo "[INFO]: Vue FrontEnd Project Build Succeed" 
		else
		        echo "[ERROE]: Vue FrontEnd Project Build Failure" 
		        exit 10
		fi
		log_info 'vue comple end'
	fi
}

docker_build(){
        log_info "starting build image ${ProjectImageName}"
        sudo docker build -t ${ProjectImageName} . 
        if [ $? == 0 ];then
                log_info "build image success"
        else
                log_fail "build image fail"
                delete_cache_container
                exit 10
        fi
}

docker_tag_image(){
        log_info "tag image ${ProjectImageName} To ${FullProjectImageName}"
        sudo docker tag ${ProjectImageName} ${FullProjectImageName}
        if [ $? == 0 ];then
                log_info "tag image success"
        else
                log_fail "tag image fail"
                exit 10
        fi
}

docker_login(){
        log_info "login ${Repository}"
        sudo docker login -u ${Username} -p ${Password} ${Repository} >& /dev/null
        if [ $? == 0 ];then
                log_info "login success"
        else
                log_fail "login fail"
                exit 10
        fi
}

docker_push_image(){
        log_info "push image ${FullProjectImageName}"
        sudo docker push ${FullProjectImageName}
        if [ $? == 0 ];then
                log_info "push image success"
        else
                log_fail "push image fail"
                exit 10
        fi
}

aliyun_docker_tag_image(){
        log_info "tag image ${FullProjectImageName} to ${AliyunFullProjectImageName}"
        sudo docker tag ${FullProjectImageName} ${AliyunFullProjectImageName}
        if [ $? == 0 ];then
                log_info "tag aliyun image success"
        else
                log_fail "tag aliyun image fail"
                exit 10
        fi
}

aliyun_docker_login(){
        log_info "login ${ALiYunRepository}"
        sudo docker login -u ${ALiYunUsername} -p ${ALiYunPassword} ${ALiYunRepository} >& /dev/null
        if [ $? == 0 ];then
                log_info "login aliyun repository success"
        else
                log_fail "login aliyun repository fail"
                exit 10
        fi
}

aliyun_docker_push_image(){
        log_info "push aliyun image"
        sudo docker push ${AliyunFullProjectImageName}
        if [ $? == 0 ];then
                log_info "push aliyun image success"
        else
                log_fail "push aliyun image fail"
                exit 10
        fi
}

delete_aliyun_local_image(){
        log_info "delete local image ${AliyunFullProjectImageName}"
        sudo docker image rm ${AliyunFullProjectImageName}
        if [ $? == 0 ];then
                log_info "delete aliyun local image success"
        else
                log_fail "delete aliyun local image fail"
        fi
}

delete_local_image(){
        log_info "delete local image ${ProjectImageName}, ${FullProjectImageName}"
        sudo docker image rm ${ProjectImageName} ${FullProjectImageName}
        if [ $? == 0 ];then
                log_info "delete local image success"
        else
                log_fail "delete local image fail"
        fi
}

delete_cache_container(){
        # delete docker container is Exited.
        log_info "delete docker container status is exited"
	Exited_Containers=$(sudo docker ps -a | egrep -v 'CONTAINER|redis|uatHotelES|cadvisor|es_admin|rsyslog|jms_guacamole|nacos-standalone' |  grep -E 'Exited|Created' |  awk '{print $1}')
        for i in ${Exited_Containers};do
                sudo docker rm -fv $i
        done

        # delete local name is <none> image
        log_info "delete docker image name is <none>"
        NoNameImage=$(sudo docker image ls | grep '<none>' | awk '{print $3}')
        for i in ${NoNameImage};do
                sudo docker image rm $i
        done
}


#### k8s copy code 

git_k8s_clone_for_copy(){
	[ -d ${GIT_K8S_LOCAL_REPODIR_FOR_COPY} ] || sudo mkdir -p ${GIT_K8S_LOCAL_REPODIR_FOR_COPY}

	cd ${GIT_K8S_LOCAL_REPODIR_FOR_COPY}

	if [ "${PublishEnvironment}" == "${ENV_PRO}" ];then
		PEER_ENV="${ENV_PREPRO}"
	elif [ "${PublishEnvironment}" == "${ENV_PREPRO}" ];then
		PEER_ENV="${ENV_PRO}"
	fi

	# get peer product enviroment image version
	if [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV} == "${ENV_PRO}" ];then
		log_info "Clone -b ${PEER_ENV} ${GIT_K8S_PROJECT_FULLNAME}"
		sudo rm -rf ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
		sudo git clone -b ${PEER_ENV} ${GIT_K8S_PROJECT_FULLNAME} 
	elif [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV}  == "${ENV_PREPRO}" ];then
		log_info "Clone -b ${PEER_ENV} ${GIT_K8S_PROJECT_FULLNAME}"
		sudo rm -rf ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
		sudo git clone -b ${PEER_ENV} ${GIT_K8S_PROJECT_FULLNAME} 
	fi

        if [ $? == 0 ];then
                log_info "clone success"
        else
                log_fail "clone fail"
                exit 10
        fi
}

# only allow in ${GIT_K8S_LOCAL_REPODIR_FOR_COPY} directory use
git_k8s_get_image_version_for_copy(){
	cd ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
	PEER_IMAGE_VERSION=`sudo grep 'image:' ${GIT_K8S_PRODUCT_IMAGE_FILE} | awk '{print $2}'`
        echo ${PEER_IMAGE_VERSION} | grep -i ${MirrorName} >& /dev/null && \
                echo ${PEER_IMAGE_VERSION} | grep -r "/${PEER_ENV}/" >& /dev/null
        if [ $? != 0 ];then
                log_fail "${PEER_ENV} environment image version ${PEER_IMAGE_VERSION} unlawful"
                return 1
        else
                log_info "${PEER_ENV} environment image version ${PEER_IMAGE_VERSION} lawful"
                return 0
        fi
}

git_k8s_copy_image_for_copy(){
        log_info "starting from ${PEER_ENV} environment copy image to ${PublishEnvironment} environment"
        CURRENT_IAMGE_VERSION=`echo $1 | sed "s@/${PEER_ENV}/@/${PublishEnvironment}/@g"`
        echo ${CURRENT_IAMGE_VERSION} | grep -i ${MirrorName} >& /dev/null && \
                echo ${CURRENT_IAMGE_VERSION} | grep -i "/${PublishEnvironment}/" >& /dev/null
        if [ $? == 0 ];then
                log_info "${PEER_ENV}:$1  ${PublishEnvironment}:${CURRENT_IAMGE_VERSION}"
                sudo docker pull $1 && \
                sudo docker tag $1 ${CURRENT_IAMGE_VERSION} && \
                sudo docker push ${CURRENT_IAMGE_VERSION}
                if [ $? != '0' ];then
                        log_fail "push image ${CURRENT_IAMGE_VERSION} fail"
                        exit 10
                fi
                log_info "from ${PEER_ENV} environment copy image to ${PublishEnvironment} success"
        else
                log_fail "from ${PEER_ENV} environment copy image to ${PublishEnvironment} fail"
                exit 10
        fi
}

k8s_deploy_for_copy(){
        if [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ];then
		# get image version
                git_k8s_clone_for_copy
                git_k8s_get_image_version_for_copy && \
		git_k8s_copy_image_for_copy "${PEER_IMAGE_VERSION}"
		# update image version
		k8s_deploy "${CURRENT_IAMGE_VERSION}"
        fi
}


#### k8s build code 

git_k8s_clone(){
	[ -d ${GIT_K8S_LOCAL_REPODIR} ] || sudo mkdir -p ${GIT_K8S_LOCAL_REPODIR}

	cd ${GIT_K8S_LOCAL_REPODIR} && \
	if [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV} == "${ENV_PRO}" -o ${GIT_K8S_PROJECT_ENV} == "${ENV_PREPRO}" ];then
		log_info "Clone -b ${GIT_K8S_PROJECT_BRANCH} ${GIT_K8S_PROJECT_FULLNAME}"
		sudo rm -rf ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
		sudo git clone -b ${GIT_K8S_PROJECT_BRANCH} ${GIT_K8S_PROJECT_FULLNAME} 
	elif [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV} == "${ENV_FAT}" -o ${GIT_K8S_PROJECT_ENV} == "${ENV_UAT}" ];then
		log_info "Clone -b ${GIT_K8S_PROJECT_BRANCH_FOR_TEST} ${GIT_K8S_PROJECT_FULLNAME}"
		sudo rm -rf ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
		sudo git clone -b ${GIT_K8S_PROJECT_BRANCH_FOR_TEST} ${GIT_K8S_PROJECT_FULLNAME} 
	fi

        if [ $? == 0 ];then
                log_info "clone success"
        else
                log_fail "clone fail"
                exit 10
        fi
}

git_k8s_imageUpdate(){
	log_info "update image version"
	cd ${LANGUAGE}-${GIT_K8S_PROJECT_NAME} && \
	sudo git config --global user.name "Jenkins@master" && \
	sudo git config --global user.email "Jenkins@homsom.com"

	if [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV} == "${ENV_PRO}" -o ${GIT_K8S_PROJECT_ENV} == "${ENV_PREPRO}" ];then
		sudo sed -i "s#image:.*#image: ${1}#" ${GIT_K8S_PRODUCT_IMAGE_FILE} && \
		sudo git add -A && \
		sudo git commit -m "${1}" && \
		sudo git push origin ${GIT_K8S_PROJECT_BRANCH}
	elif [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ] && [ ${GIT_K8S_PROJECT_ENV} == "${ENV_FAT}" -o ${GIT_K8S_PROJECT_ENV} == "${ENV_UAT}" ];then
		sudo sed -i "/image/{n;s#value: .*#value: ${1}#}" kustomize/${GIT_K8S_PROJECT_ENV}/patch-deployment.yaml && \
		sudo git add -A && \
		sudo git commit -m "${1}" && \
		sudo git push origin ${GIT_K8S_PROJECT_BRANCH_FOR_TEST}
	fi

	if [ $? == 0 ];then
		log_info "update image version and git push successful, k8s deploying......, see https://argocd.k8s.hs.com/applications/${GIT_K8S_PROJECT_ENV}-${LANGUAGE}-${GIT_K8S_PROJECT_NAME}"
	else
		log_fail "update image version and git push fail"
                exit 10
	fi
}

k8s_deploy(){
        if [ ${GIT_K8S_ZONE_ENV} == "${ENV_HOMSOM}" ];then
                git_k8s_clone
                git_k8s_imageUpdate "$1"
        fi
}


k8s_log(){
	printf "
----------------------------------
	k8s stage
----------------------------------\n"
}



main(){
        log_info "BEGIN_ITME"

        init

        if [[ ${CurrentDate} != ${Date} ]];then
                delete_cache_container
                echo $(date +"%d") > ${DateFile}
        fi

        #if ([[ "${DeployENV}" == "${ENV_HOMSOM}" ]] && [[ "${PublishEnvironment}" == "${ENV_FAT}" || "${PublishEnvironment}" == "${ENV_UAT}" ]]) || \
        #([[ "${DeployENV}" == "${ENV_HOMSOM}" ]] && [[ "${PublishEnvironment}" == "${ENV_PREPRO}" || "${PublishEnvironment}" == "${ENV_PRO}" ]] && [[ "${BuildOrCopy}" == "${ACTION_BUILD}" ]]);then
        if [[ "${DeployENV}" == "${ENV_HOMSOM}" ]] && [[ "${PublishEnvironment}" == "${ENV_FAT}" || "${PublishEnvironment}" == "${ENV_UAT}" || "${PublishEnvironment}" == "${ENV_PREPRO}" || "${PublishEnvironment}" == "${ENV_PRO}" ]] && [[ "${BuildOrCopy}" == "${ACTION_BUILD}" ]];then
                compile
                docker_build
                docker_tag_image
                docker_login
                docker_push_image
                delete_local_image
		k8s_log
                k8s_deploy "${FullProjectImageName}"
        elif [[ "${DeployENV}" == "${ENV_ALIYUN}" ]] && [[ "${PublishEnvironment}" == "${ENV_PRO}" ]];then
                compile
                docker_build
                docker_tag_image
                aliyun_docker_tag_image
                aliyun_docker_login
                aliyun_docker_push_image
                delete_aliyun_local_image
        else
		k8s_log
		k8s_deploy_for_copy
        fi

        log_info "END_TIME"
}

main

