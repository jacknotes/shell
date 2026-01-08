#!/bin/bash

BASH_SHELL='/shell/notice/main.sh'
func_list=`grep event_[a-zA-Z] $BASH_SHELL | tr -d "(){"`

for i in $func_list;do
	echo "[DEBUG] $i"
	eval "$BASH_SHELL $i"
done
