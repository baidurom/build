#!/bin/bash 
#############################################################################################################
# Option: target, ota;                                                                                      #
# target: This shell will pull files from phone, build apkcerts.txt and filesystem_config.txt from device,  #
# create linkinfo.txt from device and recover the device files' symlink information in target_file, then    #
# generate a target zip file.                                                                               #
# ota:    This shell will build a ota package from the target file.                                         #
#############################################################################################################

PRJ_ROOT=`pwd`
ADB="adb"
TOOL_DIR=$PORT_BUILD/tools
TARGET_FILES_TEMPLATE_DIR=$PORT_BUILD/target_files_template
OTA_FROM_TARGET_FILES=$TOOL_DIR/releasetools/ota_from_target_files
SYSTEM_INFO_PROCESS=$TOOL_DIR/releasetools/systeminfoprocess.py
RECOVERY_LINK=$TOOL_DIR/releasetools/recoverylink.py
GET_INFO_FROM_SCRIPT=$TOOL_DIR/getInfoFromScript.py

OUT_DIR=$PRJ_ROOT/out
OUT_OTA_DIR=$OUT_DIR/ota
OUT_OTA_SYSTEM=$OUT_OTA_DIR/system
OUT_OTA_METAINF=$OUT_OTA_DIR/META-INF

OEM_TARGET_DIR=$OUT_DIR/oem_target_files
SYSTEM_DIR=$OEM_TARGET_DIR/SYSTEM
META_DIR=$OEM_TARGET_DIR/META
RECOVERY_ETC_DIR=$OEM_TARGET_DIR/RECOVERY/RAMDISK/etc

OTA_PACKAGE=$PRJ_ROOT/ota.zip
OEM_TARGET_ZIP=$OUT_DIR/oem_target_files.zip
VENDOR_TARGET_ZIP=$OUT_DIR/vendor_target_files.zip
OUTPUT_OTA_PACKAGE=$OUT_DIR/vendor_ota.zip

FROM_OTA=0
ROOT_STATE="system_root"

######## Error Exit Num ##########
ERR_USB_NOT_CONNECTED=151
ERR_DEVICE_NOT_ROOTED=152

ERR_NOT_PREPARE_RECOVERY_FSTAB=201
ERR_NOT_OTA_PACKAGE=202
ERR_OTA_INCOMPATIBLE=203
ERR_NOT_VENDOR_TARGET=204
ERR_MISSION_FAILED=209

# check for files preparing
function checkForEnvPrepare {
	if [ ! -f $PRJ_ROOT/recovery.fstab ];then
		echo ">>> Can not find $PRJ_ROOT/recovery.fstab"
		exit $ERR_NOT_PREPARE_RECOVERY
	fi
	$ADB shell ls / > /dev/null 2>&1
	if [ $? != 0 -a -f $OTA_PACKAGE ];then
		echo ">>> Device is not online, but ota.zip is exist."
		echo ">>> Config Makefile from $OTA_PACKAGE."
		FROM_OTA=1
	fi
}

# wait for the device to be online or timeout
function waitForDeviceOnline {
	echo ">>> Wait for the device to be online..."

	local timeout=30
	while [ $timeout -gt 0 ]
	do
		if adb shell ls > /dev/null 2>&1; then
			echo ">>> device is online"
			break
		fi
		echo ">>> device is not online, wait .."
		sleep 3
		timeout=$[$timeout - 3]
	done
	if [ $timeout -eq 0 ];then
		echo ">>> Please ensure adb can find your device and then rerun this script."
		exit $ERR_USB_NOT_CONNECTED
	fi
}

# check system root state
function checkRootState {
	echo ">>> Check root state of phone ..."
	waitForDeviceOnline
	SECURE_PROP=$(adb shell cat /default.prop | grep -o "ro.secure=\w")
	DEBUG_PROP=$(adb shell cat /default.prop | grep -o "ro.debuggable=\w")
	if [ "$SECURE_PROP" = "ro.secure=0" -o "$DEBUG_PROP" = "ro.debuggable=1" ];then
		ROOT_STATE="kernel_root"
		echo ">>> Root State: Kernel Root"
		adb root
		waitForDeviceOnline
	else
		echo "exit" > exit_command
		waitForDeviceOnline
		adb push exit_command /data/local/tmp
		rm -f exit_command
		if echo "su < /data/local/tmp/exit_command; exit" | adb shell | grep "not found" > /dev/null 2>&1;then
			echo ">>> ERROR: Not a root phone, please root this device firstly"
			exit $ERR_DEVICE_NOT_ROOTED;
		fi
		ROOT_STATE="system_root"
		echo ">>> Root State: System Root"
	fi
}

