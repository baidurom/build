# main.mk

$(info # ------------------------------------------------------------------)
include $(PORT_BUILD)/locals.mk
include $(PORT_BUILD)/defines.mk

include $(PORT_BUILD)/configs/baidu_default.mk
include $(PORT_BUILD)/configs/vendor_default.mk

# include the mk after baidu/xxx/rom/ for different base
$(foreach mk, \
	$(strip $(wildcard $(PORT_ROOT/baidu/$(BAIDU_BASE_DEVICE)/rom))), \
	$(eval include $(mk)))

.PHONY: target-files framework-res bootimage recoveryimage

.PHONY: otapackage ota fullota

ifeq ($(strip $(wildcard $(BAIDU_SYSTEM))),)
$(info # no source directory, need prepare-source)
ota fullota otapackage: check-project prepare-source
	$(hide) cd $(PRJ_ROOT) && $(MAKE) ota-files-zip
else
ifneq ($(strip $(serverdir)),)
$(info # serverdir is not null, need prepare-source: $(serverdir))
ota fullota otapackage: check-project prepare-source
	$(hide) cd $(PRJ_ROOT) && $(MAKE) ota-files-zip
else
ota fullota otapackage: check-project
	$(hide) cd $(PRJ_ROOT) && $(MAKE) ota-files-zip
endif
endif

newota: check-project prepare-new-source
	$(hide) cd $(PRJ_ROOT) && $(MAKE) ota-files-zip

ifeq ($(strip $(WITH_DEXPREOPT)),true)
NEED_SIGNED_TARGET_ZIP := $(PRJ_TARGET_FILE_ODEX)
else
NEED_SIGNED_TARGET_ZIP := $(PRJ_OUT_TARGET_ZIP)
endif

ifeq ($(strip $(WITH_SIGN)),true)
OUT_TARGET_ZIP := $(PRJ_SIGNED_TARGET_FILE)
else
OUT_TARGET_ZIP := $(NEED_SIGNED_TARGET_ZIP)
endif

ifneq ($(wildcard $(PORT_BUILD)/version.mk),)
include $(PORT_BUILD)/version.mk
endif

################# check-project ######################
.PHONY: check-project
check-project:
	$(hide) echo ">>> begining check project"
	$(hide) if [ ! -f $(PRJ_ROOT)/Makefile ] && [ ! -f $(PRJ_ROOT)/makefile ];then \
				echo ">>> ERROR: invalid project path, PRJ_ROOT: $(PRJ_ROOT)"; \
				echo ">>> $(PRJ_ROOT)/makefile doesn't exist!!"; \
				exit 1; \
			fi
	$(hide) if [ "$(PLATFORM)" = "" ];then \
				echo ">>> ERROR: invalid platform, PLATFORM can not be null, "; \
				exit 1; \
			fi
	$(hide) echo ">>> project path: $(PRJ_ROOT)"
	$(hide) echo ">>> platform: $(PLATFORM)"
	$(hide) echo ">>> project: $(PRJ_NAME)"
	$(hide) echo ">>> check-project done, SUCCESS\n"

####################### clean #########################
CLEAN_TARGETS += clean-out 

.PHONY: clean-out
clean-out:
	$(hide) echo ">>> remove $(OUT_DIR)"
	$(hide) rm -rf $(OUT_DIR)

CLEAN_TARGETS += clean-source

CLEAN_SOURCE_REMOVE_TARGETS := $(patsubst %,$(BAIDU_DIR)/%,$(filter-out $(notdir $(BAIDU_ZIP) $(BAIDU_BASE_ZIP)) \
                                    timestamp,$(shell if [ -d $(BAIDU_DIR) ]; then ls $(BAIDU_DIR); fi)))
.PHONY: clean-source
clean-source:
	$(hide) echo ">>> remove $(CLEAN_SOURCE_REMOVE_TARGETS)"
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)

clean-baidu-zip:
	$(hide) echo ">>> remove $(BAIDU_DIR)";
	$(hide) rm -rf $(BAIDU_DIR);

################### boot recovery ######################
ifeq ($(PRJ_ROOT)/boot_recovery.mk,$(wildcard $(PRJ_ROOT)/boot_recovery.mk))
    $(info # use project boot_recovery.mk)
    include $(PRJ_ROOT)/boot_recovery.mk
else
    $(info # use build/boot_recovery.mk)
    include $(PORT_BUILD)/boot_recovery.mk
endif
TARGET_FILES_SYSTEM += bootimage recoveryimage

################### newproject #########################
include $(PORT_BUILD)/newproject.mk

################ get-new-package #######################
# include get_new_package.mk for get the package from server
ifneq ($(wildcard $(PORT_BUILD)/get_new_package.mk),)
include $(PORT_BUILD)/get_new_package.mk
endif

#################   prebuilt   #########################
# get all of the files from source/system
ALL_BAIDU_FILES := \
    $(strip $(patsubst $(BAIDU_SYSTEM)/%,%,\
        $(strip $(call get_all_files_in_dir,$(BAIDU_SYSTEM)))))

# get all of the files from vendor/vendor_files
ALL_VENDOR_FILES := \
    $(strip $(patsubst $(VENDOR_SYSTEM)/%,%,\
        $(strip $(call get_all_files_in_dir,$(VENDOR_SYSTEM)))))

# get the project modified app and jars, remove them from prebuilt list
PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,app/%.apk,\
        $(vendor_saved_apps) \
        $(vendor_modify_apps) \
        $(baidu_modify_apps))))

PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,framework/%.apk,\
        $(vendor_modify_apps) $(baidu_modify_apps))))

PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,framework/%.jar,\
        $(vendor_modify_jars) \
        $(baidu_modify_jars))))

PRJ_CUSTOM_TARGET += $(sort framework/framework-res.apk)

PRJ_CUSTOM_TARGET += $(sort build.prop)

# add the vendor prebuilt apps
VENDOR_PREBUILT_APPS := $(patsubst %,app/%.apk,$(vendor_saved_apps))

include $(PORT_BUILD)/prebuilt.mk

###### get all of the framework resources apks #########
BAIDU_FRAMEWORK_APKS := $(patsubst %,$(BAIDU_SYSTEM)/%, \
	$(strip $(sort $(filter framework/%.apk, \
		$(ALL_BAIDU_FILES)))))

VENDOR_FRAMEWORK_APKS := $(patsubst %,$(VENDOR_SYSTEM)/%, \
	$(strip $(sort $(filter framework/%.apk, \
		$(ALL_VENDOR_FILES)))))

FRAMEWORK_APKS_TARGETS := $(patsubst %,$(OUT_SYSTEM)/%,\
    $(strip $(sort $(filter framework/%.apk,\
        $(ALL_BAIDU_FILES) \
        $(ALL_VENDOR_FILES)))))

IF_BAIDU_RES	:= $(OUT_OBJ_FRAMEWORK)/ifbaidu
IF_VENDOR_RES	:= $(OUT_OBJ_FRAMEWORK)/ifvendor
IF_MERGED_RES	:= $(OUT_OBJ_FRAMEWORK)/ifmerged
IF_ALL_RES		:= $(IF_BAIDU_RES) $(IF_VENDOR_RES) $(IF_MERGED_RES)
$(IF_BAIDU_RES): $(BAIDU_FRAMEWORK_APKS)
	$(hide) $(call apktool_if_baidu,$(BAIDU_FRAMEWORK))
	$(hide) echo ">>> apktool if baidu framework res done"
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@

$(IF_VENDOR_RES): $(VENDOR_FRAMEWORK_APKS)
	$(hide) $(call apktool_if_vendor,$(VENDOR_FRAMEWORK))
	$(hide) echo ">>> apktool if vendor framework res done"
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@

$(IF_MERGED_RES): $(FRAMEWORK_APKS_TARGETS)
	$(hide) $(call apktool_if_merged,$(OUT_SYSTEM_FRAMEWORK))
	$(hide) echo ">>> apktool if merged framework res done"
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@

################# build.prop ###########################
include $(PORT_BUILD)/build.prop.mk

