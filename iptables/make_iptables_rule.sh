#!/bin/bash
# date: 20250227
# author: JackLi
# description: process iptables rules for localhost in INPUT chain and container in FORWARD chain from request

container_var(){
        # HOST_PORT:CONTAINER_PORT
        declare -g -a CONTAINER_PORTS=('8080:80 8081:80')
        declare -g -a CONTAINER_IP_BLACK_LIST=('192.168.13.0/24' '172.168.2.122')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('172.168.2.219 192.168.13.236')
}

host_var(){
        declare -g -a LOCALHOST_PORTS=('9100 8088 ')
        declare -g -a LOCALHOST_IP_BLACK_LIST=('192.168.13.0/24' '172.168.2.0/24')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('172.168.2.219 192.168.13.236')
        #declare -g -a LOCALHOST_IP_BLACK_LIST=('1.1.1.1 2.2.2.2')
        #declare -g -a LOCALHOST_IP_WHITE_LIST=('3.3.3.3' '4.4.4.4')
}

init_var(){
        tag=''
        IPTABLES_ACTION_DROP='DROP'
        IPTABLES_ACTION_ACCEPT='ACCEPT'
        EXECUTE_ACTION_MAKE='make'
        EXECUTE_ACTION_REMOVE='remove'
        container_var
        host_var
}

validata(){
        # receive all args
        local arr=("$@")
        if [ "${#arr[*]}" -lt 1 ];then
                return 1
        elif [ "${#arr[*]}" -ge 1 ];then
                return 0
        else
                echo "[ERROR] validata $arr fail"
                exit 1
        fi
}

