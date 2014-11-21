# defines.mk

ifeq ($(strip $(SHOW_COMMANDS)),)
hide := @
else
hide :=
endif

include $(PORT_BUILD)/generate_define.mk

# apktool install framework resouce apks, normal used
define apktool_if_dir
$(INSTALL_FRAMEWORKS) $(1)
endef

# apktool install framework in source/system/framework
# which are baidu's framework resource apk
# such as framework-res.apk, framework-res-yi.apk
define apktool_if_baidu
rm -rf ~/apktool/framework/[1-9]-$(APKTOOL_BAIDU_TAG).apk;\
$(INSTALL_FRAMEWORKS) $(1) $(APKTOOL_BAIDU_TAG)
endef

# apktool install framework resouce apks in vendor/system/framework
# which are vendor's framework resource apk
define apktool_if_vendor
rm -rf ~/apktool/framework/[1-9]-$(APKTOOL_VENDOR_TAG).apk;\
$(INSTALL_FRAMEWORKS) $(1) $(APKTOOL_VENDOR_TAG)
endef

# apktool install framework resouce apks in out/merged_target_files/SYSTEM/framework
# thoese framework resouce apks which were merged from baidu to vendor
define apktool_if_merged
rm -rf ~/apktool/framework/[1-9]-$(APKTOOL_MERGED_TAG).apk;\
$(INSTALL_FRAMEWORKS) $(1) $(APKTOOL_MERGED_TAG)
endef

define decode
	$(hide) rm -rf $(2)
	$(hide) mkdir -p `dirname $(2)`
	$(hide) $(APKTOOL) d -f -t $(3) $(1) $(2)
endef

define decode_baidu
$(2)/apktool.yml: $(IF_BAIDU_RES) $(1)
#	@echo ">>> decode_baidu $(1) to $(2)"
$(call decode,$(1),$(2),$(APKTOOL_BAIDU_TAG))
endef

define decode_vendor
$(2)/apktool.yml: $(IF_VENDOR_RES) $(1)
#	@echo ">>> decode_vendor $(1) to $(2)"
$(call decode,$(1),$(2),$(APKTOOL_VENDOR_TAG))
endef

define decode_merged
$(2)/apktool.yml: $(IF_MERGED_RES) $(1)
#	@echo ">>> decode_merged $(1) to $(2)"
$(call decode,$(1),$(2),$(APKTOOL_MERGED_TAG))
endef


# used for aapt to merged resouce
define get_baidu_installed_framework_params
`ls ~/apktool/framework/[1-9]-$(APKTOOL_BAIDU_TAG).apk | sed 's/^/-I /g'`
endef

# used for aapt to merged resouce
define get_vendor_installed_framework_params
`ls ~/apktool/framework/[1-9]-$(APKTOOL_VENDOR_TAG).apk | sed 's/^/-I /g'`
endef

# used for aapt to merged resouce
define get_merged_installed_framework_params
`ls ~/apktool/framework/[1-9]-$(APKTOOL_MERGED_TAG).apk | sed 's/^/-I /g'`
endef

# used for aapt to get resource
define get_aapt_framework_params
`if [ "x$(OVERLAY_TAG)" != "x" ]; then \
ls ~/apktool/framework/[1-9]-$(OVERLAY_TAG).apk | sed 's/^/-I /g'; \
else \
ls ~/apktool/framework/[1-9]-$(APKTOOL_MERGED_TAG).apk | sed 's/^/-I /g'; \
fi`
endef

# get all files in the directory, only for makefile
define get_all_files_in_dir
$(strip $(filter-out $(1),$(shell if [ -d $(1) ]; then find $(1) -type f; fi)))
endef

# get all smali files in the directory, only for find xx.jar.out, process "$" symbol
define get_all_smali_files_in_dir
$(strip $(filter-out $(1),$(shell if [ -d $(1) ]; then find $(1) -type f | sed 's/\$$/\\$$$$/g' | tee /tmp/find; fi)))
endef

# update the apktool.yml, include tags and usesFramework
define update_apktool_yml
$(UPDATE_APKTOOL_YML_TOOLS) $(1) $(2)
endef

# only for makefile
# used to check is framework apk or not
define is_framework_apk
$(shell awk '/isFrameworkApk/{if ($$2 = /true/){ print $$2 }}' $(1))
endef