################ framework-res #########################

# get the public.xml from framework-res.apk
PRJ_PUBLIC_XML += $(BAIDU_PUBLIC_XML)
$(eval $(call get_publicXml_template,$(BAIDU_PUBLIC_XML),$(BAIDU_FRAMEWORK_RES)))

PRJ_PUBLIC_XML += $(VENDOR_PUBLIC_XML)
$(eval $(call get_publicXml_template,$(VENDOR_PUBLIC_XML),$(VENDOR_FRAMEWORK_RES),-t $(APKTOOL_VENDOR_TAG)))

PRJ_PUBLIC_XML += $(MERGED_PUBLIC_XML)
$(eval $(call get_publicXml_template,$(MERGED_PUBLIC_XML),$(OUT_OBJ_FRAMEWORK)/framework-res.apk))

# generate the merged_update.txt mereged_none.txt merged_add.txt
.PHONY: generate-merged-txts
MERGED_TXTS := $(MERGE_NONE_TXT) $(MERGE_ADD_TXT) $(MERGE_UPDATE_TXT)
$(MERGED_TXTS): $(PRJ_PUBLIC_XML)
	$(hide) echo ">>> generate merged txts"
	$(hide) echo ">>> generate the merged_update.txt mereged_none.txt merged_add.txt"
	$(hide) mkdir -p $(OUT_OBJ_RES)
	$(hide) $(DIFFMAP_TOOL) -map $(VENDOR_PUBLIC_XML) \
		$(MERGED_PUBLIC_XML) $(BAIDU_PUBLIC_XML) $(OUT_OBJ_RES) > /dev/null
	$(hide) echo ">>> generate merged txts done"

generate-merged-txts: $(MERGED_TXTS)

CLEAN_TARGETS += clean-merged-txts
.PHONY: clean-merged-txts
clean-merged-txts:
	$(hide) echo ">>> remove $(MERGED_TXTS)"
	$(hide) rm -rf $(MERGED_TXTS);

# get the sources files of overlay and vendor framework-res
# get project overlay
PRJ_FRAMEWORK_OVERLAY_SOURCES += $(sort $(strip $(call get_all_files_in_dir, $(PRJ_FRAMEWORK_OVERLAY))))
FRAMEWORK_RES_SOURCE += $(PRJ_FRAMEWORK_OVERLAY_SOURCES)

# get project for baidu
BAIDU_OVERLAY_SOURCE := $(sort $(strip $(call get_all_files_in_dir, $(BAIDU_FRAMEWORK_OVERLAY))))
FRAMEWORK_RES_SOURCE += $(BAIDU_OVERLAY_SOURCE)
FRAMEWORK_RES_SOURCE += $(sort $(strip $(call get_all_files_in_dir, $(VENDOR_FRAMEWORK_RES_OUT))))

# add framework-res to TARGET_FILES_SYSTEM
TARGET_FILES_SYSTEM += framework-res

# add framework-res.apk to SIGN_APPS
# means framework-res will be signed and zipalign
SIGN_APPS += \
    $(OUT_OBJ_FRAMEWORK)/framework-res.apk:$(OUT_SYSTEM_FRAMEWORK)/framework-res.apk

clean-framework-res: remove_targets += $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
# use aapt to generate the framework-res.apk
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: $(FRAMEWORK_RES_SOURCE) 
	$(hide) echo ">>> start auto merge framework-res"
	$(hide) mkdir -p $(OUT_OBJ_FRAMEWORK)
	$(AAPT) package -u -x -z \
		$(addprefix -c , $(PRIVATE_PRODUCT_AAPT_CONFIG)) \
		$(addprefix --preferred-configurations , $(PRIVATE_PRODUCT_AAPT_PREF_CONFIG)) \
		-M $(VENDOR_FRAMEWORK_RES_OUT)/AndroidManifest.xml \
		-A $(VENDOR_FRAMEWORK_RES_OUT)/assets \
		$(if $(PRJ_FRAMEWORK_OVERLAY_SOURCES),-S $(PRJ_FRAMEWORK_OVERLAY),)\
		-S $(BAIDU_FRAMEWORK_OVERLAY) \
		-S $(VENDOR_FRAMEWORK_RES_OUT)/res \
		-F $@ 1>/dev/null
	$(hide) echo ">>> aapt done"
		

