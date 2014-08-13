# baidu_default.mk

BAIDU_PREBUILT += \
	app/BaiduBrowser.apk \
	app/BaiduDirectShare.apk \
	app/BaiduInput.apk \
	app/BaiduMap.apk \
	app/BaiduNetworkLocation.apk \
	app/BaiduWangpan.apk \
	app/SearchBox.apk \
	app/VoiceAssistant.apk \
	app/BaiduAppSearch.apk \
	app/BaiduKeyguard.apk \
	app/BaiduOpService.apk \
	app/BaiYiSearch.apk \
	app/HelpBook.apk \

BAIDU_PREBUILT += \
	lib/libWordSegService.so \
	lib/libshare.so \
	lib/libtmfe30.so \
	lib/libwordseg.so \
	lib/libvoiceSpeechVad.so \
	lib/libSpeakerRec.so \
	lib/libcyberplayer-core.so \
	lib/libcyberplayer.so \
	lib/liblocSDK_2.4.so \
	lib/liblocSDK3.so \
	lib/libENPackage.so \
	lib/libCNPackage.so \
	lib/libejTTS-yi.so \
	lib/libbdocr.so \
	lib/libmtprocessor-jni.so \
	lib/libJniWordSegService.so \
	lib/libjni_mosaic.so \
	lib/liballjoyn_java.so \
	lib/liballjoyn.so \
	lib/libajdaemon.so \
	lib/libencrypt.so \
	lib/libbaidukeyguardbds.so \
	lib/libyi_backup_module.so \
	lib/libpush-socket.so \
	lib/libacs.so \
	lib/libBaiduJni.so \
	lib/libBaiduJniAnti.so \
	lib/libSMSFilter.so \
	lib/libjni_eglfenceForGallery.so \
	lib/libjni_filtershow_filtersForGallery.so

# for BaiduSysFramework 
BAIDU_PREBUILT += \
	lib/libregister.so

BAIDU_PREBUILT += \
	bin/WordSegService \
	bin/backuprestore \
	framework/framework-yi.jar \
	xbin/alljoyn-daemon \
	xbin/tcpdump \
	tts/lang_pico/it-IT_cm0_sg.bin \
	tts/lang_pico/es-ES_zl0_sg.bin \
	tts/lang_pico/fr-FR_ta.bin \
	tts/lang_pico/de-DE_ta.bin \
	tts/lang_pico/fr-FR_nk0_sg.bin \
	tts/lang_pico/de-DE_gl0_sg.bin \
	tts/lang_pico/es-ES_ta.bin \
	tts/lang_pico/it-IT_ta.bin \
	etc/defaultTheme.btp \
	etc/localTheme01.btp \
	etc/localTheme02.btp \
	etc/water.btp \
	etc/female.btp \
	etc/security/otacerts.zip \
	bin/http2wormhole \
	bin/property_stop.sh \
	bin/property_start.sh \
	etc/http2wormhole.conf \
	lib/libwormjni.so \
	lib/libsapi_V5_1.so \
	lib/libshare_v2.so \
	etc/dp.db

# the directory which need copy to target
BAIDU_PREBUILT_DIRS += \
	media/audio \
	etc/localTheme01 \
	etc/channel_files \
	etc/defaultTheme \
	etc/water \
	etc/female

#for SearchBox 
BAIDU_PREBUILT += \
	lib/libcyberplayer.so \
	lib/libgetcpuspec.so \
	lib/libp2p-jni.so \
	lib/librabjni.so \
	lib/libstlport_shared.so \
	lib/libPushMD5.so

#for BaiduCamera
BAIDU_PREBUILT += \
	lib/librabjni-for-camera.so

#for Contacts calllocation
BAIDU_PREBUILT += \
	etc/calllocation.db \
	etc/dict.model.utf \
	etc/name.model.utf

#for moduleservice
BAIDU_PREBUILT += \
	etc/modules/moduleservice.conf \
	lib/libyi_serviceext_module.so \
	etc/raw_yellow_data.db \
	etc/permissions/framework-yi.xml \
	xbin/su

# for bootanimation
BAIDU_PREBUILT += \
	media/bootanimation.zip \
	media/shutanimation.zip \
	media/images/boot_logo \
	xbin/busybox