# modify resource id in smali
define modify_res_id
$(MODIFY_ID_TOOL) $(MERGE_UPDATE_TXT) $(1)
endef

# change the #type@name#t to resouce id
define name_to_id
for publicXMl in `find $(FRW_RES_DECODE_MERGED) -name "public.xml"`; \
do \
$(NAME_TO_ID_TOOL) $$$$publicXMl $(1) > /dev/null; \
done; \
if [ -f $(1)/res/values/public.xml ]; then \
$(NAME_TO_ID_TOOL) $(1)/res/values/public.xml $(1) > /dev/null; \
fi
endef

# used to merged resource for apk
# only used for baidu_modify_apps
define aapt_overlay_apk
if [ "x$(3)" != "x" ] && [ -d $(3)/res ]; then app_res="$$$$app_res -S $(3)/res"; fi; \
if [ "x$(2)" != "x" ] && [ -d $(2)/res ]; then app_res="$$$$app_res -S $(2)/res"; fi; \
if [ "x$(1)" != "x" ] && [ -d $(1)/res ]; then app_res="$$$$app_res -S $(1)/res"; fi; \
if [ -d $(1)/assets ]; then app_assests="$$$$app_assests -A $(1)/assets"; fi; \
minSdkVersion=`$(call getMinSdkVersionFromApktoolYmlFD,$(1)/apktool.yml)`; \
targetSdkVersion=`$(call getTargetSdkVersionFromApktoolYmlFD,$(1)/apktool.yml)`;\
sed -i 's/android:versionName[ ]*=[ ]*"[^\"]*"//g' $(1)/AndroidManifest.xml; \
$(AAPT) package -u -z $(call get_aapt_framework_params) \
	$(if $(filter true,$(FULL_RES)),,$(addprefix -c , $(PRIVATE_PRODUCT_AAPT_CONFIG)) \
									$(addprefix --preferred-configurations , $(PRIVATE_PRODUCT_AAPT_PREF_CONFIG))) \
	$(if $$$$minSdkVersion,$(addprefix --min-sdk-version , $$$$minSdkVersion),) \
	$(if $$$$targetSdkVersion,$(addprefix --target-sdk-version , $$$$targetSdkVersion),) \
	$(if $(VERSION_NUMBER),$(addprefix --version-name ,$(VERSION_NUMBER)),) \
	-M $(1)/AndroidManifest.xml \
	$$$$app_assests \
	$$$$app_res \
	-F $(1).tmp.apk \
	1>/dev/null || exit $$?; \
if [ "x$(OVERLAY_TAG)" != "x" ]; then \
	$(APKTOOL) d -t $(OVERLAY_TAG) -f $(1).tmp.apk $(1).tmp; \
else \
	$(APKTOOL) d -t $(APKTOOL_MERGED_TAG) -f $(1).tmp.apk $(1).tmp; \
fi; \
rm -r $(1)/res && cp -r $(1).tmp/res $(1); \
rm $(1)/AndroidManifest.xml && cp $(1).tmp/AndroidManifest.xml $(1); \
rm -rf $(1).tmp.apk $(1).tmp
endef

define aapt_build_baidu_apk
$(2): tempSmaliDir  := $(shell mktemp -u $(OUT_OBJ_APP)/$(call getBaseName,$(1)).aapt.XXX)
$(2): apkName := $(call change_bracket,$(notdir $(1)))
$(2): apkBaseName := $(call getBaseName, $(1))
$(2): $(OUT_OBJ_META)/apkcerts.txt
$(2): $(IF_BAIDU_RES)
$(2): $(1)
	$(hide) mkdir -p `dirname $(2)`
	$(hide) if [ "x`grep "\\"$$(apkName)\\"" $(OUT_OBJ_META)/apkcerts.txt | grep "\\"PRESIGNED\\""`" = "x" ]; then \
				rm -rf $$(tempSmaliDir); \
				$(APKTOOL) d -t $(APKTOOL_BAIDU_TAG) $(1) $$(tempSmaliDir); \
				$(call port_custom_app,$$(apkBaseName),$$(tempSmaliDir)); \
                $(eval OVERLAY_TAG := $(APKTOOL_BAIDU_TAG)) \
				$(call aapt_overlay_apk,$$(tempSmaliDir)); \
                $(eval OVERLAY_TAG := ) \
                $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_BAIDU_TAG)); \
				$(APKTOOL) b $$(tempSmaliDir) $$@; \
				rm -rf $$(tempSmaliDir); \
			else \
				cp $(1) $(2); \
			fi;