$(OUT_OBJ_FRAMEWORK)/framework-res.apk: tmpResDir := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/framework-res.XXX)

ifneq ($(strip $(NOT_CUSTOM_FRAMEWORK-RES)),true)
$(OUT_OBJ_FRAMEWORK)/framework-res.apk: $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
	$(hide) mkdir -p $(tmpResDir)
	$(hide) $(APKTOOL) d -f $< $(tmpResDir)
	$(hide) $(call custom_app,framework-res,$(tmpResDir))
	$(hide) $(APKTOOL) b $(tmpResDir) $@
	$(hide) rm -rf $(tmpResDir)
	$(hide) echo ">>> build framework-res.apk done"
else
$(OUT_OBJ_FRAMEWORK)/framework-res.apk: $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
	$(hide) cp $< $@
endif

# define the rule to make framework-res
framework-res: $(OUT_SYSTEM_FRAMEWORK)/framework-res.apk generate-merged-txts
	$(hide) echo ">>> Install: $(OUT_SYSTEM_FRAMEWORK)/framework-res.apk"
############## framework-res end #######################

############## need update res id's apks ###############
# remove the files which doesn't exist!!
BAIDU_UPDATE_RES_APPS := $(sort $(strip $(filter $(ALL_BAIDU_FILES),$(BAIDU_UPDATE_RES_APPS))))

# build baidu_modify_apps
BAIDU_MODIFY_APPS := $(strip $(patsubst %,app/%.apk,$(baidu_modify_apps)))
$(info # BAIDU_MODIFY_APPS:$(BAIDU_MODIFY_APPS))
$(foreach apk,$(BAIDU_MODIFY_APPS),\
    $(eval $(call baidu_modify_apk_build,$(PRJ_ROOT)/$(call getBaseName,$(apk)),$(apk))))

BAIDU_UPDATE_RES_APPS := $(filter-out $(PRJ_CUSTOM_TARGET),$(BAIDU_UPDATE_RES_APPS))
$(info # BAIDU_UPDATE_RES_APPS:$(BAIDU_UPDATE_RES_APPS))

$(foreach apk,$(BAIDU_UPDATE_RES_APPS),\
    $(eval $(call baidu_update_template,$(apk))))

################## vendor_modify_apps ##################
$(info # vendor_modify_apps:$(vendor_modify_apps))

$(foreach apk,$(vendor_modify_apps),\
    $(if $(wildcard $(PRJ_ROOT)/$(apk)/smali), \
           $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),app/$(apk).apk)), \
           $(if $(call is_framework_apk,$(PRJ_ROOT)/$(apk)/apktool.yml), \
               $(eval $(call framework_apk_build,$(PRJ_ROOT)/$(apk),framework/$(apk).apk)), \
               $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),app/$(apk).apk)) \
           ) \
    ) \
)

################### need signed apks ###################
# remove the files which doesn't exist!!
BAIDU_SIGNED_APPS += $(filter %.apk,$(BAIDU_PREBUILT))

BAIDU_SIGNED_APPS := $(sort $(strip $(filter $(ALL_BAIDU_FILES),$(BAIDU_SIGNED_APPS))))
BAIDU_SIGNED_APPS := $(filter-out $(PRJ_CUSTOM_TARGET),$(BAIDU_SIGNED_APPS))
BAIDU_SIGNED_APPS := $(filter-out $(patsubst %,app/%.apk,$(baidu_remove_apps)),$(BAIDU_SIGNED_APPS))

