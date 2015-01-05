# baidu_default.mk

# add prebuilt dirs which should be override by baidu
BAIDU_PREBUILT_DIRS += \
	media/audio \
	app \
	priv-app \
	etc/channel_files

# add prebuilt files which should be override by baidu
BAIDU_PREBUILT_DEFAULT := \
	media/bootanimation.zip \
	media/images/boot_logo \
	media/shutanimation.zip \
	xbin/busybox \
	xbin/su \
	xbin/tcpdump \
	lib/libjni_mosaic.so \
	lib/libSpeakerRec.so \
	lib/liblocSDK_2.4.so \
	lib/librabjni-for-camera.so \
	lib/liballjoyn.so \
	bin/WordSegService \
	bin/http2wormhole \
	framework/framework-res-yi.apk

$(call resetPosition,BAIDU_PREBUILT_DEFAULT,$(BAIDU_SYSTEM_FOR_POS))
BAIDU_PREBUILT += $(BAIDU_PREBUILT_DEFAULT)

# define the apk and jars which need update the res id
BAIDU_UPDATE_RES_APPS += \
	app/Contacts.apk \
	app/SystemUI.apk \
	app/Settings.apk \
	app/Phone.apk \
	priv-app/InCallUI.apk \
	priv-app/TeleService.apk \
	priv-app/Keyguard.apk \
	app/Mms.apk \
	app/P2P.apk \
	app/BaiduDualCardSetting.apk \
	app/SceneMode.apk \
	app/PackageInstaller.apk \
	framework/android.policy.jar \
	framework/framework-yi.jar

$(call resetPosition,BAIDU_UPDATE_RES_APPS,$(BAIDU_SYSTEM_FOR_POS))

BAIDU_PROPERTY_OVERRIDES := \
	ro.baidu.build.hardware=$(shell echo $(PRJ_NAME) | tr a-z A-Z)

BAIDU_PREBUILT_LOW_RAM_REMOVE := \
	app/BaiduClickSearch.apk \
	app/BaiduVirusKilling.apk \
	app/Yellowpages.apk \
	app/iReader.apk \
	app/GameCenter.apk \
	app/FindmeDM.apk \
	lib/libbdocr.so

$(call resetPosition,BAIDU_PREBUILT_LOW_RAM_REMOVE,$(BAIDU_PREBUILT_LOW_RAM_REMOVE))

BAIDU_PROPERTY_FOLLOW_BASE := \
	ro.baidu.build.hardware.version \
	ro.baidu.build.software \
	ro.baidu.build.version.release \
	ro.baidu.recovery.verify \
	ro.baidu.build.hardware.version \
	ro.baidu.build.software \
	ro.baidu.build.version.release \
	ro.config.notification_sound \
	ro.config.ringtone \
	ro.config.alarm_alert \
	ro.config.rootperm.enable \
	ro.call.record \
	persist.sys.timezone

BAIDU_SERVICES += \
	/system/bin/WordSegService \
	/system/bin/serviceext

BAIDU_PREBUILT_PACKAGE_android.policy := \
	android \
	baidu \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_services := \
	baidu \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_framework := \
	baidu \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_framework2 := \
	baidu \
	com/baidu \
	com/yi \
	yi

# if the app was set in MINI_SYSTEM_SAVE_APPS, it will not build with aapt
MINI_SYSTEM_SAVE_APPS += BaiduCamera

$(call resetPositionApp,MINI_SYSTEM_SAVE_APPS,$(BAIDU_SYSTEM_FOR_POS))

ifeq ($(filter Phone,$(vendor_modify_apps)),)
ifneq ($(strip $(call isExist,Phone.apk,$(VENDOR_SYSTEM))),)
ifneq ($(strip $(call isExist,Phone.apk,$(BAIDU_SYSTEM_FOR_POS))),)
NEED_COMPELETE_MODULE_PAIR += \
	app/Phone.apk:Phone
endif # ifneq ($(call posOfApp,Phone,$(BAIDU_SYSTEM_FOR_POS)),)
endif # ifneq ($(call posOfApp,Phone,$(VENDOR_SYSTEM)),)
endif # ifeq ($(filter Phone,$(vendor_modify_apps)),)

ifeq ($(filter android.policy,$(vendor_modify_jars)),)
NEED_COMPELETE_MODULE_PAIR += \
	framework/android.policy.jar:android.policy.jar.out
endif

VENDOR_COM_MODULE_PAIR := \
	framework/core.jar:core.jar.out

# BAIDU_PRESIGNED_APPS set here is to proguard, if can not find apkcerts.txt, this would worked!
BAIDU_PRESIGNED_APPS_DEFAULT := \
	app/BaiduBrowser.apk \
	app/BaiduInput.apk \
	app/BaiduMap.apk \
	app/BaiduNetworkLocation.apk \
	app/BaiduWangpan.apk \
	app/SearchBox.apk \
	app/VoiceAssistant.apk \
	app/BaiduAppSearch.apk \
	app/BaiduKeyguard.apk \
	app/iReader.apk \
	app/GameCenter.apk \
	app/BaiduOpService.apk \
	app/BaiYiSearch.apk \
	app/HelpBook.apk

$(call resetPosition,BAIDU_PRESIGNED_APPS_DEFAULT,$(BAIDU_SYSTEM_FOR_POS))

