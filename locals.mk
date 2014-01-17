#
# locals.mk
# owner: baidu
# 

# set PRJ_ROOT to PWD
PRJ_ROOT := $(PWD)

# if doesn't set PRJ_NAME, set by PRJ_ROOT
ifeq ($(strip $(PRJ_NAME)),)
    PRJ_NAME := $(shell basename $(PRJ_ROOT))
endif

PROJECT_NAME_UP := $(strip $(shell echo $(PRJ_NAME) | tr '[a-z]' '[A-Z]'))

# if doesn't set, set to $(PRJ_ROOT)/logo.bin
# which means where the logo.bin is, only for mtk
# if the file $(PRJ_LOGO_BIN) doesn't exist, ignore
ifeq ($(strip $(PRJ_LOGO_BIN)),)
    PRJ_LOGO_BIN := $(PRJ_ROOT)/logo.bin
endif

ifneq ($(strip $(USER)),baidu)
    USER := 
endif

ifeq ($(strip $(ANDROID_SDK_VERSION)),)
    ANDROID_SDK_VERSION := 15
endif

# the version of the target
# which would be set to build.prop by $(MAKE_BUILD_PROP)
# eg:
#	make xxx version = 
ifneq ($(strip $(version)),)
VERSION_NUMBER := $(version)
else
VERSION_NUMBER :=
endif #ifneq ($(strip $(version)),)

##################### density ############################
ALL_DENSITY := \
     mdpi \
     hdpi \
     xhdpi \
     xxhdpi

ifeq ($(strip $(DENSITY)),)
    DENSITY := hdpi
endif

$(warning DENSITY:$(DENSITY))

DENSITY := $(shell echo $(DENSITY) | tr A-Z a-z)

ifeq ($(filter $(DENSITY),$(ALL_DENSITY)),$(DENSITY))
    NOT_USED_DENSITY := $(filter-out $(DENSITY),$(ALL_DENSITY))
else
    $(error density must be one of: $(ALL_DENSITY), ignore case)
endif

empty :=
space := $(empty) $(empty)
comma := $(empty),$(empty)

PRIVATE_PRODUCT_AAPT_CONFIG := \
	$(subst $(space),$(comma),$(sort normal,nodpi,$(ALL_DENSITY)))

PRIVATE_PRODUCT_AAPT_PREF_CONFIG := $(DENSITY)

##################### baidu zip ###########################
BAIDU_DIR          := $(PRJ_ROOT)/baidu
BAIDU_ZIP          := $(BAIDU_DIR)/baidu.zip
BAIDU_BASE_ZIP     := $(BAIDU_DIR)/baidu.deodex.zip

# apktool tags
# which used to compile multiple projects simultaneously
APKTOOL_BAIDU_TAG  := baidu_$(PRJ_NAME)
APKTOOL_VENDOR_TAG := vendor_$(PRJ_NAME)
APKTOOL_MERGED_TAG := merged_$(PRJ_NAME)

######################## vendor ###########################
VENDOR_DIR := vendor

VENDOR_META           := $(VENDOR_DIR)/META
VENDOR_METAINF        := $(VENDOR_DIR)/METAINF
VENDOR_OTA            := $(VENDOR_DIR)/OTA
VENDOR_SYSTEM         := $(VENDOR_DIR)/system
VENDOR_FRAMEWORK      := $(VENDOR_SYSTEM)/framework
VENDOR_FRAMEWORK_RES  := $(VENDOR_SYSTEM)/framework/framework-res.apk

######################### out #############################
OUT_DIR := out

OUT_OBJ_DIR    := $(OUT_DIR)/obj
OUT_TARGET_DIR := $(OUT_DIR)/merged_target_files
OUT_LOGO_BIN   := $(OUT_DIR)/logo.bin

########################## obj ############################
OUT_OBJ_BOOT      := $(OUT_OBJ_DIR)/BOOT
OUT_OBJ_RECOVERY  := $(OUT_OBJ_DIR)/RECOVERY
OUT_OBJ_META      := $(OUT_OBJ_DIR)/META
OUT_OBJ_SYSTEM    := $(OUT_OBJ_DIR)/system
OUT_OBJ_FRAMEWORK := $(OUT_OBJ_SYSTEM)/framework
OUT_OBJ_APP       := $(OUT_OBJ_SYSTEM)/app
OUT_OBJ_RES       := $(OUT_OBJ_SYSTEM)/res
OUT_OBJ_BIN       := $(OUT_OBJ_SYSTEM)/bin