# add the baidu sign apk to SIGN_APPS
$(foreach apk,$(BAIDU_SIGNED_APPS),\
    $(eval SIGN_APPS += $(BAIDU_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))

############# baidu_modify_jars ########################
$(foreach jar,$(baidu_modify_jars),\
    $(eval $(call baidu_modify_jar_build,$(PRJ_ROOT)/$(jar).jar.out,framework/$(jar).jar)))

############# vendor_modify_jars #######################
$(foreach jar,$(vendor_modify_jars),\
    $(eval $(call vendor_modify_jar_build,$(PRJ_ROOT)/$(jar).jar.out,framework/$(jar).jar)))

################ process jars ##########################

#$(info # SIGN_JARS:$(SIGN_JARS))
$(foreach jar_pair,$(SIGN_JARS),\
    $(eval src_jar := $(call word-colon,1,$(jar_pair)))\
    $(eval dst_jar := $(call word-colon,2,$(jar_pair)))\
    $(eval $(call sign_jar,$(src_jar),$(dst_jar))))

.PHONY: sign-jars
TARGET_FILES_SYSTEM += sign-jars
sign-jars: $(SIGN_JAR_TARGETS)
#$(info # SIGN_JAR_TARGETS:$(SIGN_JAR_TARGETS))

########## signed apk with testkey #####################
#$(info # SIGN_APPS:$(SIGN_APPS))

$(foreach app_pair,$(SIGN_APPS),\
    $(eval src_apk := $(call word-colon,1,$(app_pair)))\
    $(eval dst_apk := $(call word-colon,2,$(app_pair)))\
    $(eval $(call sign_apk_testkey,$(src_apk),$(dst_apk))))

.PHONY: sign-apps
TARGET_FILES_SYSTEM += sign-apps
sign-apps: $(SIGN_APP_TARGETS)

################### META ###############################
$(OUT_META)/filesystem_config.txt: $(OUT_OBJ_META)/filesystem_config.txt
$(OUT_META)/filesystem_config.txt: target-files-system
	$(hide) echo ">>> update the filesystem_config.txt";
	$(hide) $(UPDATE_FILE_SYSTEM) $(OUT_OBJ_META)/filesystem_config.txt $(OUT_SYSTEM);
	$(hide) mkdir -p $(OUT_META);
	$(hide) cp $(OUT_OBJ_META)/filesystem_config.txt $(OUT_META)/filesystem_config.txt;
	$(hide) echo ">>> update filesystem done";

$(OUT_OBJ_META)/filesystem_config.txt: $(VENDOR_META)/filesystem_config.txt
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $(VENDOR_META)/filesystem_config.txt $(OUT_OBJ_META)/filesystem_config.txt;

.PHONY: META
TARGET_FILES_META := META
META: $(eval meta_sources := $(filter-out %/filesystem_config.txt %/apkcerts.txt %/linkinfo.txt,\
        $(call get_all_files_in_dir,$(VENDOR_META))))
META: $(OUT_META)/filesystem_config.txt $(OUT_META)/apkcerts.txt
	$(hide) cp $(meta_sources) $(OUT_META);
	$(hide) echo ">>> META is ok."

####################### OTA ############################
.PHONY: OTA
OTA_TARGETS += OTA
OTA $(OUT_OTA): $(strip $(call get_all_files_in_dir,$(VENDOR_OTA))) $(strip $(call get_all_files_in_dir,$(BAIDU_OTA)))
	$(hide) rm -rf $(OUT_OTA);
	$(hide) mkdir -p $(OUT_OTA);
	$(hide) cp -rf $(VENDOR_OTA)/* $(OUT_OTA);
	$(hide) if [ -d $(BAIDU_OTA) ]; then cp -rf $(BAIDU_OTA)/* $(OUT_OTA); fi

########### recover the link files in system ###########
.PHONY: recover_link
OTA_TARGETS += recover_link
recover_link: target-files-system $(OUT_SYSTEM)
	$(hide) echo ">>> begin recover the link files in system";
	$(hide) cp $(VENDOR_META)/linkinfo.txt $(OUT_SYSTEM);
	$(hide) $(RECOVER_LINK) $(OUT_TARGET_DIR);
	$(hide) rm -rf $(OUT_SYSTEM)/linkinfo.txt;
	$(hide) echo ">>> recover the link files done"

################# update the apk certs #################
.PHONY: updateapkcerts
updateapkcerts: $(OUT_META)/apkcerts.txt
	$(hide) echo ">>> update the apk certs done"

OTA_TARGETS += $(TARGET_FILES_META)
ifeq ($(USER),baidu)
$(OUT_OBJ_META)/apkcerts.txt: USE_VENDOR_CERT_APPS:= $(strip $(patsubst %,%.apk,$(vendor_modify_apps)) $(VENDOR_SIGN_APPS))
$(OUT_OBJ_META)/apkcerts.txt: $(BAIDU_META)/apkcerts.txt $(VENDOR_META)/apkcerts.txt
	$(hide) echo ">>> base $(BAIDU_META)/apkcerts.txt";
	$(hide) echo "    except: $(VENDOR_SIGN_APPS), CERTS_PATH:$(CERTS_PATH)";
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $(BAIDU_META)/apkcerts.txt $(OUT_OBJ_DIR)/apkcerts.txt;
	$(hide) egrep 'certificate="build/target/product/security|PRESIGNED' $(BAIDU_META)/apkcerts.txt \
				| sed 's#build/target/product/security#$(CERTS_PATH)#g'  \
				> $(OUT_OBJ_DIR)/apkcerts.txt;
	$(hide) echo ">>> USE_VENDOR_CERT_APPS:$(USE_VENDOR_CERT_APPS)"
	$(hide) for apk in $(USE_VENDOR_CERT_APPS); do\
				apkbasename=`basename $$apk`; \
				vendor_cert=`grep "\\"$$apkbasename\\"" $(VENDOR_META)/apkcerts.txt`; \
				echo ">>> $$apkbasename vendor_cert:$$vendor_cert"; \
				if [ x"$$vendor_cert" != x"" ];then\
					sed -i "/\"$$apkbasename\"/d" $(OUT_OBJ_DIR)/apkcerts.txt;\
					echo $$vendor_cert >> $(OUT_OBJ_DIR)/apkcerts.txt; \
				fi; \
			done;
	$(hide) mkdir -p $(OUT_META)
	$(hide) mv $(OUT_OBJ_DIR)/apkcerts.txt $@;
	$(hide) echo ">>> Update Out ==> $@";

$(OUT_META)/apkcerts.txt: $(OUT_OBJ_META)/apkcerts.txt
	$(hide) cp $< $@
else
$(OUT_OBJ_META)/apkcerts.txt:
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cat /dev/null > $@
	$(hide) $(foreach app,$(BAIDU_PRESIGNED_APPS),\
			echo "name=\"`basename $(app)`\" certificate=\"PRESIGNED\" private_key=\"\"" >> $@;)

$(OUT_META)/apkcerts.txt: target-files-system $(OUT_OBJ_META)/apkcerts.txt
	$(hide) echo ">>> use testkey to sign all of the apks, except presigned apk, CERTS_PATH:$(CERTS_PATH)"
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) find $(OUT_SYSTEM) -name "*.apk" | awk -F '\/' '{print $$NF}' > $(OUT_OBJ_META)/apkcerts.txt;
	$(hide) sed -i 's#^#name="#g' $(OUT_OBJ_META)/apkcerts.txt;
	$(hide) sed -i 's#$$#" certificate="$(CERTS_PATH)/testkey.x509.pem" private_key="$(CERTS_PATH)/testkey.pk8"#g' \
			$(OUT_OBJ_META)/apkcerts.txt;
	$(hide) for apk in $(BAIDU_PRESIGNED_APPS); do \
				apkbasename=`echo $$apk | awk 'BEGIN{FS="[\/\.]"}{print $$(NF-1)}'`; \
				sed -i "/\"$$apkbasename\"/d" $(OUT_OBJ_META)/apkcerts.txt; \
				echo "name=\"$$apk\" certificate=\"PRESIGNED\" private_key=\"\"" >> $(OUT_OBJ_META)/apkcerts.txt; \
			done;
	$(hide) mkdir -p $(OUT_META)
	$(hide) mv $(OUT_OBJ_META)/apkcerts.txt $(OUT_META)/apkcerts.txt;
	$(hide) echo ">>> Update Out ==> $(OUT_META)/apkcerts.txt";
endif

##################### channel #########################
ifneq ($(strip $(USER)),baidu)

ifeq ($(strip $(CHANNEL)),)
CHANNEL := 105
endif

TARGET_FILES_SYSTEM += add_channel

.PHONY: add_channel
add_channel: 
	$(hide) echo $(CHANNEL) > $(OUT_SYSTEM)/etc/channel
endif

##################### logo.bin #########################
ifeq ($(strip $(wildcard $(PRJ_LOGO_BIN))),)
LOGO_BIN_PARAM :=
$(OUT_LOGO_BIN):
	$(hide) echo ">>> nothing to do for $(OUT_LOGO_BIN)"
else
LOGO_BIN_PARAM := -l $(OUT_LOGO_BIN)
$(OUT_LOGO_BIN): $(PRJ_LOGO_BIN)
	$(hide) mkdir -p `dirname $(OUT_LOGO_BIN)`
	$(hide) cp $(PRJ_LOGO_BIN) $(OUT_LOGO_BIN)
endif

################### target-files #######################
TARGET_FILES_SYSTEM += bootimage recoveryimage
OTA_TARGETS += target-files-system

.PHONY: target-files-system
target-files-system: $(TARGET_FILES_SYSTEM)
	$(hide) $(call custom_post);

target-files: $(OTA_TARGETS)
	$(hide) echo ">>> build target-files"

$(PRJ_OUT_TARGET_ZIP): target-files
	$(hide) cd $(OUT_TARGET_DIR) && zip -q -r -y target-files.zip *;
	$(hide) mv $(OUT_TARGET_DIR)/target-files.zip $@;

ifeq ($(USE_FIVE_PARAM_FORMAT),true)
FORMAT_PARAM := -f 5
else
FORMAT_PARAM :=
endif

$(OUT_DIR)/ota_$(PRJ_NAME).zip: device_specific_script := $(call get_device_specific_script)
$(OUT_DIR)/ota_$(PRJ_NAME).zip: $(OUT_TARGET_ZIP) $(OUT_LOGO_BIN)
	$(hide) $(OTA_FROM_TARGET_FILES) $(device_specific_script) \
			$(FORMAT_PARAM) \
			-n -k $(OTA_CERT) \
			$(LOGO_BIN_PARAM) \
			$(OUT_TARGET_ZIP) \
			$(OUT_DIR)/ota_$(PRJ_NAME).zip; \

ota-files-zip: $(OUT_DIR)/ota_$(PRJ_NAME).zip mkuserimg
	$(hide) echo ">>> out: $(OUT_DIR)/ota_$(PRJ_NAME).zip";

.PHONY: mkuserimg
mkuserimg: $(OUT_TARGET_ZIP)
	$(hide) echo "OUT_TARGET_ZIP: $(OUT_TARGET_ZIP)"
	$(hide) echo "PRJ_OUT_TARGET_ZIP: $(PRJ_OUT_TARGET_ZIP)"
	$(hide) $(IMG_FROM_TARGET_FILES) $(OUT_TARGET_ZIP) \
			$(OUT_DIR)/target-files.signed.zip;
	$(hide) unzip -o $(OUT_DIR)/target-files.signed.zip -d $(OUT_DIR);
	$(hide) rm -f $(OUT_DIR)/target-files.signed.zip;

##################  server-ota #########################
ifneq ($(wildcard $(PORT_BUILD)/server_ota.mk),)
include $(PORT_BUILD)/server_ota.mk
endif

############### dex target-files #######################
include $(PORT_BUILD)/dex_opt.mk

ifneq ($(wildcard $(PORT_BUILD)/sign_ota.mk),)
include $(PORT_BUILD)/sign_ota.mk
endif

################### clean ##############################
.PHONY: clean
clean: $(CLEAN_TARGETS) 
	$(hide) echo ">>> clean done"

.PHONY: clean-all
clean-all: clean clean-baidu-zip

$(info # ------------------------------------------------------------------)
