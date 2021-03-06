# main.mk

#$(info # ------------------------------------------------------------------)
####################  custom #########################
ifneq ($(wildcard $(PORT_BUILD)/custom/defines.mk),)
include $(PORT_BUILD)/custom/defines.mk
endif

include $(PORT_BUILD)/locals.mk
include $(PORT_BUILD)/defines.mk

include $(PORT_BUILD)/configs/baidu_default.mk
include $(PORT_BUILD)/configs/vendor_default.mk

# include the mk after baidu/xxx/rom/ for different base
$(foreach mk, \
	$(strip $(wildcard $(PORT_ROOT/baidu/$(BAIDU_BASE_DEVICE)/rom))), \
	$(eval include $(mk)))

######################  ota ##########################
.PHONY: target-files framework-res bootimage recoveryimage
.PHONY: otapackage ota fullota

ifeq ($(strip $(wildcard $(BAIDU_SYSTEM))),)
#$(info # no source directory, need $(PREPARE_SOURCE))
ota fullota otapackage: check-project $(PREPARE_SOURCE)
else
ota fullota otapackage: check-project
endif

ota fullota otapackage:
	$(hide) cd $(PRJ_ROOT) && $(MAKE) ota-files-zip
	@echo "=========================================================================="
	@echo "Recommend Commands:                                                       "
	@echo "   make otadiff => build an Incremental OTA Package, with preparing       "
	@echo "         target_files.zip of previous version in current directory.       "
	@echo "   make otadiff PRE=xx/xx/target_files_xx.zip => specify previous package."
	@echo "   make otadiff PRE=xx/xx/ota_xx.zip => specify previous ota package.     "
	@echo "=========================================================================="

.PHONY: ota.phone
ota.phone: ota_path := $(shell if [ -f $(PRJ_SAVED_OTA_NAME) ];then cat $(PRJ_SAVED_OTA_NAME); fi)
ota.phone:
	@echo ">>> Install ota package to device ..."
	$(hide) $(FLASH_OTA_TO_DEVICE) $(ota_path)

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

################# check-project ######################
.PHONY: check-project
check-project:
	$(hide) if [ ! -f $(PRJ_ROOT)/Makefile ] && [ ! -f $(PRJ_ROOT)/makefile ];then \
				echo ">>> ERROR: invalid project path, PRJ_ROOT: $(PRJ_ROOT)"; \
				echo ">>> $(PRJ_ROOT)/Makefile doesn't exist!!"; \
				exit 1; \
			fi
	$(hide) echo ">>> project: $(PRJ_NAME), path: $(PRJ_ROOT)"

####################### clean #########################
CLEAN_TARGETS += clean-out 

