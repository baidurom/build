#!/bin/bash

# usage: use apktool to install the framework-res.apk
# eg: ifdir system/framework [baidu/origin/xxxx]

function install_frameworks()
{	
	for res_apk in `ls $1/*.apk`;
	do
		$PORT_ROOT/tools/apktool if $res_apk $2
	done
}

if [ $# != 0 ];then
	install_frameworks $1 $2
fi
