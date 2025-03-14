#!/bin/bash
# date: 20250211
# author: JackLi
# description: scan https tls version、display server_name tls version、check server_name is available

# default var
DOMAIN_NAME='markli.cn'
NGINX_CONFIG_FILE="./source/${DOMAIN_NAME}.conf"
OUTPUT_DIR='./output'
SERVER_NAME_FILE_LIST="${OUTPUT_DIR}/${DOMAIN_NAME}.servername.txt"
OUTPUT_FILE="${OUTPUT_DIR}/ssl"
TLS_TRUE="${OUTPUT_DIR}/true.txt"
TLS_FALSE="${OUTPUT_DIR}/false.txt"
STATUS_OK='ok'
STATUS_NOOK='nook'
# tls version
CONST_tls1='tls1'
CONST_tls1_1='tls1_1'
CONST_tls1_2='tls1_2'
CONST_tls1_3='tls1_3'
OUTPUT_RESULT_PREFIX="${OUTPUT_DIR}/tls"
# date
DATETIME="date +'%Y%m%d%H%M%S'"


clean(){
	mv $OUTPUT_DIR $OUTPUT_DIR`eval ${DATETIME}`
}

init(){
	mkdir -p $OUTPUT_DIR
}

generate_ServerName_file_list(){
	grep 443 -C 6 $NGINX_CONFIG_FILE | grep -E 'server_name ' | grep -v '#.*server_name' | awk '{print $2}' | tr -d ';' | sort | uniq > $SERVER_NAME_FILE_LIST
}

generate_TLSInfo(){
	for i in `cat $SERVER_NAME_FILE_LIST`;do 
		for j in tls1 tls1_1 tls1_2 tls1_3;do 
			echo "--${i}--" >> ${OUTPUT_FILE}_${j}_${i}.txt
			timeout 3 openssl s_client -connect ${i}:443 -servername ${i} -${j} | tee -a ${OUTPUT_FILE}_${j}_${i}.txt
		done
	done
}

check_tls_version(){
	for i in ${OUTPUT_FILE}*;do
		cat $i | grep 'Server certificate' &> /dev/null && \
		echo $i $STATUS_OK | tee -a ${TLS_TRUE}  || echo $i $STATUS_NOOK | tee -a ${TLS_FALSE}
	done
}

filter_func(){
	if [ $1 == "$CONST_tls1_1" ];then
		grep -E "$CONST_tls1_1" $2 > $OUTPUT_DIR/${CONST_tls1_1}$3
	elif [ $1 == "$CONST_tls1_2" ];then
		grep -E "$CONST_tls1_2" $2> $OUTPUT_DIR/${CONST_tls1_2}$3
	elif [ $1 == "$CONST_tls1_3" ];then
		grep -E "$CONST_tls1_3" $2> $OUTPUT_DIR/${CONST_tls1_3}$3
	elif [ $1 == "$CONST_tls1" ];then
		grep -E ${CONST_tls1}'_[a-zA-Z]' $2> $OUTPUT_DIR/${CONST_tls1}$3
	else
		echo "[ERROR]: filter_func $1 args is error, valid arg is '[ tls1 tls1_1 tls1_2 tls1_3 ]'"
		exit 1
	fi
}

filter_tls(){
	if [ "$2" == "$TLS_TRUE" ];then
		prefix="-${STATUS_OK}.txt"
		filter_func $1 $2 $prefix
	elif [ "$2" == "$TLS_FALSE" ];then
		prefix="-${STATUS_NOOK}.txt"
		filter_func $1 $2 $prefix
	else
		echo "[ERROR]: filter_tls $2 args is error, valid arg is ""[ $TLS_TRUE $TLS_FALSE ]"
		exit 1
	fi
}


# filter server_name display
dislpay_ServerName(){
	if [ $1 = 'all' ];then
		cat ${OUTPUT_RESULT_PREFIX}*
	else
		cat ${OUTPUT_RESULT_PREFIX}* | grep -i "$1"
	fi
}


check_output_result_IsExist(){
	ls ${SERVER_NAME_FILE_LIST} &> /dev/null && \
	ls ${OUTPUT_RESULT_PREFIX}* &> /dev/null && \
	echo 'true' || echo 'false'
}

# check server_name isAvailable
check_ServerName_Available(){
	if [ "$(check_output_result_IsExist)" == 'false' ];then
		echo "[ERROR] server_name list file AND output result files Not Exists!"
                exit 1
	fi	

	for i in `cat $SERVER_NAME_FILE_LIST`;do 
		result_list=(`cat ${OUTPUT_RESULT_PREFIX}* | grep $i | awk '{print $2}' | sort -t 1 | uniq`)
		if [ "${#result_list[*]}" -eq 1 ];then
			if [ "${result_list[0]}" == "${STATUS_OK}" ];then
				echo "[INFO] $i is Available"
			else
				echo "[INFO] $i is UnAvailable"
			fi			
		elif [ "${#result_list[*]}" -eq 2 ];then
			echo "[INFO] $i is Available"
		else
			echo "[ERROR] parse error, valid value is [ $STATUS_OK $STATUS_NOOK ]"
			exit 1
		fi
	done
}

main(){
	clean
	init
	generate_ServerName_file_list
	generate_TLSInfo
	check_tls_version
	for i in tls1 tls1_1 tls1_2 tls1_3;do
		filter_tls $i $TLS_TRUE
		filter_tls $i $TLS_FALSE
	done
}

case $1 in
	start)
		main
	;;

	filter)
		if [ -z $2 ];then
			echo -e "[WARN] args ARG1 is null!\n[WARN] Usage: $0 filter ARG1"
			exit 1
		fi
		dislpay_ServerName $2
	;;

	check)
		check_ServerName_Available
	;;

	*)
		echo "[WARN] To execute the 'check'、'filter' command, the 'start' command must be executed first"
		echo "Usage: $0 [ start | filter ARG1 | check ]"
		echo -e "ARG1 = [ SERVER_NAME | all ]	example: $0 filter www.test.com"
	;;
esac