BAIDU_PREBUILT += \
	app/LiveWallpapersPicker.apk \
	app/Exchange.apk \
	app/UserDictionaryProvider.apk \
	app/MTKThermalManager.apk \
	app/MediaProvider.apk \
	app/P2PScenes.apk \
	app/AtciService.apk \
	app/EngineerModeSim.apk \
	app/BaiduVideoPlayer.apk \
	app/YGPS.apk \
	app/VpnDialogs.apk \
	app/BaiduSync.apk \
	app/BackupRestoreConfirmation.apk \
	app/CalendarProvider.apk \
	app/BaiduUpdate.apk \
	app/SettingsProvider.apk \
	app/Wallpaper.apk \
	app/OnekeyWidget.apk \
	app/Browser.apk \
	app/ResManager.apk \
	app/BaiduMusicPlayer.apk \
	app/HomePro.apk \
	app/DownloadProvider.apk \
	app/BaiduSysFramework.apk \
	app/DynamicPermissionProvider.apk \
	app/CellConnService.apk \
	app/Provision.apk \
	app/BaiduServiceFramework.apk \
	app/BaiduUserFeedback.apk \
	app/CertInstaller.apk \
	app/DrmProvider.apk \
	app/NewPhoneWizard.apk \
	app/ContactsProvider.apk \
	app/InternalEngineerMode.apk \
	app/CDS_INFO.apk \
	app/BaiduNotepad.apk \
	app/dm.apk \
	app/BaiduClickSearch.apk \
	app/BaiduImageSearch.apk \
	app/SharedStorageBackup.apk \
	app/Omacp.apk \
	app/MtkBt.apk \
	app/BaiduSemiView.apk \
	app/Calculator.apk \
	app/TrafficMonitor.apk \
	app/KeyChain.apk \
	app/Email.apk \
	app/BaiduClock.apk \
	app/BaiduAntiDisturbance.apk \
	app/TelephonyProvider.apk \
	app/NotificationProvider.apk \
	app/DefaultContainerService.apk \
	app/BaiduBackupRestore.apk \
	app/PhaseBeam.apk \
	app/EngineerMode.apk \
	app/ApplicationsProvider.apk \
	app/DownloadProviderUi.apk \
	app/BaiduWeather.apk \
	app/BaiduSoundRecorder.apk \
	app/BaiduTts.apk \
	app/iReader.apk \
	app/GameCenter.apk \
	app/BaiduCamera.apk \
	app/BaiduTheme.apk \
	framework/framework-res-yi.apk \
	app/BaiduNetworkService.apk \
	app/BaiduProxy.apk \
	app/FindmeDM.apk \
	app/OnlineWallpaper.apk \
	app/BaiduFlashlight.apk \
	app/BaiduVirusKilling.apk \
	app/BaiduFestival.apk \
	app/FusedLocation.apk \
	app/BaiduGallery3D.apk \
	app/Email2.apk \
	app/Exchange2.apk \
	app/BaiduAccount.apk \


BAIDU_PREBUILT += \
    app/Yellowpages.apk \
	etc/onlinephonebook.db

BAIDU_PREBUILT += \
	app/BaiduSecurityCenter.apk \
	lib/libBaiduSecurityJni.so \
	lib/libacs.so \
	app/BaiduVideoEditor.apk \
	app/BulletinSubPage.apk

BAIDU_PREBUILT += \
    lib/libyi_compress_module.so

BAIDU_PRESIGNED_APPS += \
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
	app/HelpBook.apk \

# define the apk and jars which need update the res id
BAIDU_UPDATE_RES_APPS += \
	app/Contacts.apk \
	app/SystemUI.apk \
	app/Settings.apk \
	app/Phone.apk \
	app/Mms.apk \
	app/P2P.apk \
	app/BaiduDualCardSetting.apk \
	app/Calendar.apk \
	app/SceneMode.apk \
	app/PackageInstaller.apk \
	framework/android.policy.jar

BAIDU_PROPERTY_OVERRIDES := \
	ro.baidu.build.hardware=$(shell echo $(PRJ_NAME) | tr a-z A-Z) \
	ro.baidu.build.hardware.version=1.0 \
	ro.baidu.build.software=yi_3.0 \
	ro.baidu.build.version.release=2.1 \
	ro.product.manufacturer=Baidu \
	ro.config.notification_sound=HarvestSeason_meassage.ogg \
	ro.config.ringtone=HarvestSeason.ogg \
	ro.config.alarm_alert=KusoAlarm.ogg \
	ro.config.rootperm.enable=1 \
	persist.sys.timezone=Asia/Shanghai \
	ro.rom.mt.font=0

BAIDU_PREBUILT_LOW_RAM_REMOVE := \
	app/BaiduClickSearch.apk \
	app/BaiduVirusKilling.apk \
	app/Yellowpages.apk \
	app/iReader.apk \
	app/GameCenter.apk \
	app/FindmeDM.apk \
	lib/libbdocr.so

BAIDU_PROPERTY_FOLLOW_BASE := \
	ro.baidu.build.hardware.version \
	ro.baidu.build.software \
	ro.baidu.build.version.release \
	ro.build.version.release \
	ro.baidu.recovery.verify

BAIDU_SERVICES += \
	/system/bin/WordSegService \
	/system/bin/serviceext

BAIDU_PREBUILT_PACKAGE_android.policy := \
	android \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_framework := \
	android \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_services := \
	android \
	com/baidu \
	com/yi \
	yi

NEED_COMPELETE_MODULE_PAIR := \
	app/Phone.apk:Phone \
	framework/android.policy.jar:android.policy.jar.out

VENDOR_COM_MODULE_PAIR := \
	framework/core.jar:core.jar.out

ifeq ($(filter ro.rom.mt.font=%,$(override_property)),ro.rom.mt.font=1)
BAIDU_PREBUILT += lib/libskia.so
endif

BAIDU_PREBUILT_DIRS := $(sort $(strip $(baidu_saved_dirs)) $(BAIDU_PREBUILT_DIRS))
BAIDU_PREBUILT := $(sort $(strip $(baidu_saved_files)) $(BAIDU_PREBUILT))

ifeq ($(strip $(LOW_RAM_DEVICE)),true)
$(info low ram device, remove $(BAIDU_PREBUILT_LOW_RAM_REMOVE))
BAIDU_PREBUILT := $(filter-out $(BAIDU_PREBUILT_LOW_RAM_REMOVE),$(BAIDU_PREBUILT))
endif