BAIDU_PUBLIC_XML  := $(OUT_OBJ_RES)/public_master.xml
VENDOR_PUBLIC_XML := $(OUT_OBJ_RES)/public_vendor.xml
MERGED_PUBLIC_XML := $(OUT_OBJ_RES)/public_merged.xml

MERGE_NONE_TXT   := $(OUT_OBJ_RES)/merge_none.txt
MERGE_ADD_TXT    := $(OUT_OBJ_RES)/merge_add.txt
MERGE_UPDATE_TXT := $(OUT_OBJ_RES)/merge_update.txt

################ merged_target_files ######################
OUT_BOOTABLE_IMAGES  := $(OUT_TARGET_DIR)/BOOTABLE_IMAGES
OUT_META             := $(OUT_TARGET_DIR)/META
OUT_OTA              := $(OUT_TARGET_DIR)/OTA
OUT_RECOVERY         := $(OUT_TARGET_DIR)/RECOVERY
OUT_SYSTEM           := $(OUT_TARGET_DIR)/SYSTEM
OUT_DATA             := $(OUT_TARGET_DIR)/DATA

OUT_SYSTEM_APP       := $(OUT_SYSTEM)/app
OUT_SYSTEM_FRAMEWORK := $(OUT_SYSTEM)/framework
OUT_SYSTEM_LIB       := $(OUT_SYSTEM)/lib
OUT_SYSTEM_BIN       := $(OUT_SYSTEM)/bin
OUT_BUILD_PROP       := $(OUT_SYSTEM)/build.prop

################# target-files zips #######################
PRJ_OUT_TARGET_ZIP := $(OUT_DIR)/target-files.zip

################ overlay for project ######################
PRJ_OVERLAY           := overlay
PRJ_FRAMEWORK_OVERLAY := $(PRJ_OVERLAY)/framework-res/res

################# baidu overlay ###########################
BAIDU_OVERLAY           := $(PORT_ROOT)/baidu/overlay
BAIDU_FRAMEWORK_OVERLAY := $(BAIDU_OVERLAY)/frameworks/base/core/res/res

################## baidu source ###########################
BAIDU_SYSTEM        := $(BAIDU_DIR)/system
BAIDU_META          := $(BAIDU_DIR)/META
BAIDU_OTA           := $(BAIDU_DIR)/OTA

BAIDU_FRAMEWORK     := $(BAIDU_SYSTEM)/framework
BAIDU_FRAMEWORK_RES := $(BAIDU_FRAMEWORK)/framework-res.apk

############## vendor framework-res smali dir #############
VENDOR_FRAMEWORK_RES_OUT := $(PRJ_ROOT)/framework-res

############## internal resource java position ############
FRWK_INTER_RES_POS := smali/com/android/internal

################# project prebuilt directory ##############
BAIDU_SYSTEM_PREBUILT_DIR := $(PORT_ROOT)/baidu/rom/system
PRJ_SYSTEM_PREBUILT_DIR   := $(PRJ_OVERLAY)/system
PRJ_DATA_PREBUILT_DIR     := $(PRJ_OVERLAY)/data

###################### odex ###############################
PRODUCT_DIR            := odexupdate
SYSDIR                 := system
BOOTDIR                := $(SYSDIR)/framework
VENDOR_INIT_RC         := $(VENDOR_DIR)/BOOT/RAMDISK/init.rc

# do not change the order in DEFAULT_BOOT_CLASS_ODEX_ORDER
DEFAULT_BOOT_CLASS_ODEX_ORDER  := core.jar:core-junit.jar:bouncycastle.jar:ext.jar:framework.jar:android.policy.jar:services.jar:apache-xml.jar:filterfw.jar:mediatek-framework.jar:secondary_framework.jar

OUT_ODEX_DIR       := $(OUT_DIR)/$(PRODUCT_DIR)
OUT_ODEX_SYSTEM    := $(OUT_ODEX_DIR)/system
OUT_ODEX_FRAMEWORK := $(OUT_ODEX_SYSTEM)/framework
OUT_ODEX_APP       := $(OUT_ODEX_SYSTEM)/app
OUT_ODEX_META      := $(OUT_ODEX_DIR)/META

# the dalvik vm build version
# which will be used for preodex
DEFAULT_DALVIK_VM_BUILD := 27
DEXOPT_LIBS             := $(PORT_ROOT)/tools/lib
################## target for server ######################
PRJ_FULL_OTA_ZIP            := $(OUT_DIR)/ota-full_$(PRJ_NAME).zip
PRJ_TARGET_FILE_ODEX        := $(OUT_DIR)/target_files.zip.odex.zip

