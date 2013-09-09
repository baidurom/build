# !/bin/bash

BAIDU_OTA_ZIP="$1"
BAIDU_PUBLIC_XML="$2"
APKTOOL=$PORT_ROOT/tools/apktool

echo "$@"

if [ -f $BAIDU_OTA_ZIP ];then
	echo "start get public.xml from $BAIDU_OTA_ZIP to $BAIDU_PUBLIC_XML"
	if [ ! -d `dirname $BAIDU_PUBLIC_XML` ];then
		mkdir -p `dirname $BAIDU_PUBLIC_XML`
	fi
	rm -rf ./.tmp
	mkdir ./.tmp
	unzip -q  $BAIDU_OTA_ZIP -d ./.tmp
	cd ./.tmp
	$APKTOOL d ./system/framework/framework-res.apk framework-res
	if [ $? != "0" ];then
		echo "ERROR: can not decode ./system/framework/framework-res.apk"
		exit 1
	fi
	cp -rf ./framework-res/res/values/public.xml $BAIDU_PUBLIC_XML
	cd - > /dev/null
	rm -rf ./.tmp
	exit 0
fi