endef

# sign the apk with testkey
define sign_apk_testkey
$(eval $(2)_apkBaseName := $(call getBaseName, $(2)))
$(OUT_OBJ_RES)/$($(2)_apkBaseName).remove: REMOVE_DRWABLE := $(patsubst $($(2)_apkBaseName)/%,%,$(filter $($(2)_apkBaseName)/%, $(remove_drawables)))
$(OUT_OBJ_RES)/$($(2)_apkBaseName).remove: $(1)
	$(hide) rm -rf $$@
	$(hide) mkdir -p $$@
	$(hide) unzip -q $(1) -d $$@
	$(hide) for drw in $$(REMOVE_DRWABLE); do \
				if [ "x$$$$drw" != "x" ] && [ -f "$$@/$$$$drw" ]; then \
					cat /dev/null > $$@/$$$$drw; \
				fi; \
			done

# check the apk is PRESIGNED or not
# 	if PRESIGNED, just copy
# 	otherwise, sign it with testkey
$(OUT_OBJ_APP)/$($(2)_apkBaseName).signed.apk: $(OUT_OBJ_META)/apkcerts.txt
$(OUT_OBJ_APP)/$($(2)_apkBaseName).signed.apk: $(OUT_OBJ_RES)/$($(2)_apkBaseName).remove
	$(hide) mkdir -p $(OUT_OBJ_APP)
	$(hide) if [ "x`grep "\\"$$(apkName)\\"" $(OUT_OBJ_META)/apkcerts.txt | grep "\\"PRESIGNED\\""`" = "x" ]; then \
				cd $$< > /dev/null; \
				zip $$(apkName) * -r -q -0; \
				cd - > /dev/null; \
				zip -d $$</$$(apkName) "META-INF/*" 2>&1 > /dev/null; \
				java -jar $(SIGN_JAR) $(TESTKEY_PEM) $(TESTKEY_PK) $$</$$(apkName) $$@; \
				rm $$</$($(2)_apkBaseName).apk; \
				touch $$@; \
				echo ">>> Sign testkey, out => $$@"; \
			else \
				cp '$(1)' $$@; \
				echo ">>> Presigned, out => $$@"; \
			fi

clean-$($(2)_apkBaseName): remove_targets += $(OUT_OBJ_RES)/$($(2)_apkBaseName).remove

$($(2)_apkBaseName): $(2)
SIGN_APP_TARGETS += $(2)

# zipalign for apk
$(2): apkName := $(call change_bracket,$(notdir $(2)))
$(2): $(OUT_OBJ_APP)/$(strip $($(2)_apkBaseName)).signed.apk
	$(hide) mkdir -p `dirname '$(2)'`
	$(hide) rm -rf '$(2)'
	$(hide) $(ZIPALIGN) 4 '$$<' '$(2)'
	$(hide) echo ">>> Zipalign, out => '$(2)'"

# add clean for this target
$(call clean-app,$(1),$(2))

# add push to phone
$(call push_phone,$(1),$(2))

endef

# sign the jar
define sign_jar
$(call getBaseName,$(2)): $(2)
SIGN_JAR_TARGETS += $(2)

$(2): jarBaseName := $(notdir $(1))
$(2): tempJarDir  := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/$(call getBaseName,$(2)).process.XXX)

$(2): $(1) $(VENDOR_METAINF)
	$(hide) if [ ! -d `dirname $(2)` ]; then mkdir -p `dirname $(2)`; fi;	
	$(hide) rm -rf $$(tempJarDir);
	$(hide) mkdir -p $$(tempJarDir);
	$(hide) if [ -d $(VENDOR_METAINF) ]; then cp -rf $(VENDOR_METAINF) $$(tempJarDir)/Jar; fi;
	$(hide) cp $(1) $$(tempJarDir);
	$(hide) cd $$(tempJarDir) && jar xf $$(jarBaseName) > /dev/null;
	$(hide) mv $$(tempJarDir)/classes.dex $$(tempJarDir)/Jar; 
	$(hide) if [ $$(jarBaseName) != "framework.jar" ];then \
				rm -rf $$(tempJarDir)/Jar/preloaded-classes*; \
			fi; 
	$(hide) cd $$(tempJarDir) && jar cf $$(jarBaseName) -C Jar/ . > /dev/null; 
	$(hide) mv $$(tempJarDir)/$$(jarBaseName) $(2);
	$(hide) rm -rf $$(tempJarDir);
	$(hide) echo ">>> Signed, out ==> $(2)";