# copy the whole target_files_template dir
function copyTargetFilesTemplate {
    echo ">>> Copy target file template into current working directory"
    rm -rf $OEM_TARGET_DIR
    rm -f $OEM_TARGET_ZIP
    mkdir -p $OEM_TARGET_DIR
    cp -r $TARGET_FILES_TEMPLATE_DIR/* $OEM_TARGET_DIR
}

# get system files info from phone
function buildSystemInfo {
	echo ">>> Get system files info from phone ..."
	waitForDeviceOnline
	adb push $TOOL_DIR/releasetools/getfilesysteminfo.sh /data/local/tmp

	waitForDeviceOnline
	if [ "$ROOT_STATE" = "system_root" ];then
		adb push $TOOL_DIR/releasetools/getsysteminfocommand /data/local/tmp
		echo "su < /data/local/tmp/getsysteminfocommand; exit" | adb shell
	else
		adb shell chmod 0777 /data/local/tmp/getfilesysteminfo.sh
		adb shell /data/local/tmp/getfilesysteminfo.sh
	fi
	adb pull /data/local/tmp/file.info $META_DIR/
	$SYSTEM_INFO_PROCESS $META_DIR/file.info $META_DIR/system.info $META_DIR/link.info

	cat $META_DIR/system.info | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/filesystem_config.txt
	cat $META_DIR/link.info   | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/linkinfo.txt

	if [ ! -f $META_DIR/filesystem_config.txt -o ! -f $META_DIR/linkinfo.txt ];then
		echo ">>> Failed to create filesystem_config.txt or linkinfo.txt"
		exit $ERR_MISSION_FAILED
	fi

	rm -f $META_DIR/file.info $META_DIR/system.info $META_DIR/link.info
}

# build apkcerts.txt from packages.xml
function buildApkcerts {
    echo ">>> Build apkcerts.txt"
	if [ x"$ROOT_STATE" = x"system_root" ];then
		echo "chmod 666 /data/system/packages.xml" > chmodcommand
		adb push chmodcommand /data/local/tmp/chmodcommand
		rm chmodcommand
		echo "su < /data/local/tmp/chmodcommand; exit" | adb shell
	else
		adb shell chmod 666 /data/system/packages.xml
	fi
    adb pull /data/system/packages.xml $OEM_TARGET_DIR
    python $TOOL_DIR/apkcerts.py $OEM_TARGET_DIR/packages.xml $META_DIR/apkcerts.txt
    for file in $(adb shell ls /system/framework/*.apk)
    do
        apk=$(basename $file | tr -d "\015")
        echo "name=\"$apk\" certificate=\"build/security/platform.x509.pem\" private_key=\"build/security/platform.pk8\"" >> $META_DIR/apkcerts.txt
    done
    cat $META_DIR/apkcerts.txt | sort > $META_DIR/temp.txt
    mv $META_DIR/temp.txt $META_DIR/apkcerts.txt
    rm -f $OEM_TARGET_DIR/packages.xml
	if [ ! -f $META_DIR/apkcerts.txt ];then
		echo ">>> Failed to create apkcerts.txt"
		exit $ERR_MISSION_FAILED
	fi
}

# recover the device files' symlink information
function recoverSystemSymlink {
    echo ">>> Run recoverylink.py to recover symlink"
    $RECOVERY_LINK $META_DIR/linkinfo.txt $OEM_TARGET_DIR
}

function turnModToNum {
    mod=$1
    ((num=2#$(echo $mod | sed 's/[^\-]/1/g; s/\-/0/g')))
    echo $num
}

function addReadMod {
    sFile=$1

    sFileMod=$(adb shell ls -l $sFile | awk '{print $1}')
    ownMod=${sFileMod:1:3}
    grpMod=${sFileMod:4:3}
    otherMod="r"${sFileMod:8:2}

    newMod=$(turnModToNum $ownMod)$(turnModToNum $grpMod)$(turnModToNum $otherMod)

    if [ "x$newMod" != "x" ];then
        if [ x"$ROOT_STATE" = x"system_root" ]; then
            adb shell "su -c \"mount -o remount,rw /system; chmod $newMod $sFile; exit;\""
        else
            echo "mount -o remount,rw /system; chmod $newMod $sFile;exit" | adb shell
        fi
    fi
}

function pullFailedFailes {
    failedLog=$1
    times=$2
    tmpLog=$(mktemp -t "tmp.pull.XXXXX")

    grep "^failed to copy" $failedLog | while read LINE
    do
        sFile=$(echo $LINE | awk -F \' '{print $2}')
        outFile=$(echo $LINE | awk -F \' '{print $4}')

        addReadMod $sFile
        adb pull $sFile $outFile 2>&1 | grep "^failed to copy" | tee $tmpLog
    done

    if [ $(test -s $tmpLog) ]; then
         times=$(expr $times - 1)
         if [ $times -gt 0 ]; then
             pullFailedFailes $tmpLog
         else
             cat $tmpLog > $OUT_DIR/system-pull-failed.log
         fi
    fi
    rm $tmpLog
}

function dealwithSystemPullLog {
	pullLog=$1
	pullFailedFailes $pullLog 20
	if [ -s $OUT_DIR/system-pull-failed.log ];then
		echo "-------------------------------------------------------" > $OUT_DIR/build-info-to-user.txt
		echo "Some files those pull failed you must deal with manually:" >> $OUT_DIR/build-info-to-user.txt
		cat $OUT_DIR/system-pull-failed.log | sed -e "s/.*out\/oem_target_files\/SYSTEM\/\(.*\)'.*/\1/" >> $OUT_DIR/build-info-to-user.txt
		echo "" >> $OUT_DIR/build-info-to-user.txt
		echo "---------" >> $OUT_DIR/build-info-to-user.txt
		echo "pull log:" >> $OUT_DIR/build-info-to-user.txt
		cat $OUT_DIR/system-pull-failed.log >> $OUT_DIR/build-info-to-user.txt
		echo "-------------------------------------------------------" >> $OUT_DIR/build-info-to-user.txt
	fi
}

