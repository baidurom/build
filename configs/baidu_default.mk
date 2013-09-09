# baidu_default.mk

BAIDU_PREBUILT += \
	app/BaiduBrowser.apk \
	app/BaiduInput.apk \
	app/BaiduMap.apk \
	app/BaiduNetworkLocation.apk \
	app/BaiduWangpan.apk \
	app/SearchBox.apk \
	app/VoiceAssistant.apk \
	app/BaiduAppSearch.apk \
	app/BaiduKeyguard.apk \
	app/BaiduOpService.apk

BAIDU_PREBUILT += \
	lib/libWordSegService.so \
	lib/libshare.so \
	lib/libtmfe30.so \
	lib/libwordseg.so \
	lib/libvoiceSpeechVad.so \
	lib/libSpeakerRec.so \
	lib/libffmpeg.so \
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
	lib/libSMSFilter.so

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
	etc/security/otacerts.zip \
	media/audio/alarms/alarm.mp3 \
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
	media/audio/ringtones \
	media/audio/notifications \
	etc/localTheme01 \
	etc/defaultTheme

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
	app/PackageInstaller.apk \
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
	app/BaiduReader.apk \
	app/BaiduCamera.apk \
	app/BaiduTheme.apk \
	framework/framework-res-yi.apk \
	app/BaiduNetworkService.apk \
	app/BaiduProxy.apk \
	app/FindmeDM.apk \
	app/OnlineWallpaper.apk \
	app/BaiduFlashlight.apk \
	app/BaiduVirusKilling.apk \
	app/BaiduFestival.apk

BAIDU_PREBUILT += \
	app/Yellowpages.apk \
	etc/onlinephonebook.db

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
	app/BaiduReader.apk \
	app/BaiduOpService.apk

# define the apk and jars which need update the res id
BAIDU_UPDATE_RES_APPS += \
	app/Contacts.apk \
	app/SystemUI.apk \
	app/Settings.apk \
	app/Phone.apk \
	app/Mms.apk \
	app/P2P.apk \
	app/BaiduGallery3D.apk \
	app/BaiduDualCardSetting.apk \
	app/Calendar.apk \
	app/SceneMode.apk \
	framework/android.policy.jar

BAIDU_PROPERTY_OVERRIDES := \
	ro.baidu.build.hardware=$(shell echo $(PRJ_NAME) | tr a-z A-Z) \
	ro.baidu.build.hardware.version=1.0 \
	ro.baidu.build.software=yi_3.0 \
	ro.baidu.build.version.release=2.1 \
	ro.product.manufacturer=Baidu \
	ro.config.notification_sound=Ding.mp3 \
	ro.config.ringtone=Echo.mp3 \
	ro.config.alarm_alert=alarm.mp3 \
	ro.config.rootperm.enable=1 \
	persist.sys.timezone=Asia/Shanghai \
	ro.rom.mt.font=0

BAIDU_PROPERTY_FOLLOW_BASE := \
	ro.baidu.build.hardware.version \
	ro.baidu.build.software \
	ro.baidu.build.version.release \
	ro.build.version.release

BAIDU_PREBUILT_PACKAGE_android.policy := \
	android \
	com/baidu \
	com/yi \
	yi

BAIDU_PREBUILT_PACKAGE_framework := \
	com/baidu \
	baidu

ifeq ($(filter ro.rom.mt.font=%,$(override_property)),ro.rom.mt.font=1)
BAIDU_PREBUILT += lib/libskia.so
endif

BAIDU_PREBUILT_DIRS := $(sort $(strip $(baidu_saved_dirs)) $(BAIDU_PREBUILT_DIRS))
BAIDU_PREBUILT := $(sort $(strip $(baidu_saved_files)) $(BAIDU_PREBUILT))
