#!/bin/bash

EMAIL_ADDRESSES=('222222222@qq.com 111111111@qq.com')
SELF_ADDRESSES=('222222222@qq.com')
FEISHU_WEBHOOK_ADDRESS='https://open.feishu.cn/open-apis/bot/v2/hook/18e7516f'
FEISHU_AT='<at user_id=\"ou_886128a399ef0a8c\">JackLi</at> '
PYTHON_SHELL='/shell/notice/lunar_to_solar.py'
NL_YEAR=`$PYTHON_SHELL $(date +"%Y %m %d") | awk -F ' ' '{print $2}'`


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
	nl_happy_birthday="$NL_YEAR 1 18"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
	nl_happy_birthday="$NL_YEAR 1 5"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
	nl_happy_birthday="$NL_YEAR 1 18"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
	nl_happy_birthday="$NL_YEAR 1 25"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
	nl_happy_birthday="$NL_YEAR 2 21"
	yl_happy_birthday=`$PYTHON_SHELL $nl_happy_birthday | awk -F'：' '{print $2}'`
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
