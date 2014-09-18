# baidu_default.mk

PREBUILT_MK        := $(PORT_BUILD)/configs/prebuilt.mk
CONFIG_PREBUILT    := $(PORT_TOOLS)/config/config_prebuilt.py
BASE_VENDOR_SYSTEM := $(PORT_ROOT)/devices/base/vendor/system

ifeq ($(wildcard $(PREBUILT_MK)),)
ifneq ($(wildcard $(BASE_VENDOR_SYSTEM)),)
ifneq ($(wildcard $(BAIDU_RELEASE)/system),)
BAIDU_SYSTEM_FOR_GENERATE_PREBUILT := $(BAIDU_RELEASE)/system
else
ifneq ($(wildcard $(BAIDU_SYSTEM)),)
BAIDU_SYSTEM_FOR_GENERATE_PREBUILT := $(BAIDU_SYSTEM)
endif # ifneq ($(wildcard $(BAIDU_SYSTEM)),)
endif # ifneq ($(wildcard $(BAIDU_RELEASE)/system),)

ifneq ($(BAIDU_SYSTEM_FOR_GENERATE_PREBUILT),)
PREBUILT_MK          := $(OUT_OBJ_DIR)/prebuilt.mk
generate_prebuilt_mk := $(shell mkdir -p $(OUT_OBJ_DIR) && $(CONFIG_PREBUILT) $(PREBUILT_MK) $(BAIDU_SYSTEM_FOR_GENERATE_PREBUILT) $(BASE_VENDOR_SYSTEM))
endif 
endif # ifneq ($(wildcard $(BASE_VENDOR_SYSTEM)),)
endif # ifeq ($(wildcard $(PREBUILT_MK)),)

ifneq ($(wildcard $(PREBUILT_MK)),)
include $(PREBUILT_MK)
endif #ifneq ($(wildcard $(PREBUILT_MK)),)

include $(PORT_BUILD)/configs/black_prebuilt.mk
BAIDU_PREBUILT := $(filter-out $(BLACK_LIST_DIRS) $(BLACK_LIST),$(BAIDU_PREBUILT))
BAIDU_PREBUILT_DIRS := $(patsubst %/,%,$(filter-out $(BLACK_LIST_DIRS),$(patsubst %,%/,$(BAIDU_PREBUILT_DIRS))))

include $(PORT_BUILD)/configs/baidu_override.mk

ifeq ($(strip $(BAIDU_PRESIGNED_APPS)),)
$(info Warning: use default presigned apps, $(BAIDU_PRESIGNED_APPS_DEFAULT))
BAIDU_PRESIGNED_APPS := $(BAIDU_PRESIGNED_APPS_DEFAULT)
endif

# get all of the files in $(BAIDU_PREBUILT_DIRS)
$(foreach dirname,$(BAIDU_PREBUILT_DIRS), \
    $(eval BAIDU_PREBUILT += \
    $(sort $(filter-out $(BLACK_LIST_DIRS) $(BLACK_LIST),$(patsubst $(BAIDU_SYSTEM_FOR_POS)/%,%,$(call get_all_files_in_dir,$(BAIDU_SYSTEM_FOR_POS)/$(dirname)))))))

BAIDU_PREBUILT_DIRS := $(sort $(strip $(baidu_saved_dirs)) $(BAIDU_PREBUILT_DIRS))
BAIDU_PREBUILT := $(sort $(strip $(baidu_saved_files)) $(BAIDU_PREBUILT))

ifeq ($(strip $(LOW_RAM_DEVICE)),true)
$(info low ram device, remove $(BAIDU_PREBUILT_LOW_RAM_REMOVE))
BAIDU_PREBUILT := $(filter-out $(BAIDU_PREBUILT_LOW_RAM_REMOVE),$(BAIDU_PREBUILT))
endif

MINI_SYSTEM_SAVE_APPS         := $(strip $(MINI_SYSTEM_SAVE_APPS))
BAIDU_UPDATE_RES_APPS         := $(strip $(BAIDU_UPDATE_RES_APPS))
BAIDU_PRESIGNED_APPS          := $(strip $(BAIDU_PRESIGNED_APPS))
BAIDU_PREBUILT_LOW_RAM_REMOVE := $(strip $(BAIDU_PREBUILT_LOW_RAM_REMOVE))
BAIDU_PREBUILT                := $(strip $(BAIDU_PREBUILT))

