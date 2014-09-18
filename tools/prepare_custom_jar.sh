#!/bin/bash

jarBaseName=$1
tempSmaliDir=$2

WORK_DIR=$PWD
BAIDU_DIR=$WORK_DIR/baidu
OUT_OBJ_DIR=$WORK_DIR/out/obj
MERGE_UPDATE_TXT=$OUT_OBJ_DIR/system/res/merge_update.txt

MODIFY_ID_TOOL=$PORT_ROOT/build/tools/modifyID.py

if [ "$jarBaseName" = "android.policy" ];then
	BAIDU_FRAMEWORK_YI=$BAIDU_DIR/system/framework/framework-yi.jar
	
	if [ -f $BAIDU_FRAMEWORK_YI ]; then
		tempYi=`mktemp -u $OUT_OBJ_DIR/framework-yi.XXXX`
		rm -rf $tempYi
		mkdir -p $tempYi
		
		apktool d -f $BAIDU_FRAMEWORK_YI $tempYi
		$MODIFY_ID_TOOL $MERGE_UPDATE_TXT $tempYi
		
		#echo ">>> copy framework-yi.jar's package(`cd $tempYi/smali/ >/dev/null; find -type d; cd - > /dev/null`) to android.policy.jar"
		cp -rf $tempYi/smali/* $tempSmaliDir
	fi
fi
