#!/bin/bash

OTA_PATH=$1
TOOL_NAME="flash_ota_to_device.sh"
TMP_COMMAND=".tmp_command"
COMMAND_DIR=/cache/recovery
COMMAND_NAME=command
PACKAGE_DIR=/data/local/tmp
PACKAGE_NAME=ota.zip

function usage() {
	echo "USAGE: $TOOL_NAME ota-path"
	echo "       $TOOL_NAME out/ota.zip"
	exit 1
}

function pushPackage() {
	echo ">>> Push $OTA_PATH to $PACKAGE_DIR/$PACKAGE_NAME ..."
	adb shell mkdir -p $PACKAGE_DIR
	adb push $OTA_PATH $PACKAGE_DIR/$PACKAGE_NAME
	if [ $? != 0 ];then
		echo ">>> Push package Failed!"
		exit 1
	fi
	echo ">>> Push package Success!"
}

function createCommand() {
	echo "--update_package=$PACKAGE_DIR/$PACKAGE_NAME" > $TMP_COMMAND
	echo "--wipe_data" >> $TMP_COMMAND
	adb shell mkdir -p $COMMAND_DIR
	adb push $TMP_COMMAND $COMMAND_DIR/$COMMAND_NAME
	if [ "$?" = "0" ];then
		rm -f $TMP_COMMAND
		echo "$COMMAND_DIR/$COMMAND_NAME:"
		adb shell cat $COMMAND_DIR/$COMMAND_NAME
		echo ">>> Reboot to Recovery ..."
		adb reboot recovery
	else
		rm -f $TMP_COMMAND
		echo ">>> command file create failed!"
		exit 1
	fi
}

if [ "$#" != "1" -o ! -f $OTA_PATH ];then
	usage
fi

OTA_DIR=$(dirname $OTA_PATH)
OTA_NAME=$(basename $OTA_PATH)

pushPackage
createCommand
