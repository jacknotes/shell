#!/bin/bash
# date: 20250305
# author: JackLi
# description: process iptables INPUT chain and FORWARD chain rules, valid for host and container service.
# version: v2


host_var(){
        declare -g -a LOCALHOST_PORTS=('9100 8088')
        declare -g -a LOCALHOST_IP_BLACK_LIST=('10.10.13.0/24' '192.168.2.0/24')
        declare -g -a LOCALHOST_IP_WHITE_LIST=('192.168.2.219 10.10.13.236')
}

container_var(){
        # HOST_PORT:CONTAINER_PORT
        declare -g -a CONTAINER_PORTS=('8080:80 8081:80')
        declare -g -a CONTAINER_IP_BLACK_LIST=('10.10.13.0/24' '192.168.2.122')
        declare -g -a CONTAINER_IP_WHITE_LIST=('192.168.2.219 10.10.13.236')
}

init_var(){
        tag=''
        nums=''
        IPTABLES_ACTION_DROP='DROP'
        IPTABLES_ACTION_ACCEPT='ACCEPT'
        EXECUTE_ACTION_MAKE='make'
        EXECUTE_ACTION_REMOVE='remove'
        IPTABLES_NUMS_TYPE_HOST='host'
        IPTABLES_NUMS_TYPE_CONTAINER='container'
        host_var
        container_var
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

get_iptables_numbers(){
        if [[ "$1" == "$IPTABLES_NUMS_TYPE_HOST" ]];then
                nums=`iptables -t filter -vnL INPUT --line-numbers | tail -n 1 | awk '{print $1}'`
        elif [[ "$1" == "$IPTABLES_NUMS_TYPE_CONTAINER" ]];then
                nums=`iptables -t filter -vnL FORWARD --line-numbers | grep -vE '(DOCKER|docker|br)' | tail -n 1 | awk '{print $1}'`
        fi

        # default vale is 1
        if ! expr "$nums" : '^[0-9]\+$' >& /dev/null ;then
                nums='1'
        elif [ "$nums" -gt 0 ];then
                nums=$( expr $nums + 1 )
        fi
}

process_host_iptables_rule(){
        get_iptables_numbers "$IPTABLES_NUMS_TYPE_HOST"
        if [[ "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                if [[ "$3" == "ACCEPT" ]];then
                        iptables -t filter -I INPUT 1 -p tcp -s ${2} --dport ${1} -j ${3}
                elif  [[ "$3" == "DROP" ]];then
                        iptables -t filter -I INPUT ${nums} -p tcp -s ${2} --dport ${1} -j ${3}
                fi

                if [ $? -eq 0 ];then
                        echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} successful"
                else
                        echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} failure"
                fi
        elif [[ "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                iptables -t filter -D INPUT -p tcp -s ${2} --dport ${1} -j ${3}
                if [ $? -eq 0 ];then
                        echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} successful"
                else
                        echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${2} -> 0.0.0.0:${1} ${3} failure"
                fi
        fi
}

process_container_iptables_rule(){
        get_iptables_numbers "$IPTABLES_NUMS_TYPE_CONTAINER"
        if [[ "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                if [[ "$4" == "ACCEPT" ]];then
                        iptables -t filter -I FORWARD 1 -p tcp -s ${3} -d ${1} --dport ${2} -j ${4}
                elif  [[ "$4" == "DROP" ]];then
                        iptables -t filter -I FORWARD ${nums} -p tcp -s ${3} -d ${1} --dport ${2} -j ${4}
                fi

                if [ $? -eq 0 ];then
                        echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${3} -> ${1}:${2} ${4} successful"
                else
                        echo "[INFO] ${EXECUTE_ACTION_MAKE} iptalbles rule: ${3} -> ${1}:${2} ${4} failure"
                fi
        elif [[ "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                iptables -t filter -D FORWARD -s ${3} -p tcp -d ${1} --dport ${2} -j ${4}
                if [ $? -eq 0 ];then
                        echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${3} -> ${1}:${2} ${4} successful"
                else
                        echo "[INFO] ${EXECUTE_ACTION_REMOVE} iptalbles rule: ${3} -> ${1}:${2} ${4} failure"
                fi
        fi
}

process_host_iptables(){
        validata ${LOCALHOST_PORTS}
        localhost_port_res=$?
        if [ $localhost_port_res -eq 1 ];then
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

        echo -e "####################\n       HOST     \n####################"
        # make
        for i in ${LOCALHOST_PORTS[*]};do
                # make white_list
                if [ $white_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_WHITE_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_ACCEPT}
                                elif [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_ACCEPT}) iptables INPUT chain rule already exists!!!"
                                elif [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_ACCEPT}) iptables INPUT chain rule not exists!!!"
                                fi
                        done
                fi

                # make black_list
                if [ $black_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_BLACK_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_DROP}
                                elif [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_DROP}) iptables INPUT chain rule already exists!!!"
                                elif [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> 0.0.0.0:${i} ${IPTABLES_ACTION_DROP}) iptables INPUT chain rule not exists!!!"
                                fi
                        done
                fi

                # remove black_list
                if [ $black_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_BLACK_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_DROP}
                                fi
                        done
                fi

                # remove white_list
                if [ $white_res -eq 0 ];then
                        for j in ${LOCALHOST_IP_WHITE_LIST[*]};do
                                iptables -t filter -vnL INPUT | grep ":${i}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        process_host_iptables_rule ${i} ${j} ${IPTABLES_ACTION_ACCEPT}
                                fi
                        done
                fi
        done
}

process_container_iptables(){
        validata ${CONTAINER_PORTS}
        container_port_res=$?
        if [ $container_port_res -eq 1 ];then
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


        echo -e "####################\n     CONTAINER     \n####################"
        # make and remove
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

                # make white_list
                if [ $white_res -eq 0 ];then
                         for j in ${CONTAINER_IP_WHITE_LIST[*]};do
                                iptables -t filter -vnL FORWARD | grep "${IP}" | grep ":${PORT}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_ACCEPT}
                                elif [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_ACCEPT}) iptables FORWARD chain rule already exists!!!"
                                elif [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_ACCEPT}) iptables FORWARD chain rule not exists!!!"
                                fi
                         done
                fi

                # make black_list
                if [ $black_res -eq 0 ];then
                        for j in ${CONTAINER_IP_BLACK_LIST[*]};do
                                iptables -t filter -vnL FORWARD | grep "${IP}" | grep ":${PORT}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_DROP}
                                elif [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_MAKE}" ]];then
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_DROP}) iptables FORWARD chain rule already exists!!!"
                                elif [[ $result != 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        echo "[INFO] (${j} -> ${IP}:${PORT} ${IPTABLES_ACTION_ACCEPT}) iptables FORWARD chain rule not exists!!!"
                                fi
                        done
                fi

                # remove black_list
                if [ $black_res -eq 0 ];then
                        for j in ${CONTAINER_IP_BLACK_LIST[*]};do
                                iptables -t filter -vnL FORWARD | grep "${IP}" | grep ":${PORT}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_DROP}
                                fi
                        done
                fi

                # remove white_list
                if [ $white_res -eq 0 ];then
                         for j in ${CONTAINER_IP_WHITE_LIST[*]};do
                                iptables -t filter -vnL FORWARD | grep "${IP}" | grep ":${PORT}" | grep "${j}" >& /dev/null
                                result=$?
                                if [[ $result == 0 && "$tag" == "${EXECUTE_ACTION_REMOVE}" ]];then
                                        process_container_iptables_rule ${IP} ${PORT} ${j} ${IPTABLES_ACTION_ACCEPT}
                                fi
                        done

                fi
        done
}

show_iptables(){
        echo -e '##########################'
        echo "[ HOST INFO ] LOCALHOST_PORTS: ${LOCALHOST_PORTS[*]}, LOCALHOST_IP_BLACK_LIST: ${LOCALHOST_IP_BLACK_LIST[*]}, LOCALHOST_IP_WHITE_LIST: ${LOCALHOST_IP_WHITE_LIST[*]}"
        echo "[ CONTAINER INFO ] CONTAINER_PORTS(HOST_PORT:CONTAINER_PORT): ${CONTAINER_PORTS[*]}, CONTAINER_IP_BLACK_LIST: ${CONTAINER_IP_BLACK_LIST[*]}, CONTAINER_IP_WHITE_LIST: ${CONTAINER_IP_WHITE_LIST[*]}"
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
                if [[ "$2" == "$IPTABLES_NUMS_TYPE_HOST" ]];then
                        process_host_iptables $tag
                elif [[ "$2" == "$IPTABLES_NUMS_TYPE_CONTAINER" ]];then
                        process_container_iptables $tag
                elif [[ "$2" == "all" ]];then
                        process_host_iptables $tag
                        process_container_iptables $tag
                else
                        echo "Example: $0 { ${EXECUTE_ACTION_MAKE} | ${EXECUTE_ACTION_REMOVE} } { ${IPTABLES_NUMS_TYPE_HOST} | ${IPTABLES_NUMS_TYPE_CONTAINER} | all }"
                        exit 1
                fi
        ;;

        show)
                show_iptables
        ;;

        *)
                echo "Usage $0 ACTION | show"
                echo "where  ACTION := { ${EXECUTE_ACTION_MAKE} | ${EXECUTE_ACTION_REMOVE} } { ${IPTABLES_NUMS_TYPE_HOST} | ${IPTABLES_NUMS_TYPE_CONTAINER} | all }"
        ;;
esac
