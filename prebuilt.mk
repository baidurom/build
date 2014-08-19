# prebuilt.mk

# config for vendor, which need remove from vendor files
PREBUILT_TARGET      :=
BAIDU_PREBUILT_FILES :=

################# prepare-vendor ##############################
# remove the files which in vendor_remove_dirs
VENDOR_PREBUILT_FILES := $(ALL_VENDOR_FILES)
$(foreach removeDirs,$(VENDOR_REMOVE_DIRS), \
    $(eval VENDOR_PREBUILT_FILES:=$(filter-out $(removeDirs)/%,$(VENDOR_PREBUILT_FILES))))

# remove the files which define in vendor_remove_files
VENDOR_PREBUILT_FILES:=$(filter-out $(VENDOR_REMOVE_FILES),$(VENDOR_PREBUILT_FILES))

#$(info # PRJ_CUSTOM_TARGET:$(PRJ_CUSTOM_TARGET))
# remove the files which are define in project
VENDOR_PREBUILT_FILES:=$(filter-out $(PRJ_CUSTOM_TARGET), $(VENDOR_PREBUILT_FILES))

VENDOR_PREBUILT_FILES += $(VENDOR_PREBUILT_APPS)
############## prepare baidu prebuilt #########################
# get all of the files in $(BAIDU_PREBUILT_DIRS)
$(foreach dirname,$(BAIDU_PREBUILT_DIRS), \
    $(eval BAIDU_PREBUILT_FILES += \
    $(sort $(patsubst $(BAIDU_SYSTEM)/%,%,$(call get_all_files_in_dir,$(BAIDU_SYSTEM)/$(dirname))))))

# filter the target which are not prebuilt
BAIDU_PREBUILT_FILES += $(strip $(BAIDU_PREBUILT_APPS) $(BAIDU_PREBUILT))
BAIDU_PREBUILT_FILES := $(sort $(strip $(filter-out $(PRJ_CUSTOM_TARGET),$(BAIDU_PREBUILT_FILES))))
BAIDU_PREBUILT_FILES := $(filter-out %.apk,$(BAIDU_PREBUILT_FILES))

# filter these files which are not exist!!
BAIDU_PREBUILT_FILES := $(filter $(ALL_BAIDU_FILES),$(BAIDU_PREBUILT_FILES))
BAIDU_PREBUILT_FILES := $(filter-out $(VENDOR_PREBUILT_APPS),$(BAIDU_PREBUILT_FILES))

VENDOR_PREBUILT_FILES := $(filter-out $(BAIDU_PREBUILT_FILES),$(VENDOR_PREBUILT_FILES))

# filter the apks, which need sign
VENDOR_SIGN_APPS := $(filter %.apk,$(VENDOR_PREBUILT_FILES))
$(foreach apk,$(VENDOR_SIGN_APPS),\
    $(eval SIGN_APPS += $(VENDOR_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))

#$(info # VENDOR_SIGN_APPS:$(VENDOR_SIGN_APPS))

VENDOR_PREBUILT_FILES := $(filter-out %.apk,$(VENDOR_PREBUILT_FILES))
################## define the prebuilt targets ###############

$(foreach file,$(VENDOR_PREBUILT_FILES),\
     $(eval $(call prebuilt_template,$(VENDOR_SYSTEM)/$(file),$(OUT_SYSTEM)/$(file))))

$(foreach file,$(BAIDU_PREBUILT_FILES),\
     $(eval $(call prebuilt_template,$(BAIDU_SYSTEM)/$(file),$(OUT_SYSTEM)/$(file))))

############ bootanimation&shutdownanimation   ###############
RESOLUTION := $(strip $(RESOLUTION))
ifneq ($(RESOLUTION),)
	ifneq ($(wildcard $(BAIDU_BOOTANIMATION)/bootanimation_$(RESOLUTION).zip),)
        $(eval $(call prebuilt_template,$(BAIDU_BOOTANIMATION)/bootanimation_$(RESOLUTION).zip,$(OUT_SYSTEM)/media/bootanimation.zip))
	endif
	ifneq ($(wildcard $(BAIDU_BOOTANIMATION)/shutdownanimation_$(RESOLUTION).zip),)
        $(eval $(call prebuilt_template,$(BAIDU_BOOTANIMATION)/shutdownanimation_$(RESOLUTION).zip,$(OUT_SYSTEM)/media/shutdownanimation.zip))
	endif
endif

###################### prebuilt ##############################
OTA_TARGETS += prebuilt
prebuilt: $(PREBUILT_TARGET)
	$(hide) echo ">>> prebuilt-files done"