# add clean for this target
$(call clean-jar,$(1),$(2))

# add push to phone
$(call push_phone,$(1),$(2))
endef

# custom app: call custom_app.sh in $(PRJ_ROOT)
# include framework resource apk
# it would be called when build a apk
define custom_app
if [ -f $(PRJ_CUSTOM_APP) ]; then $(PRJ_CUSTOM_APP) $(1) $(2); fi
endef

define port_custom_app
if [ -f $(PORT_CUSTOM_APP) ]; then $(PORT_CUSTOM_APP) $(1) $(2); fi
endef

# update the framework.jar.out/smali/com/android/internal/R*.smali
define update_internal_resource
echo ">>> use $(1) to update internal resources in $(2)"; \
$(UPDATE_INTERNAL_RESOURCE) $(1) $(2)
endef

define hasInternalResource
-f "$(strip $(1))/$(FRWK_INTER_RES_POS)/R.smali"
endef

# copy package define in BAIDU_PREBUILT_PACKAGE_xxx
define copy_package
ifneq ($(strip $(baidu_prebuilt_package)),)
	$(hide) echo ">>> begin copy baidu packages: \"$(baidu_prebuilt_package)\"\n \
		\t\tfrom $(BAIDU_SYSTEM)/$(baidu_prebuilt_from) to $(3)"
	$(hide) $(foreach from,$(baidu_prebuilt_from), \
					if [ -f $(BAIDU_SYSTEM)/$(from) ]; then \
						rm -rf $(1); \
						$(APKTOOL) d -f -t $(APKTOOL_BAIDU_TAG) $(BAIDU_SYSTEM)/$(from) $(1); \
						$(call modify_res_id,$(1)/smali); \
						$(foreach package,$(baidu_prebuilt_package),\
						$(call safe_dir_copy,$(1)/smali/$(package),$(2)/smali/$(package))) fi;)
endif
endef

# custom jar: call custom_app.sh in $(PRJ_ROOT)
# it would be called when build a jar
define custom_jar
	$(hide) if [ $(call hasInternalResource,$(2)) ];then \
				$(call update_internal_resource,$(MERGE_ADD_TXT),$(2)/$(FRWK_INTER_RES_POS)); \
			fi;
	$(hide) if [ -f $(PRJ_CUSTOM_JAR) ];then \
				$(PRJ_CUSTOM_JAR) $(1) $(2); \
			fi
endef

define port_custom_jar
	$(hide) if [ -f $(PORT_CUSTOM_JAR) ];then \
				$(PORT_CUSTOM_JAR) $(1) $(2); \
			fi
endef

define prepare_custom_jar
	$(hide) if [ -f $(PORT_PREPARE_CUSTOM_JAR) ];then \
				$(PORT_PREPARE_CUSTOM_JAR) $(1) $(2); \
			fi
endef