PRJ_SIGNED_TARGET_FILE      := $(OUT_DIR)/$(PRJ_NAME)-target-file-signed.zip
PRJ_SIGNED_IMAGES           := $(OUT_DIR)/signed-images.zip

########################## init ###########################
FRAMEWORK_RES_SOURCE := 
PRJ_PUBLIC_XML             := 

BAIDU_PREBUILT_APPS := 
BAIDU_UPDATE_APPS   := 

TARGET_FILES_SYSTEM :=
TARGET_FILES_OTA    :=
TARGET_FILES_META   :=
OTA_TARGETS         :=

########################## MAKE ###########################
# if doesn't set MAKE, set it to make -j4
ifeq ($(strip $(MAKE)),)
MAKE := make -j4
endif

###################### build.prop #########################
VENDOR_BUILD_PROP       := $(VENDOR_SYSTEM)/build.prop

############### tools in $(PORT_BUILD)/tools ###############
PORT_BUILD_TOOLS   := $(PORT_BUILD)/tools
GET_PACKAGE        := $(PORT_BUILD_TOOLS)/getpackage.sh
GET_PUBLIC_XML     := $(PORT_BUILD_TOOLS)/getPublicXml.sh
INSTALL_FRAMEWORKS := $(PORT_BUILD_TOOLS)/ifdir.sh

MAKE_BUILD_PROP          := $(PORT_BUILD_TOOLS)/make_build_prop.sh
PART_SMALI_APPEND        := $(PORT_BUILD_TOOLS)/partSmaliAppend.sh
UPDATE_INTERNAL_RESOURCE := $(PORT_BUILD_TOOLS)/UpInterrJava.py
UPDATE_FILE_SYSTEM       := $(PORT_BUILD_TOOLS)/UpdateFilesystem.py

UPDATE_APKTOOL_YML_TOOLS := $(PORT_BUILD_TOOLS)/update_apktool_yml.sh
DIFFMAP_TOOL             := $(PORT_BUILD_TOOLS)/diffmap.sh

############### tools in $(PORT_ROOT)/tools ###############
PORT_TOOLS     := $(PORT_ROOT)/tools
APKTOOL        := $(PORT_TOOLS)/apktool
AAPT           := $(PORT_TOOLS)/aapt

DEODEX		:= $(PORT_TOOLS)/deodex.sh
SIGN_TOOL   := $(PORT_TOOLS)/sign.sh
SIGN_JAR    := $(PORT_TOOLS)/signapk.jar
TESTKEY_PEM := $(PORT_TOOLS)/security/testkey.x509.pem
TESTKEY_PK  := $(PORT_TOOLS)/security/testkey.pk8

# CERTS_PATH only for generate the apkcerts.txt
CERTS_PATH  := tools/security
OTA_CERT := $(PORT_ROOT)/$(CERTS_PATH)/testkey

MODIFY_ID_TOOL           := $(PORT_TOOLS)/modifyID.py
NAME_TO_ID_TOOL          := $(PORT_TOOLS)/nametoid.py
ID_TO_NAME_TOOL          := $(PORT_TOOLS)/idtoname.py
ZIPALIGN                 := $(PORT_TOOLS)/zipalign

RECOVER_LINK             := $(PORT_TOOLS)/releasetools/recoverylink.py
OTA_FROM_TARGET_FILES    := $(PORT_TOOLS)/releasetools/ota_from_target_files
IMG_FROM_TARGET_FILES    := $(PORT_TOOLS)/releasetools/img_from_target_files
SIGN_TARGET_FILES_APKS   := $(PORT_TOOLS)/releasetools/sign_target_files_apks

NON_MTK_WRITE_RAW_IMAGE	 :=$(PORT_TOOLS)/releasetools/non_mtk_writeRawImage.py

DEX_OPT                  := $(PORT_TOOLS)/dexopt
DEX_PRE_OPT              := $(PORT_TOOLS)/dex-preopt

################### tools for project ####################
PRJ_CUSTOM_TARGETFILES := $(PRJ_ROOT)/custom_targetfiles.sh
PRJ_CUSTOM_APP         := $(PRJ_ROOT)/custom_app.sh
PRJ_CUSTOM_JAR         := $(PRJ_ROOT)/custom_jar.sh
PRJ_CUSTOM_BUILDPROP   := $(PRJ_ROOT)/custom_buildprop.sh