.PHONY: clean-out
clean-out:
	$(hide) if [ -d $(OUT_DIR) ];then \
				filelist=$$(ls $(OUT_DIR)/*.zip 2> /dev/null | egrep "$(OUT_DIR)/ota-.*\.zip|$(OUT_DIR)/target-files-.*\.zip" | tr "\n" " "); \
				if [ x"$$filelist" != x"" ];then \
					filename=`echo $$filelist | sed 's#$(OUT_DIR)/##g'`; \
					echo ">>> Backup files to $(HISTORY_DIR)/:"; \
					echo "    $$filename"; \
					mkdir -p $(HISTORY_DIR); \
					mv $$filelist $(HISTORY_DIR) > /dev/null; \
				fi; \
				echo ">>> remove $(OUT_DIR)"; \
				rm -rf $(OUT_DIR); \
			fi

CLEAN_TARGETS += clean-source

CLEAN_SOURCE_REMOVE_TARGETS := $(patsubst %,$(BAIDU_DIR)/%,$(filter-out $(notdir $(BAIDU_ZIP) $(BAIDU_LAST_ZIP) $(THEME_RES)) \
                                    timestamp,$(shell if [ -d $(BAIDU_DIR) ]; then ls $(BAIDU_DIR); fi)))
.PHONY: clean-source
clean-source:
	$(hide) echo ">>> remove $(CLEAN_SOURCE_REMOVE_TARGETS)"
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)

clean-baidu-zip:
	$(hide) echo ">>> remove $(BAIDU_DIR)";
	$(hide) rm -rf $(BAIDU_DIR);

.PHONY: clean-autopatch
clean-autopatch:
	$(hide) echo ">>> remove $(PRJ_ROOT)/autopatch";
	$(hide) rm -rf $(PRJ_ROOT)/autopatch;

################### boot recovery ######################
include $(PORT_BUILD)/boot_recovery.mk

TARGET_FILES_SYSTEM += bootimage recoveryimage

################### newproject #########################
include $(PORT_BUILD)/newproject.mk

################ prepare baidu source ##################
include $(PORT_BUILD)/prepare_baidu.mk

#################   prebuilt   #########################
# get all of the files from source/system
ALL_BAIDU_FILES := \
    $(strip $(patsubst $(BAIDU_SYSTEM_FOR_POS)/%,%,\
        $(strip $(call get_all_files_in_dir,$(BAIDU_SYSTEM_FOR_POS)))))

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

BAIDU_PRJ_CUSTOM_TARGET := $(PRJ_CUSTOM_TARGET)
$(call resetPosition,BAIDU_PRJ_CUSTOM_TARGET,$(BAIDU_SYSTEM_FOR_POS))
$(call resetPosition,PRJ_CUSTOM_TARGET,$(VENDOR_SYSTEM))
PRJ_CUSTOM_TARGET := $(strip $(PRJ_CUSTOM_TARGET) $(BAIDU_PRJ_CUSTOM_TARGET))

# add the vendor prebuilt apps
VENDOR_PREBUILT_APPS := $(patsubst %,app/%.apk,$(vendor_saved_apps))
$(call resetPosition,VENDOR_PREBUILT_APPS,$(VENDOR_SYSTEM))

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
        framework/framework-res-yi.apk \
        $(ALL_VENDOR_FILES)))))

$(BAIDU_FRAMEWORK_APKS): $(PREPARE_SOURCE)

$(IF_BAIDU_RES): $(BAIDU_FRAMEWORK_APKS) $(PREPARE_SOURCE)
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

BAIDU_FRW_APK_NAMES :=
VENDOR_FRW_APK_NAMES :=
MERGED_FRW_APK_NAMES :=

$(foreach frw_res, $(BAIDU_FRAMEWORK_APKS),   $(eval BAIDU_FRW_APK_NAMES  += $(call getBaseName, $(frw_res))))
$(foreach frw_res, $(VENDOR_FRAMEWORK_APKS),  $(eval VENDOR_FRW_APK_NAMES += $(call getBaseName, $(frw_res))))
$(foreach frw_res, $(FRAMEWORK_APKS_TARGETS), $(eval MERGED_FRW_APK_NAMES += $(call getBaseName, $(frw_res))))

$(foreach frw_res, $(MERGED_FRW_APK_NAMES), \
	$(eval $(if $(filter 3, $(words $(filter $(frw_res), $(BAIDU_FRW_APK_NAMES) $(VENDOR_FRW_APK_NAMES) $(MERGED_FRW_APK_NAMES)))),BOTH_OWN_RES += $(frw_res))))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(BAIDU_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_BAIDU)/$(frw_res)) \
	$(eval $(call decode_baidu,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(VENDOR_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_VENDOR)/$(frw_res)) \
	$(eval $(call decode_vendor,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(OUT_SYSTEM_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_MERGED)/$(frw_res)) \
	$(eval $(call decode_merged,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

ifeq ($(ALL_FRW_NAME_TO_ID),true)
NOT_BOTH_OWN_RES := $(filter-out $(BOTH_OWN_RES), $(MERGED_FRW_APK_NAMES))

$(foreach frw_res, $(NOT_BOTH_OWN_RES), \
	$(eval frw_res_apk := $(OUT_SYSTEM_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_MERGED)/$(frw_res)) \
	$(eval $(call decode_merged,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))
endif

.IGNORE: $(PREPARE_FRW_RES_TARGET)

$(PREPARE_FRW_RES_JOB): $(PREPARE_FRW_RES_TARGET)
	$(hide) for frw_res_target in $(PREPARE_FRW_RES_TARGET); do \
				if [ ! -e $$frw_res_target ];then \
					echo ">>> WARNING: Failed to create $$frw_res_target, because of decode failure"; \
					mkdir -p `dirname $$frw_res_target`; \
					touch $$frw_res_target; \
				fi \
			done
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@

################# build.prop ###########################
include $(PORT_BUILD)/build.prop.mk

################ framework-res #########################

# generate the merged_update.txt mereged_none.txt merged_add.txt
.PHONY: generate-merged-txts
MERGED_TXTS := $(MERGE_NONE_TXT) $(MERGE_ADD_TXT)
$(MERGED_TXTS): $(MERGE_UPDATE_TXT)
	@ echo "" > /dev/null

$(MERGE_UPDATE_TXT): TXT_OUT_DIR := $(OUT_OBJ_RES)
$(MERGE_UPDATE_TXT): TMP_OUT_DIR := $(OUT_OBJ_RES)/tmp_txts
$(MERGE_UPDATE_TXT): TMP_UPDATE := $(OUT_OBJ_RES)/tmp_update.txt
$(MERGE_UPDATE_TXT): TMP_NONE := $(OUT_OBJ_RES)/tmp_none.txt
$(MERGE_UPDATE_TXT): OTHER_FRW_RES := $(filter-out framework-res, $(BOTH_OWN_RES))
$(MERGE_UPDATE_TXT): $(PREPARE_FRW_RES_JOB)
	$(hide) echo ">>> generate merged txts"
	$(hide) echo ">>> generate the merged_update.txt mereged_none.txt merged_add.txt"
	$(hide) mkdir -p $(TMP_OUT_DIR)
	$(hide) $(DIFFMAP_TOOL) -map $(VENDOR_PUBLIC_XML) \
		$(MERGED_PUBLIC_XML) $(BAIDU_PUBLIC_XML) $(TMP_OUT_DIR) > /dev/null
	$(hide) for frw_res in $(OTHER_FRW_RES); do \
				if [ -f $(FRW_RES_DECODE_MERGED)/$$frw_res/res/values/public.xml ] && \
					[ -f $(FRW_RES_DECODE_BAIDU)/$$frw_res/res/values/public.xml ]; then \
						$(GENMAP_TOOL) -map $(FRW_RES_DECODE_MERGED)/$$frw_res/res/values/public.xml \
								$(FRW_RES_DECODE_BAIDU)/$$frw_res/res/values/public.xml \
								$(TMP_UPDATE) $(TMP_NONE); \
						if [ -f $(TMP_UPDATE) ]; then \
							cat $(TMP_UPDATE) >> $(TMP_OUT_DIR)/merge_update.txt; \
						fi; \
						rm -rf $(TMP_UPDATE) $(TMP_NONE); \
				fi; \
			done
	$(hide) mv $(TMP_OUT_DIR)/* $(TXT_OUT_DIR)
	$(hide) rm -rf $(TMP_OUT_DIR)
	$(hide) echo ">>> generate merged txts done"

generate-merged-txts: $(MERGE_UPDATE_TXT)
	@ echo "" > /dev/null

CLEAN_TARGETS += clean-merged-txts
.PHONY: clean-merged-txts
clean-merged-txts: CLEAN_MERGED_TXTS := $(MERGED_TXTS) $(MERGE_UPDATE_TXT)
clean-merged-txts:
	$(hide) echo ">>> remove $(CLEAN_MERGED_TXTS)"
	$(hide) rm -rf $(CLEAN_MERGED_TXTS);

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
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: minSdkVersion := $(shell $(call getMinSdkVersionFromApktoolYml,\
																$(VENDOR_FRAMEWORK_RES_OUT)/apktool.yml))
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: targetSdkVersion := $(shell $(call getTargetSdkVersionFromApktoolYml,\
																$(VENDOR_FRAMEWORK_RES_OUT)/apktool.yml))
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: OUT_OBJ_FRAMEWORK_RES := $(OUT_OBJ_FRAMEWORK)/framework-res
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: $(FRAMEWORK_RES_SOURCE) 
	$(hide) echo ">>> start auto merge framework-res"
	$(hide) rm -rf $(OUT_OBJ_FRAMEWORK_RES)
	$(hide) mkdir -p $(OUT_OBJ_FRAMEWORK_RES)
	$(hide) cp -rf $(BAIDU_FRAMEWORK_OVERLAY) $(OUT_OBJ_FRAMEWORK_RES)/baidu-res-overlay
	$(hide) $(call formatOverlay,$(OUT_OBJ_FRAMEWORK_RES)/baidu-res-overlay)
	$(hide) $(if $(PRJ_FRAMEWORK_OVERLAY_SOURCES), \
				cp -rf $(PRJ_FRAMEWORK_OVERLAY) $(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay; \
				$(call formatOverlay,$(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay);,)
	$(hide) cp $(VENDOR_FRAMEWORK_RES_OUT)/AndroidManifest.xml $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml;
	$(hide) sed -i 's/android:versionName[ ]*=[ ]*"[^\"]*"//g' $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml;
	$(AAPT) package -u -x -z \
		$(if $(filter true,$(FULL_RES)),,$(addprefix -c , $(PRIVATE_PRODUCT_AAPT_CONFIG)) \
										$(addprefix --preferred-configurations , $(PRIVATE_PRODUCT_AAPT_PREF_CONFIG))) \
		$(if $(minSdkVersion),$(addprefix --min-sdk-version , $(minSdkVersion)),) \
		$(if $(targetSdkVersion),$(addprefix --target-sdk-version , $(targetSdkVersion)),) \
		$(if $(VERSION_NUMBER),$(addprefix --version-name ,$(VERSION_NUMBER)),) \
		-M $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml \
		-A $(VENDOR_FRAMEWORK_RES_OUT)/assets \
		$(if $(PRJ_FRAMEWORK_OVERLAY_SOURCES),-S $(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay,)\
		-S $(OUT_OBJ_FRAMEWORK_RES)/baidu-res-overlay \
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
$(call resetPosition,BAIDU_MODIFY_APPS,$(BAIDU_SYSTEM_FOR_POS))
#$(info # BAIDU_MODIFY_APPS:$(BAIDU_MODIFY_APPS))
$(foreach apk,$(BAIDU_MODIFY_APPS),\
    $(eval $(call baidu_modify_apk_build,$(PRJ_ROOT)/$(call getBaseName,$(apk)),$(apk))))

BAIDU_UPDATE_RES_APPS := $(filter-out $(PRJ_CUSTOM_TARGET),$(BAIDU_UPDATE_RES_APPS))
#$(info # BAIDU_UPDATE_RES_APPS:$(BAIDU_UPDATE_RES_APPS))

$(foreach apk,$(BAIDU_UPDATE_RES_APPS),\
    $(eval AAPT_BUILD_TARGET:=$(BAIDU_SYSTEM)/$(apk)) \
    $(if $(strip $(filter %.jar,$(apk))),\
         $(eval SIGN_JARS += $(OUT_OBJ_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)),\
         $(eval SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk))\
         $(if $(filter true,$(MINI_SYSTEM)),\
               $(if $(filter framework/%,$(apk)),,\
                   $(eval $(call aapt_build_baidu_apk,$(BAIDU_SYSTEM)/$(apk),$(OUT_OBJ_SYSTEM)/$(apk).aapt))\
                   $(eval AAPT_BUILD_TARGET := $(OUT_OBJ_SYSTEM)/$(apk).aapt)),))\
    $(if $(strip $(filter $(MINI_SYSTEM_SAVE_APPS),$(apk))),$(eval AAPT_BUILD_TARGET:=$(BAIDU_SYSTEM)/$(apk)),)\
    $(eval $(call baidu_update_template,$(apk)))\
    $(eval AAPT_BUILD_TARGET :=))

################## vendor_modify_apps ##################
#$(info # vendor_modify_apps:$(vendor_modify_apps))

$(foreach apk,$(vendor_modify_apps),\
    $(eval apkPos := $(call posOfApp,app/$(apk).apk,$(VENDOR_SYSTEM))) \
    $(if $(wildcard $(PRJ_ROOT)/$(apk)/smali), \
           $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))), \
           $(if $(call is_framework_apk,$(PRJ_ROOT)/$(apk)/apktool.yml), \
               $(eval $(call framework_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))), \
               $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))) \
           ) \
    ) \
)

################### need signed apks ###################
# remove the files which doesn't exist!!
BAIDU_SIGNED_APPS := $(sort $(strip $(filter $(ALL_BAIDU_FILES),$(BAIDU_SIGNED_APPS))))
BAIDU_SIGNED_APPS := $(filter-out $(PRJ_CUSTOM_TARGET),$(BAIDU_SIGNED_APPS))
$(call resetPositionApp,baidu_remove_apps,$(BAIDU_SYSTEM_FOR_POS))
BAIDU_SIGNED_APPS := $(filter-out $(baidu_remove_apps),$(BAIDU_SIGNED_APPS))

PRIVATE_MINI_SYSTEM_SAVE_APPS := $(filter $(MINI_SYSTEM_SAVE_APPS),$(BAIDU_SIGNED_APPS))

BAIDU_SIGNED_FR_APPS  := $(filter framework/%,$(BAIDU_SIGNED_APPS)) $(PRIVATE_MINI_SYSTEM_SAVE_APPS)
BAIDU_SIGNED_APP_APPS := $(filter-out $(BAIDU_SIGNED_FR_APPS),$(BAIDU_SIGNED_APPS))

# add the baidu sign apk to SIGN_APPS
ifeq ($(strip $(MINI_SYSTEM)),true)
$(foreach apk,$(BAIDU_SIGNED_APP_APPS),\
    $(eval SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(apk).aapt:$(OUT_SYSTEM)/$(apk)) \
	$(eval $(call aapt_build_baidu_apk,$(BAIDU_SYSTEM)/$(apk),$(OUT_OBJ_SYSTEM)/$(apk).aapt)))
else
$(foreach apk,$(BAIDU_SIGNED_APP_APPS),\
    $(eval SIGN_APPS += $(BAIDU_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))
endif

$(foreach apk,$(BAIDU_SIGNED_FR_APPS),\
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
	$(hide) sed -i "/system\/xbin\/su/d" $(OUT_OBJ_META)/filesystem_config.txt;
	$(hide) echo "system/xbin/su 0 0 6755" >> $(OUT_OBJ_META)/filesystem_config.txt;
	$(hide) mkdir -p $(OUT_META);
	$(hide) cp $(OUT_OBJ_META)/filesystem_config.txt $(OUT_META)/filesystem_config.txt;
	$(hide) echo ">>> update filesystem done";

$(OUT_OBJ_META)/filesystem_config.txt: $(VENDOR_META)/filesystem_config.txt
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $(VENDOR_META)/filesystem_config.txt $(OUT_OBJ_META)/filesystem_config.txt;

$(OUT_OBJ_META)/misc_info.txt: $(VENDOR_META)/misc_info.txt
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $< $@

$(OUT_META)/misc_info.txt: $(OUT_OBJ_META)/misc_info.txt $(OUT_RECOVERY_FSTAB)
	$(hide) extensions_path=$$(cat $(OUT_OBJ_META)/misc_info.txt | grep "tool_extensions=.\+" | grep -v "tool_extensions="); \
			if [ -d "$(PRJ_ROOT)/$$extensions_path" -o -f "$(PRJ_ROOT)/$$extensions_path" ];then \
				echo ">>> absolute path of tool_extensions: $(PRJ_ROOT)/$$extensions_path"; \
				sed -i '/tool_extensions/d' $<; \
				echo "tool_extensions=$(PRJ_ROOT)/$$extensions_path" >> $<; \
			fi
	$(hide) len=$$(grep -v "^#" $(OUT_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{print NF}' | head -1); \
			isNew=$$(grep -v "^#" $(OUT_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{if ($$2 == "/system"){print "NEW"}}'); \
			if [ "x$$len" = "x5" ] && [ "x$$isNew" = "xNEW" ]; \
			then \
				sed -i '/^fstab_version[ \t]*=.*/d' $(OUT_OBJ_META)/misc_info.txt; \
				echo "fstab_version=2" >> $(OUT_OBJ_META)/misc_info.txt; \
			else \
				sed -i '/^fstab_version[ \t]*=.*/d' $(OUT_OBJ_META)/misc_info.txt; \
				echo "fstab_version=1" >> $(OUT_OBJ_META)/misc_info.txt; \
			fi;
	$(hide) if [ x"false" = x"$(strip $(RECOVERY_OTA_ASSERT))" ]; then \
				echo "recovery_ota_assert=false" >> $(OUT_OBJ_META)/misc_info.txt; \
			fi
	$(hide) if [ x"true" = x"$(strip $(MAKE_RECOVERY_PATCH))" ]; then \
				echo "make_recovery_patch=true" >> $(OUT_OBJ_META)/misc_info.txt; \
			fi
	$(hide) if [ x"true" != x"$(strip $(SIGN_OTA))" ]; then \
				echo "not_sign_ota=true" >> $(OUT_OBJ_META)/misc_info.txt; \
			fi
	$(hide) mkdir -p $(OUT_META);
	$(hide) cp $(OUT_OBJ_META)/misc_info.txt $@

.PHONY: META
TARGET_FILES_META := META
META: $(eval meta_sources := $(filter-out %/filesystem_config.txt %/apkcerts.txt %/linkinfo.txt %/misc_info.txt, \
        $(call get_all_files_in_dir,$(VENDOR_META))))
META: $(OUT_META)/filesystem_config.txt $(OUT_META)/apkcerts.txt $(OUT_META)/misc_info.txt
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
	$(hide) if [ -d $(PRJ_OTA_OVERLAY) ]; then cp -rf $(PRJ_OTA_OVERLAY)/* $(OUT_OTA); fi
	$(hide) if [ -f $(PRJ_UPDATE_BINARY_OVERLAY) ]; then cp $(PRJ_UPDATE_BINARY_OVERLAY) $(OUT_OTA)/bin/updater; fi
	$(hide) if [ -f $(PRJ_UPDATER_SCRIPT_OVERLAY) ]; then cp $(PRJ_UPDATER_SCRIPT_OVERLAY) $(OUT_OTA); fi

########### recover the link files in system ###########
.PHONY: recover_link
OTA_TARGETS += recover_link
recover_link: target-files-system $(OUT_SYSTEM)
	$(hide) echo ">>> begin recover the link files in system";
	$(hide) $(RECOVER_LINK) $(VENDOR_META)/linkinfo.txt $(OUT_TARGET_DIR);
	$(hide) echo ">>> recover_link done"

################# update the apk certs #################
.PHONY: updateapkcerts
updateapkcerts: $(OUT_META)/apkcerts.txt
	$(hide) echo ">>> update the apk certs done"

OTA_TARGETS += $(TARGET_FILES_META)
ifeq ($(USER),baidu)
$(BAIDU_META)/apkcerts.txt: $(PREPARE_SOURCE)
	@ echo "Do nothing" > /dev/null

$(OUT_OBJ_META)/apkcerts.txt: USE_VENDOR_CERT_APPS:= $(strip $(patsubst %,%.apk,$(vendor_modify_apps)) $(VENDOR_SIGN_APPS))
$(OUT_OBJ_META)/apkcerts.txt: $(BAIDU_META)/apkcerts.txt $(VENDOR_META)/apkcerts.txt
	$(hide) echo ">>> base $(BAIDU_META)/apkcerts.txt";
	$(hide) echo "    except: $(VENDOR_SIGN_APPS), CERTS_PATH:$(CERTS_PATH)";
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $(BAIDU_META)/apkcerts.txt $(OUT_OBJ_DIR)/apkcerts.txt;
	$(hide) egrep 'certificate="build/target/product/security|$(CERTS_PATH)|PRESIGNED' $(BAIDU_META)/apkcerts.txt \
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
	$(hide) if [ -f $(BAIDU_META)/apkcerts.txt ];then \
				cat $(BAIDU_META)/apkcerts.txt | grep "PRESIGNED" >> $@; \
			fi
	$(hide) for apk in $(BAIDU_PRESIGNED_APPS); do \
				apkbasename=`echo $$apk | awk 'BEGIN{FS="[\/\.]"}{print $$(NF-1)}'`; \
				sed -i "/\"$$apkbasename\"/d" $@; \
				echo "name=\"$$apk\" certificate=\"PRESIGNED\" private_key=\"\"" >> $@; \
			done;

$(OUT_META)/apkcerts.txt: $(OUT_OBJ_META)/apkcerts.txt
	$(hide) mkdir -p $(OUT_META)
	$(hide) cp $< $@;
	$(hide) echo ">>> Update Out ==> $@";
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

##################### prebuilt ##########################
ifeq ($(strip $(wildcard $(PRJ_PREBUILT_OVERLAY))),)
PREBUILT_PARAM :=
else
PREBUILT_PARAM := --prebuilt $(PRJ_PREBUILT_OVERLAY)
endif

################ custom updater-script ##################
ifeq ($(strip $(wildcard $(PRJ_CUSTOM_SCRIPT))),)
CUSTOM_SCRIPT_PARAM :=
else
CUSTOM_SCRIPT_PARAM := --custom_script $(PRJ_CUSTOM_SCRIPT)
endif

################### baidu_service #######################
ifeq ($(strip $(filter boot boot.img, $(vendor_modify_images))),)
TARGET_FILES_SYSTEM += $(OUT_SYSTEM_BIN)/baidu_service
endif

$(OUT_SYSTEM_BIN)/baidu_service: obj_baidu_service := $(OUT_OBJ_BIN)/baidu_service
$(OUT_SYSTEM_BIN)/baidu_service: 
	@ echo ">>> target $@"
	$(hide) rm -f $@
	$(hide) mkdir -p $(OUT_SYSTEM_BIN)
	$(hide) mkdir -p `dirname $(obj_baidu_service)`
	$(hide) if [ -f $(SOURCE_BOOT_RAMDISK_SERVICEEXT) ]; then \
				cp $(SOURCE_BOOT_RAMDISK_SERVICEEXT) $(OUT_SYSTEM_BIN); \
			fi;
	$(hide) echo "#!/system/bin/sh" > $(obj_baidu_service)
	$(hide) echo "# set su's permission" >> $(obj_baidu_service)
	$(hide) echo "toolbox mount -o remount,rw /system" >> $(obj_baidu_service)
	$(hide) echo "toolbox chown root:root /system/xbin/su" >> $(obj_baidu_service)
	$(hide) echo "toolbox chmod 6755 /system/xbin/su" >> $(obj_baidu_service)
	$(hide) echo "toolbox mount -o remount,ro /system" >> $(obj_baidu_service)
	$(hide) echo "# used to start baidu's daemon, invoid to modify boot.img! " >> $(obj_baidu_service)
	$(hide) $(foreach service,$(BAIDU_SERVICES),\
				echo "$(service) &" >> $(obj_baidu_service);)
	$(hide) cp $(obj_baidu_service) $@

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

ifeq ($(FORMAT_PARAM_NUM),)
  ifeq ($(USE_FIVE_PARAM_FORMAT),true)
    FORMAT_PARAM_NUM := 5
  endif
endif

ifneq ($(FORMAT_PARAM_NUM),)
FORMAT_PARAM := -f $(FORMAT_PARAM_NUM)
endif

ifneq ($(strip $(SIGN_OTA)),true)
SIGN_OTA_PARAM := --no_sign
endif

PRJ_FULL_OTA_ZIP := $(OUT_DIR)/ota-$(VERSION_NUMBER).zip

$(PRJ_FULL_OTA_ZIP): $(OUT_TARGET_ZIP) $(OUT_LOGO_BIN)
	$(hide) echo $(PRJ_FULL_OTA_ZIP) > $(PRJ_SAVED_OTA_NAME)
	$(hide) echo $(OUT_TARGET_ZIP) > $(PRJ_SAVED_TARGET_NAME)
	$(hide) $(OTA_FROM_TARGET_FILES) \
			$(if $(wildcard $(PRJ_UPDATER_SCRIPT_PART)),$(addprefix -e , $(PRJ_UPDATER_SCRIPT_PART)),) \
			$(FORMAT_PARAM) \
			$(SIGN_OTA_PARAM) \
			-n -k $(OTA_CERT) \
			$(LOGO_BIN_PARAM) \
			$(PREBUILT_PARAM) \
			$(CUSTOM_SCRIPT_PARAM) \
			$(OUT_TARGET_ZIP) \
			$(PRJ_FULL_OTA_ZIP) || exit 51

ota-files-zip: $(PRJ_FULL_OTA_ZIP) mkuserimg
ota-files-zip: DATE := $(shell date +%Y%m%d%H%M)
ota-files-zip:
	$(hide) if [ x"$(USER)" != x"baidu" ];then \
				mv $(OUT_TARGET_ZIP) $(OUT_DIR)/target-files-$(VERSION_NUMBER).zip; \
				echo ">>> OUT ==> $(OUT_DIR)/target-files-$(VERSION_NUMBER).zip"; \
				echo "$(OUT_DIR)/target-files-$(VERSION_NUMBER).zip" > $(PRJ_SAVED_TARGET_NAME); \
				mv $(PRJ_FULL_OTA_ZIP) $(OUT_DIR)/ota-$(VERSION_NUMBER)-$(ROMER)-$(DATE).zip; \
				echo ">>> OUT ==> $(OUT_DIR)/ota-$(VERSION_NUMBER)-$(ROMER)-$(DATE).zip"; \
				echo "$(OUT_DIR)/ota-$(VERSION_NUMBER)-$(ROMER)-$(DATE).zip" > $(PRJ_SAVED_OTA_NAME); \
			else \
				echo ">>> OUT ==> $(PRJ_FULL_OTA_ZIP)"; \
			fi;

.PHONY: mkuserimg

ifneq ($(strip $(NO_SYSTEM_IMG)),true)
mkuserimg: $(OUT_TARGET_ZIP)
	$(hide) echo ">>> OUT_TARGET_ZIP: $(OUT_TARGET_ZIP)"
	$(hide) echo ">>> PRJ_OUT_TARGET_ZIP: $(PRJ_OUT_TARGET_ZIP)"
	$(hide) $(IMG_FROM_TARGET_FILES) $(OUT_TARGET_ZIP) \
			$(OUT_DIR)/target-files.signed.zip || exit 52
	$(hide) unzip -o $(OUT_DIR)/target-files.signed.zip -d $(OUT_DIR);
	$(hide) rm -f $(OUT_DIR)/target-files.signed.zip;
else
mkuserimg:
	$(hide) echo ">>> nothing to do for mkuserimg"
endif

##################  server-ota #########################
ifneq ($(wildcard $(PORT_BUILD)/custom/server_ota.mk),)
include $(PORT_BUILD)/custom/server_ota.mk
endif

############### dex target-files #######################
include $(PORT_BUILD)/dex_opt.mk

ifneq ($(wildcard $(PORT_BUILD)/custom/sign_ota.mk),)
include $(PORT_BUILD)/custom/sign_ota.mk
endif

############## add prepare_source ######################
$(BAIDU_SYSTEM)/%: $(PREPARE_SOURCE)
	@echo ">>> prepare $@ done" > /dev/null

################### clean ##############################
.PHONY: clean
clean: $(CLEAN_TARGETS) 
	$(hide) echo ">>> clean done"

.PHONY: clean-all
clean-all: clean clean-baidu-zip clean-autopatch

################### autofix ##############################
include $(PORT_BUILD)/autofix.mk

################### otadiff ##############################
include $(PORT_BUILD)/otadiff.mk

#$(info # ------------------------------------------------------------------)