# custom post: call custompost.sh in $(PRJ_ROOT)
# it would be called before zip target-files.zip
define custom_post
	if [ -d $(BAIDU_SYSTEM_PREBUILT_DIR) ]; then \
		cp -rf $(BAIDU_SYSTEM_PREBUILT_DIR)/* $(OUT_SYSTEM);\
	fi; \
	if [ -d $(PRJ_SYSTEM_PREBUILT_DIR) ]; then \
		cp -rf $(PRJ_SYSTEM_PREBUILT_DIR)/* $(OUT_SYSTEM);\
	fi; \
	if [ -d $(PRJ_DATA_PREBUILT_DIR) ]; then \
		mkdir -p $(OUT_DATA); \
		cp -rf $(PRJ_DATA_PREBUILT_DIR)/* $(OUT_DATA);\
	fi; \
	if [ -f $(PORT_CUSTOM_TARGET_FILES) ];then \
		$(PORT_CUSTOM_TARGET_FILES) $(OUT_TARGET_DIR); \
	fi; \
	if [ -f $(PRJ_CUSTOM_TARGETFILES) ];then \
		$(PRJ_CUSTOM_TARGETFILES) $(OUT_TARGET_DIR); \
	fi
endef

# used to append .smali.part
# only used for baidu_modify_apps, baidu_modify_jars
define part_smali_append
$(PART_SMALI_APPEND) $(1) $(2) $(3)
endef

# used to build baidu_modify_apps
define baidu_modify_apk_build
SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(2):$(OUT_SYSTEM)/$(2)
$(call getBaseName, $(2))_bm_apk_sources := $(sort $(call get_all_smali_files_in_dir, $(1)))

$(BAIDU_SYSTEM)/$(2): $(PREPARE_SOURCE)
$(OUT_OBJ_SYSTEM)/$(2): apkBaseName   := $(call getBaseName, $(2))
$(OUT_OBJ_SYSTEM)/$(2): needUpdateRes := $(shell echo $(BAIDU_UPDATE_RES_APPS) | grep "$(2)" -o)
$(OUT_OBJ_SYSTEM)/$(2): tempSmaliDir  := $(shell mktemp -u $(OUT_OBJ_APP)/$(call getBaseName, $(2)).XXX)

$(OUT_OBJ_SYSTEM)/$(2): $(BAIDU_SYSTEM)/$(2) $(MERGE_UPDATE_TXT) $(PREPARE_FRW_RES_JOB) $(IF_ALL_RES) $$($(call getBaseName, $(2))_bm_apk_sources)
	$(hide) echo ">>> build baidu modify apk from $(1) to $(OUT_OBJ_SYSTEM)/$(2), tempSmaliDir:$$(tempSmaliDir)"
	$(hide) rm -rf "$$(tempSmaliDir)"
	$(hide) mkdir -p $(OUT_OBJ_APP)
	$(hide) $(APKTOOL) d -t $(APKTOOL_BAIDU_TAG) $(BAIDU_SYSTEM)/$(2) $$(tempSmaliDir)
	$(hide) if [ x"$$(needUpdateRes)" != x"" ];then \
				$(call modify_res_id,$$(tempSmaliDir)); \
			else \
				echo ">>> $$(tempSmaliDir) not need to update res id"; \
			fi;
	$(hide) $(call port_custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call part_smali_append,$(1)/smali,$$(tempSmaliDir)/smali);
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_MERGED_TAG));
	$(hide) if [ ! -d `dirname $(OUT_OBJ_SYSTEM)/$(2)` ]; then \
				mkdir -p `dirname $(OUT_OBJ_SYSTEM)/$(2)`; \
			fi;
	$(hide) if [ -d $(1)/res ]; then \
				$(call aapt_overlay_apk,$$(tempSmaliDir),$(1)); \
			fi;
	$(hide) $(call custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call name_to_id,$$(tempSmaliDir))
	$(hide) $(APKTOOL) b $$(tempSmaliDir) $(OUT_OBJ_SYSTEM)/$(2);
	$(hide) rm -rf "$$(tempSmaliDir)";
	$(hide) echo ">>> Build out ==> $(OUT_OBJ_SYSTEM)/$(2)"
endef

# used to build vendor_modify_apps
define vendor_modify_apk_build
SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(2):$(OUT_SYSTEM)/$(2)
$(call getBaseName, $(2))_vm_apk_sources := $(sort $(call get_all_smali_files_in_dir, $(1)))

$(OUT_OBJ_SYSTEM)/$(2): apkBaseName  := $(call getBaseName, $(2))
$(OUT_OBJ_SYSTEM)/$(2): baiduSmaliDir := $(shell mktemp -u $(OUT_OBJ_APP)/$(call getBaseName, $(2)).baidu.XXX)
$(OUT_OBJ_SYSTEM)/$(2): tempSmaliDir := $(shell mktemp -u $(OUT_OBJ_APP)/$(call getBaseName, $(2)).XXX)

$(OUT_OBJ_SYSTEM)/$(2): $(PREPARE_FRW_RES_JOB) $(IF_ALL_RES) $$($(call getBaseName, $(2))_vm_apk_sources)
	$(hide) echo ">>> build apk $(1) to $(OUT_OBJ_SYSTEM)/$(2)"
	$(hide) rm -rf $$(tempSmaliDir)
	$(hide) mkdir -p $$(tempSmaliDir)
$(eval baidu_prebuilt_package:=$(strip $(BAIDU_PREBUILT_PACKAGE_$(apk))))
$(eval baidu_prebuilt_from:=$(call posOfApp,$(if $(strip $(BAIDU_PREBUILT_PACKAGE_$(apk)_from)),$(BAIDU_PREBUILT_PACKAGE_$(apk)_from),$(2)),$(BAIDU_SYSTEM_FOR_POS)))
$(call copy_package,$$(baiduSmaliDir),$$(tempSmaliDir))
$(eval baidu_prebuilt_package:=)
$(eval baidu_prebuilt_from:=)
	$(hide) $(call dir_copy,$(1),$$(tempSmaliDir))
	$(hide) $(call port_custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call part_smali_append,--onlypart,$(1)/smali,$$(tempSmaliDir)/smali);
	$(hide) $(call custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call name_to_id,$$(tempSmaliDir));
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_MERGED_TAG));
	$(hide) if [ ! -d `dirname $(OUT_OBJ_SYSTEM)/$(2)` ]; then \
				mkdir -p `dirname $(OUT_OBJ_SYSTEM)/$(2)`; \
			fi;
	$(hide) $(APKTOOL) b $$(tempSmaliDir) $(OUT_OBJ_SYSTEM)/$(2);
	$(hide) rm -rf $$(tempSmaliDir);
	$(hide) echo ">>> build apk $(1) done";
endef

# get the begin resouce id in public.xml
# framework-res --> 1
define get_resource_id
$(shell grep -o "0x[0-9a-f]*" $(1)/res/values/public.xml | head -1 | cut -b4;)
endef

# get the apk in ~/apktool/framework/ which the install framework resouce apks stored
define get_include_aapt_res
`ls ~/apktool/framework/[1-$(1)]-$(APKTOOL_VENDOR_TAG).apk | sed 's/^/-I /g'`
endef

# used to build the apks in framework, and doesn't have smali directory
define framework_apk_build
SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(2):$(OUT_SYSTEM)/$(2)
$(eval fk_sources := $(sort $(call get_all_smali_files_in_dir, $(1))))
$(eval fk_ol_sources := $(sort $(call get_all_smali_files_in_dir, $(PRJ_OVERLAY)/$(call getBaseName, $(2))/res)))

$(OUT_OBJ_SYSTEM)/$(2): apkBaseName  := $(call getBaseName, $(2))
$(OUT_OBJ_SYSTEM)/$(2): tempSmaliDir := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2)).XXX)

$(OUT_OBJ_SYSTEM)/$(2): $(IF_VENDOR_RES) $(fk_sources) $(fk_ol_sources)
	$(hide) echo ">>> build framework apk $(1) to $$@"
	$(hide) rm -rf $$(tempSmaliDir)
	$(hide) mkdir -p $(OUT_OBJ_FRAMEWORK)
	$(hide) $(call dir_copy,$(1),$$(tempSmaliDir))
	$(hide) $(call port_custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_VENDOR_TAG));
	$(hide) mkdir -p `dirname $$@`
        $(eval resId := $(call get_resource_id,$(1)))
        $(eval resId := $(shell expr $(resId) - 1))
	$(hide) $(AAPT) package -u -x -z -M $$(tempSmaliDir)/AndroidManifest.xml \
			$(if $(fk_ol_sources), -S $(PRJ_OVERLAY)/$(call getBaseName, $(2))/res,) \
			-S $$(tempSmaliDir)/res \
			$(call get_include_aapt_res,$(resId)) \
			-F $$@
        $(eval resId := )
	$(hide) rm -rf $$(tempSmaliDir);
	$(hide) echo ">>> build framework apk $(1) done";

$(eval fk_sources :=)
$(eval fk_ol_sources :=)
endef

# used to build baidu_modify_jars
define baidu_modify_jar_build
SIGN_JARS += $(OUT_OBJ_SYSTEM)/$(2):$(OUT_SYSTEM)/$(2)

$(BAIDU_SYSTEM)/$(2): $(PREPARE_SOURCE)

$(call getBaseName, $(2))_bm_jar_sources := $(sort $(call get_all_smali_files_in_dir, $(1)))
$(OUT_OBJ_SYSTEM)/$(2): jarBaseName  := $(call getBaseName, $(2))
$(OUT_OBJ_SYSTEM)/$(2): tempSmaliDir := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2)).XXX)

$(OUT_OBJ_SYSTEM)/$(2): $(BAIDU_SYSTEM)/$(2) $(MERGE_UPDATE_TXT) $(PREPARE_FRW_RES_JOB) $(IF_ALL_RES) $$($(call getBaseName, $(2))_bm_jar_sources)
	$(hide) echo ">>> build baidu modify jar: $(1) to $$@, tempSmaliDir:$$(tempSmaliDir)"
	$(hide) rm -rf "$$(tempSmaliDir)"
	$(hide) mkdir -p $(OUT_OBJ_FRAMEWORK)
	$(hide) $(APKTOOL) d -t $(APKTOOL_BAIDU_TAG) $(BAIDU_SYSTEM)/$(2) $$(tempSmaliDir)
	$(hide) $(call modify_res_id,$$(tempSmaliDir))
	$(hide) $(call prepare_custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call port_custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call part_smali_append,$(1)/smali,$$(tempSmaliDir)/smali);
	$(hide) $(call custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call name_to_id,$$(tempSmaliDir))
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_MERGED_TAG));
	$(hide) mkdir -p $(OUT_OBJ_SYSTEM)
	$(hide) $(APKTOOL) b $$(tempSmaliDir) $$@;
	$(hide) echo ">>> Build jar out ==> $$@";
	$(hide) rm -rf "$$(tempSmaliDir)";
endef

# used to build vendor_modify_jars
define vendor_modify_jar_build
SIGN_JARS += $(OUT_OBJ_SYSTEM)/$(2):$(OUT_SYSTEM)/$(2)
$(call getBaseName, $(2))_vm_jar_sources  := $(sort $(call get_all_smali_files_in_dir, $(1)))

$(OUT_OBJ_SYSTEM)/$(2): jarBaseName   := $(call getBaseName, $(2))
$(OUT_OBJ_SYSTEM)/$(2): baiduSmaliDir := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2)).baidu.XXX)
$(OUT_OBJ_SYSTEM)/$(2): tempSmaliDir  := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2)).XXX)

$(OUT_OBJ_SYSTEM)/$(2): $(PREPARE_FRW_RES_JOB) $(MERGED_TXTS) $(IF_ALL_RES) $$($(call getBaseName, $(2))_vm_jar_sources)
	$(hide) echo ">>> build vendor modify jar: $(1) to $$@";
	$(hide) rm -rf $$(tempSmaliDir);
	$(hide) mkdir -p $$(tempSmaliDir)
$(eval baidu_prebuilt_package:=$(strip $(BAIDU_PREBUILT_PACKAGE_$(jar))))
$(eval baidu_prebuilt_from:=$(if $(strip $(BAIDU_PREBUILT_PACKAGE_$(jar)_from)),$(BAIDU_PREBUILT_PACKAGE_$(jar)_from),$(2)))
$(call copy_package,$$(baiduSmaliDir),$$(tempSmaliDir))
$(eval baidu_prebuilt_package:=)
$(eval baidu_prebuilt_from:=)
	$(hide) $(call prepare_custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call dir_copy,$(1),$$(tempSmaliDir))
	$(hide) $(call port_custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call part_smali_append,--onlypart,$(1)/smali,$$(tempSmaliDir)/smali);
	$(hide) $(call custom_jar,$$(jarBaseName),$$(tempSmaliDir))
	$(hide) $(call name_to_id,$$(tempSmaliDir))
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_MERGED_TAG));
	$(hide) $(APKTOOL) b $$(tempSmaliDir) $$@;
	$(hide) rm -rf $$(tempSmaliDir);
	$(hide) rm -rf $$(baiduSmaliDir);
	$(hide) echo ">>> Build jar out ==> $$@";
endef

# copy vendor or source directory
define prebuilt_template
PREBUILT_TARGET += $(2)
$(2): $(1)
	$(hide) if [ ! -d `dirname $(2)` ]; then mkdir -p `dirname $(2)`; fi;
	$(hide) cp $(1) $(2);
endef


# update the resouce id in $(BAIDU_UPDATE_RES_APPS)
define baidu_update_template
$(OUT_OBJ_SYSTEM)/$(1): apkBaseName  := $(call getBaseName, $(1))
$(OUT_OBJ_SYSTEM)/$(1): tempSmaliDir := $(shell mktemp -u $(OUT_OBJ_APP)/$(call getBaseName, $(1)).XXX)
$(OUT_OBJ_SYSTEM)/$(1): $(AAPT_BUILD_TARGET) $(MERGE_UPDATE_TXT) $(IF_ALL_RES) $(PREPARE_FRW_RES_JOB)
	$(hide) echo ">>> update the resouce id: $(BAIDU_SYSTEM)/$(1)"
	$(hide) rm -rf "$$(tempSmaliDir)"
	$(hide) mkdir -p "$$(tempSmaliDir)"
	$(hide) $(APKTOOL) d -f -t $(APKTOOL_BAIDU_TAG) $(AAPT_BUILD_TARGET) $$(tempSmaliDir) 2>/dev/null;
	$(hide) $(call port_custom_app,$$(apkBaseName),$$(tempSmaliDir));
	$(hide) $(call custom_app,$$(apkBaseName),$$(tempSmaliDir))
	$(hide) $(call modify_res_id,$$(tempSmaliDir))
	$(hide) $(call name_to_id,$$(tempSmaliDir))
	$(hide) $(call update_apktool_yml,$$(tempSmaliDir)/apktool.yml,$(APKTOOL_MERGED_TAG))
	$(hide) mkdir -p `dirname $$@`
	$(hide) $(APKTOOL) b $$(tempSmaliDir) $$@
	$(hide) rm -rf $$(tempSmaliDir);
	$(hide) echo ">>> Update out ==> $$@"
endef

# get the public.xml from framework-res.apk
define get_publicXml_template
CLEAN_TARGETS += clean-$(1)
.PHONY: clean-$(1)
clean-$(1):
	$(hide) echo ">>> remove $(1)"
	$(hide) rm -rf $(1);

$(1): tempDir := $(shell mktemp -u $(OUT_OBJ_RES)/$(call getBaseName, $(1)).XXX)
$(1): $(2) $(IF_VENDOR_RES)
	$(hide) mkdir -p `dirname $(1)`
	$(hide) $(APKTOOL) d $(3) -f "$(2)" "$$(tempDir)";
	$(hide) cp "$$(tempDir)/res/values/public.xml" "$(1)";
	$(hide) rm "$$(tempDir)" -rf;
endef

# dexopt one file
define dexopt_one_file
export LD_LIBRARY_PATH; \
$(DEX_PRE_OPT) --dexopt=$(DEX_OPT) \
	--build-dir=$(OUT_DIR) \
	--product-dir=$(PRODUCT_DIR) \
	--boot-jars=$(BOOT_CLASS_ODEX_ORDER) \
	--boot-dir=$(BOOTDIR) \
	$(patsubst $(OUT_DIR)/%,%,$(1)) $(patsubst $(OUT_DIR)/%,%,$(2))
endef

# delete the classes.dex in apk or jar
define delete_classes_dex
$(AAPT) r $(1) "classes.dex"
endef

# dexopt a jar
define dex_opt_jar
if [ -f $(OUT_ODEX_FRAMEWORK)/$(1).jar ] \
	&& [ ! -f $(OUT_ODEX_FRAMEWORK)/$(1).odex ] \
	&& [ "x`unzip -l "$(OUT_ODEX_FRAMEWORK)/$(1).jar" | grep -o "classes.dex"`" = "xclasses.dex" ]; then \
	echo ">>> begin odex for $(1)"; \
	$(call dexopt_one_file,$(OUT_ODEX_FRAMEWORK)/$(1).jar,$(OUT_ODEX_FRAMEWORK)/$(1).odex) || exit $?; \
	$(call delete_classes_dex,$(OUT_ODEX_FRAMEWORK)/$(1).jar) || exit $?; \
fi;
endef

# dexopt a apk
define dex_opt_app
if [ "x`unzip -l "$(OUT_ODEX_APP)/$(1).apk" | grep -o "classes.dex"`" = "xclasses.dex" ]; then \
	echo ">>> begin odex for $(1)"; \
	$(call dexopt_one_file,$(OUT_ODEX_APP)/$(1).apk,$(OUT_ODEX_APP)/$(1).odex) || exit $?; \
	$(call delete_classes_dex,$(OUT_ODEX_APP)/$(1).apk) || exit $?; \
else \
	echo ">>> $(1) is presigned, do not odex!"; \
fi
endef