# build the SYSTEM dir under target_files
function buildSystemDir {
    echo ">>> Extract the whole /system from device"
    adb pull /system $SYSTEM_DIR 2>&1 | tee $OUT_DIR/system-pull.log
    find $SYSTEM_DIR -name su | xargs rm -f
    find $SYSTEM_DIR -name .suv | xargs rm -f
    find $SYSTEM_DIR -name invoke-as | xargs rm -f
	dealwithSystemPullLog $OUT_DIR/system-pull.log
}


# prepare boot.img recovery.fstab for target
function prepareBootRecovery {
	if [ -f $PRJ_ROOT/boot.img ];then
		mkdir -p $OEM_TARGET_DIR/BOOTABLE_IMAGES
		cp -f $PRJ_ROOT/boot.img $OEM_TARGET_DIR/BOOTABLE_IMAGES/boot.img
		echo ">>> Copy boot.img to $OEM_TARGET_DIR/BOOTABLE_IMAGES/boot.img"
	fi
	if [ ! -d $RECOVERY_ETC_DIR ];then
		mkdir -p $RECOVERY_ETC_DIR
	fi
	cp -f $PRJ_ROOT/recovery.fstab $RECOVERY_ETC_DIR/recovery.fstab
	echo ">>> Copy recovery.fstab to $RECOVERY_ETC_DIR/recovery.fstab"
}

# compress the target_files dir into a zip file
function zipTargetFiles {
    echo ">>> Compress the target_files dir into zip file"
    cd $OEM_TARGET_DIR
    zip -q -r -y $OEM_TARGET_ZIP *
    cd -
	rm -rf $OEM_TARGET_DIR
	if [ ! -f $OEM_TARGET_ZIP ];then
		echo ">>> Failed to create $OEM_TARGET_ZIP"
		exit $ERR_MISSION_FAILED
	fi
}

# pull files and info from phone and build a target file
function targetFromPhone {
	echo ">>> Build target file from phone !"
	checkRootState
	copyTargetFilesTemplate

	buildSystemInfo
	buildApkcerts
	buildSystemDir
	recoverSystemSymlink

	prepareBootRecovery
	zipTargetFiles
}

