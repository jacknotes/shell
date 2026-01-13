#!/bin/bash

EMAIL_ADDRESSES=('test@test.com dfsf@test.com')
SELF_ADDRESSES=('test@test.com')
FEISHU_WEBHOOK_ADDRESS='https://open.feishu.cn/open-apis/bot/v2/hook/sfjlasdjfklasdf'
FEISHU_AT='<at user_id=\"ou_886128a35464645f09ef0a8c\">JackLi</at> '
# 此脚本实现农历和阳历互转
# 阳历转农历: python3 date_converter.py 2026 11 25
# 农历转阳历,最后一个参数:0表示不闰月,1表示闰月: python3 date_converter.py 2025 11 25 0
PYTHON_SHELL='/shell/notice/date_converter.py'
NL_YEAR=`$PYTHON_SHELL $(date +"%Y %m %d") | awk -F ' ' '{print $4}'`

test(){
	today="2026-01-13"
	if [ "$today" == "2026-01-13" ];then
		body="2026马年纪念币1月13日22:00开约，纪念钞22:30启动"
		for i in ${SELF_ADDRESSES[*]};do
			echo "$body" | mail -s '2026年马年纪念钞和纪念币预约' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_yl_20260113(){
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "2026-01-13" ];then
		body="2026马年纪念币1月13日22:00开约，纪念钞22:30启动"
		for i in ${SELF_ADDRESSES[*]};do
			echo "2026马年纪念币1月13日22:00开约，纪念钞22:30启动" | mail -s '2026年马年纪念钞和纪念币预约' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_1118(){
	nl_happy_birthday="$NL_YEAR 11 18"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是爸爸生日"
		for i in ${EMAIL_ADDRESSES[*]};do
			echo "$body" | mail -s '爸爸生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_1225(){
	nl_happy_birthday="$NL_YEAR 12 25"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是妈妈生日"
		for i in ${EMAIL_ADDRESSES[*]};do
			echo "$body" | mail -s '妈妈生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_0110(){
	nl_happy_birthday="$NL_YEAR 1 10"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是姐姐生日"
		for i in ${SELF_ADDRESSES[*]};do
			echo "$body" | mail -s '姐姐生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_1228(){
	nl_happy_birthday="$NL_YEAR 12 28"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是老婆生日"
		for i in ${SELF_ADDRESSES[*]};do
			echo "$body" | mail -s '老婆生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_1125(){
	nl_happy_birthday="$NL_YEAR 11 25"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是女儿小钰生日"
		for i in ${SELF_ADDRESSES[*]};do
			echo "$body" | mail -s '孩子生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

event_nl_0421(){
	nl_happy_birthday="$NL_YEAR 4 21"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday 0 | awk -F': ' '{print $2}'`
	today="`date +"%Y-%m-%d"`"
	if [ "$today" == "$yl_happy_birthday" ];then
		body="今天农历$nl_happy_birthday，是儿子轩轩和女儿馨馨生日"
		for i in ${SELF_ADDRESSES[*]};do
			echo "$body" | mail -s '孩子生日提醒' $i
		done

		curl -X POST -H "Content-Type: application/json" \
			-d '{"msg_type":"text","content":{"text":"'"$FEISHU_AT $body"'"}}' "${FEISHU_WEBHOOK_ADDRESS}"
	fi
}

case "$1" in
	event_*)
		"$1"
		;;

	*)
		echo "Usage: $0 FUNC"		
		echo "FUNC list: sh -c 'grep event_[a-zA-Z] $0 | tr -d \"(){\"'"
		;;
esac
