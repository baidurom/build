
empty :=
space := $(empty) $(empty)

left_bracket := (
right_bracket := )

# get the words split by :
define word-colon
$(word $(1),$(subst :,$(space),$(2)))
endef

define collapse-pairs
$(eval _cpSEP := $(strip $(if $(2),$(2),=)))\
$(subst $(space)$(_cpSEP)$(space),$(_cpSEP),$(strip \
    $(subst $(_cpSEP), $(_cpSEP) ,$(1))))
endef

define uniq-pairs-by-first-component
$(eval _upbfc_fc_set :=)\
$(strip $(foreach w,$(1), $(eval _first := $(word 1,$(subst $(2),$(space),$(w))))\
    $(if $(filter $(_upbfc_fc_set),$(_first)),,$(w)\
        $(eval _upbfc_fc_set += $(_first)))))\
$(eval _upbfc_fc_set :=)\
$(eval _first:=)
endef

# used to mkdir
define mkdir_p
$(1):
	$(hide) echo "mkdir -p $(1)"
	$(hide) mkdir -p $(1);
endef

# get the basename of apk or jar
define getBaseName
$(basename $(notdir $(1)))
endef

define change_bracket
$(subst $(right_bracket),\$(right_bracket),$(subst $(left_bracket),\$(left_bracket),$(1)))
endef

define safe_dir_copy
	if [ -d $(1) ]; then mkdir -p $(2) && cp -rf $(1)/* $(2); fi;
endef

define dir_copy
	mkdir -p $(2) && cp -r $(1)/* $(2);
endef

define safe_file_copy
	if [ -f $(1) ]; then mkdir -p `dirname $(2)` && cp -f $(1) $(2); fi;
endef

define file_copy
	mkdir -p `dirname $(2)` && cp $(1) $(2);
endef

# clean the app or jar
# you can add some target to remove by set "remove_targets"
# eg:
# 	clean-framework-res: remove_targets += xxxx
define clean-app
.PHONY: clean-$(call getBaseName, $(2))
clean-$(call getBaseName, $(2)): remove_targets += $(filter-out $(VENDOR_DIR)/%,$(filter-out $(BAIDU_DIR)/%,$(1) $(2)))
clean-$(call getBaseName, $(2)): remove_targets += $(OUT_OBJ_APP)/$(call getBaseName, $(2))\.*
clean-$(call getBaseName, $(2)):
	rm -rf $$(remove_targets)
	$(hide) echo ">>> clean $$@ done!"
endef
define clean-jar
.PHONY: clean-$(call getBaseName, $(2))
clean-$(call getBaseName, $(2)): remove_targets += $(filter-out $(VENDOR_DIR)/%,$(filter-out $(BAIDU_DIR)/%,$(1) $(2)))
clean-$(call getBaseName, $(2)): remove_targets += $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2))\.*
clean-$(call getBaseName, $(2)):
	rm -rf $$(remove_targets)
	$(hide) echo ">>> clean $$@ done!"
endef

# define the target xxx.phone
# it will push the apk or jar to the phone
define push_phone
$(call getBaseName, $(2)).phone: baseDir := $(shell basename $(dir $(2)))
$(call getBaseName, $(2)).phone: baseName := $(notdir $(2))
$(call getBaseName, $(2)).phone: $(2)
	$(hide) echo ">>> push $(2) to Phone"
	adb root
	@ echo "wait for devices..."
	adb wait-for-device
	adb remount
	adb push $$< /system/$$(baseDir)
	adb shell chmod 644 /system/$$(baseDir)/$$(baseName)
endef

define get_base_version
echo $(1) | grep "_[DRS]_[0-9]*.[0-9]*" -o | awk -F_ '{print $$NF}'
endef

define get_new_version
$(eval base_version := $(shell $(call get_base_version,$(2)))) \
if [ "x$(base_version)" != "x" ];then \
    echo "$(1)" | sed "s/\(_[DRS]_\)[0-9]*\.[0-9]*/\1$(base_version)/"; \
else \
    echo "$(1)";\
fi
endef

define getprop
if [ -f $(2) ]; then \
    awk -F= '/$(1)/{print $$2}' $(2); \
fi
endef

define getMinSdkVersionFromApktoolYml
if [ -f $(1) ]; then awk '/minSdkVersion:/{print $$NF}' $(1) | grep '[0-9]*' -o; fi
endef

define getTargetSdkVersionFromApktoolYml
if [ -f $(1) ]; then awk '/targetSdkVersion:/{print $$NF}' $(1) | grep '[0-9]*' -o; fi
endef

define formatOverlay
if [ -d $(1) ]; then find $(1) -name "*.xml" | xargs sed -i 's/\( name *= *"\)android:/\1/g'; fi
endef