# check for files preparing [from package]
function checkOtaPackage {
	if [ ! -f $OTA_PACKAGE ];then
		echo ">>> Can not find $OTA_PACKAGE"
		exit $ERR_NOT_OTA_PACKAGE
	fi
	[ -e $OUT_OTA_DIR ] && rm -rf $OUT_OTA_DIR
	[ ! -e $OUT_DIR ] && mkdir -p $OUT_DIR
	echo ">>> Prepare ota package to $OUT_OTA_DIR ..."
	unzip -q $OTA_PACKAGE -d $OUT_OTA_DIR
	if [ ! -e $OUT_OTA_SYSTEM -o ! -e $OUT_OTA_METAINF ];then
		echo ">>> Can not find $OUT_OTA_SYSTEM or $OUT_OTA_METAINF"
		echo "    Please check whether $PRJ_ROOT/ota.zip is a complete ota package"
		exit $ERR_OTA_INCOMPATIBLE
	fi
}

# get system files info from META in ota package
function buildSystemInfoFromPackage {
	echo ">>> Get system files info from package ..."
	mkdir -p $META_DIR
	$GET_INFO_FROM_SCRIPT $OUT_OTA_DIR $META_DIR/system.info $META_DIR/link.info

	if [ ! -f $META_DIR/system.info -o ! -f $META_DIR/link.info ];then
		echo ">>> Failed to create system.info or link.info"
		exit $ERR_MISSION_FAILED
	fi

	cat $META_DIR/system.info | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/filesystem_config.txt
	cat $META_DIR/link.info   | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/linkinfo.txt

	if [ ! -f $META_DIR/filesystem_config.txt -o ! -f $META_DIR/linkinfo.txt ];then
		echo ">>> Failed to create filesystem_config.txt or linkinfo.txt"
		exit $ERR_MISSION_FAILED
	fi

	rm -f $META_DIR/system.info $META_DIR/link.info
}

# build apkcerts just use platform key
function buildApkcertsFromPackage {
	echo ">>> Build apkcerts.txt"
	find $OUT_OTA_SYSTEM -name "*.apk" > $META_DIR/app.list
	[ -e $META_DIR/apkcerts.txt ] && rm -f $META_DIR/apkcerts.txt
	cat $META_DIR/app.list | while read line
	do
		apkname=$(basename $line)
		echo "name=\"$apkname\" certificate=\"build/security/platform.x509.pem\" private_key=\"build/security/platform.pk8\"" >> $META_DIR/apkcerts.txt
	done
	rm -f $META_DIR/app.list
}

# build system dir from ota package
function buildSystemDirFromPackage {
	echo ">>> Build system dir from package ..."
	mkdir -p $SYSTEM_DIR
	rm -rf $SYSTEM_DIR/*
	mv $OUT_OTA_SYSTEM/* $SYSTEM_DIR/
}

# get files and info from ota package and build a target file
function targetFromPackage {
	echo ">>> Build target file from ota package !"
	checkOtaPackage
	copyTargetFilesTemplate

	buildSystemInfoFromPackage
	buildApkcertsFromPackage
	buildSystemDirFromPackage
	recoverSystemSymlink

	prepareBootRecovery
	zipTargetFiles
}

# build a new full ota package
function buildOtaPackage {
	if [ ! -f $VENDOR_TARGET_ZIP ];then
		echo ">>> Can not find $VENDOR_TARGET_ZIP"
		exit $ERR_NOT_VENDOR_TARGET
	fi
    echo ">>> Build full ota package: $OUTPUT_OTA_PACKAGE from $VENDOR_TARGET_ZIP"
    $OTA_FROM_TARGET_FILES -n -k $PORT_ROOT/build/security/testkey $VENDOR_TARGET_ZIP $OUTPUT_OTA_PACKAGE
	if [ ! -f $OUTPUT_OTA_PACKAGE ];then
		echo ">>> Failed to build $OUTPUT_OTA_PACKAGE"
		exit $ERR_MISSION_FAILED
	fi
}

function usage {
	echo "Usage: $0 target/ota"
	echo "      targe   -- create target files from phone or package"
	echo "      ota     -- build ota from target"
	exit $ERR_MISSION_FAILED
}

if [ $# != 1 ];then
	usage
elif [ "$1" = "target" ];then
	checkForEnvPrepare
	if [ $FROM_OTA = 0 ];then
		targetFromPhone
	else
		targetFromPackage
	fi
elif [ "$1" = "ota" ];then
	buildOtaPackage
else
	usage
fi