process_container_iptables_rule(){
        if [[ "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${3} -> ${1}:${2} ${4} successful"
                iptables -t filter -I FORWARD 1 -p tcp -s ${3} -d ${1} --dport ${2} -j ${4}
        elif [[ "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${3} -> ${1}:${2} ${4} successful"
                iptables -t filter -D FORWARD -s ${3} -p tcp -d ${1} --dport ${2} -j ${4}
        fi
}

process_host_iptables_rule(){
        if [[ "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} successful"
                iptables -t filter -I INPUT 1 -p tcp -s ${2} --dport ${1} -j ${3}
        elif [[ "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} successful"
                iptables -t filter -D INPUT -p tcp -s ${2} --dport ${1} -j ${3}
        fi
}

process_container_iptables(){
        if [ ${#CONTAINER_PORTS[*]} -lt 1 ];then
                echo '[ERROR] CONTAINER_PORTS is null'
                exit 1
        fi

        validata ${CONTAINER_IP_BLACK_LIST}
        black_res=$?
        validata ${CONTAINER_IP_WHITE_LIST}
        white_res=$?
        if [ $black_res -eq 1 ] && [ $white_res -eq 1 ];then
                echo '[ERROR] CONTAINER_IP_BLACK_LIST and CONTAINER_IP_WHITE_LIST is null'
                exit 1
        fi


        echo "[INFO] CONTAINER:"
        for i in ${CONTAINER_PORTS[*]};do
                # get container IP:PORT
                HOST_PORT=`echo ${i} | awk -F ':' '{print $1}'`
                CONTAINER_PORT=`echo ${i} | awk -F ':' '{print $2}'`
                CONTAINER_IP_PORT=`iptables -t nat -vnL DOCKER | grep ":${HOST_PORT}" | grep ":${CONTAINER_PORT}"| awk -F 'to:' '{print $2}'`
                if [ -z ${CONTAINER_IP_PORT} ];then
                        echo '[ERROR] process: '"iptables -t nat -vnL DOCKER | grep \":${HOST_PORT}\" | grep \":${CONTAINER_PORT}\"| awk -F \"to:\" \"{print $2}\""' iptables rule fail!'
                        exit 1
                fi

                # parse container IP:PORT
                IP=`echo ${CONTAINER_IP_PORT} | awk -F ':' '{print $1}'`
                PORT=`echo ${CONTAINER_IP_PORT} | awk -F ':' '{print $2}'`
                if [[ -z "${IP}" ]] || [[ -z "${PORT}" ]] ;then
                        echo "[ERROR] validata IP:${IP} or PORT:${PORT} fail!"
                        exit 1
                fi

                # make iptalbes rule
                iptables -t filter -vnL FORWARD | grep ${IP} | grep ${PORT} >& /dev/null
                if [[ ( $? != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ) || ( $? == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ) ]];then
                        if [ $black_res -eq 0 ];then
                                for j in ${CONTAINER_IP_BLACK_LIST[*]};do
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_DROP}
                                done
                        fi

                        if [ $white_res -eq 0 ];then
                                 for j in ${CONTAINER_IP_WHITE_LIST[*]};do
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_ACCEPT}
                                 done
                        fi
                elif [[ $? != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                        if [ $black_res -eq 0 ];then
                                for j in ${CONTAINER_IP_BLACK_LIST[*]};do
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_DROP}) iptables rule not exists!!!"
                                done
                        fi

                        if [ $white_res -eq 0 ];then
                                 for j in ${CONTAINER_IP_WHITE_LIST[*]};do
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_ACCEPT}) iptables rule not exists!!!"
                                 done
                        fi
                else
                        if [ $black_res -eq 0 ];then
                                for j in ${CONTAINER_IP_BLACK_LIST[*]};do
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_DROP}) iptables rule already exists!!!"
                                done
                        fi

                        if [ $white_res -eq 0 ];then
                                 for j in ${CONTAINER_IP_WHITE_LIST[*]};do
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_ACCEPT}) iptables rule not exists!!!"
                                 done
                        fi
                fi
        done
}

process_host_iptables(){
        if [ ${#LOCALHOST_PORTS[*]} -lt 1 ];then
                echo '[ERROR] LOCALHOST_PORTS is null'
                exit 1
        fi

        validata ${LOCALHOST_IP_BLACK_LIST}
        black_res=$?
        validata ${LOCALHOST_IP_WHITE_LIST}
        white_res=$?
        if [ $black_res -eq 1 ] && [ $white_res -eq 1 ];then
                echo '[ERROR] LOCALHOST_IP_BLACK_LIST and LOCALHOST_IP_WHITE_LIST is null'
                exit 1
        fi

        echo "[INFO] LOCALHOST:"
        for i in ${LOCALHOST_PORTS[*]};do
                if [ $black_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_BLACK_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep ${j} >& /dev/null
                                # make or remove operation
                                if [[ ( $? != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ) || ( $? == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ) ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_DROP}
                                elif [[ $? != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_DROP}) iptables rule not exists!!!"
                                else
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_DROP}) iptables rule already exists!!!"
                                fi
                        done
                fi

                if [ $white_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_WHITE_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep ${j} >& /dev/null
                                # make or remove operation
                                if [[ ( $? != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ) || ( $? == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ) ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_ACCEPT}
                                elif [[ $? != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_ACCEPT}) iptables rule not exists!!!"
                                else
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_ACCEPT}) iptables rule already exists!!!"
                                fi
                        done
                fi
        done
}

show_iptables(){
        echo -e '##########################'
        echo "[INFO] execute host info: LOCALHOST_PORTS: ${LOCALHOST_PORTS[*]}, LOCALHOST_IP_BLACK_LIST: ${LOCALHOST_IP_BLACK_LIST[*]}, LOCALHOST_IP_WHITE_LIST: ${LOCALHOST_IP_WHITE_LIST[*]}"
        echo "[INFO] execute container info: CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): ${CONTAINER_PORTS[*]}, CONTAINER_IP_BLACK_LIST: ${CONTAINER_IP_BLACK_LIST[*]}, CONTAINER_IP_WHITE_LIST: ${CONTAINER_IP_WHITE_LIST[*]}"
        echo '##########################'
        echo ''
        echo ''

        echo "[INFO] host iptables rules "
        echo '##########################'
        iptables -t filter -vnL INPUT --line-numbers
        echo '##########################'

        echo ''
        echo ''
        echo "[INFO] container iptables rules "
        echo '##########################'
        iptables -t nat -vnL DOCKER --line-numbers
        echo ''
        iptables -t filter -vnL FORWARD --line-numbers
        echo '##########################'
        echo ''
}

init_var



case $1 in
        make|remove)
                tag="$1"
                process_container_iptables $tag
                process_host_iptables $tag
        ;;

        show)
                show_iptables
        ;;

        *)
                echo "Usage $0 [ ${EXECUTE_ACTION_MAKE} | ${EXECUTE_ACTION_REMOVE} | show ]"
        ;;
esac
