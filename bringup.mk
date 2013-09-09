# bringup.mk

hide:=
############## Constants Definition #######################
REVISION_TOOL := ${PORT_ROOT}/tools/autopatch/revision.py
BAIDU_FRAMEWORK_DIR := $(BAIDU_DIR)/system/framework
BAIDU_SMALI_DIR := $(BAIDU_DIR)/smali
BAIDU_FRAMEWORK-RES_PUBLIC_XML := $(BAIDU_SMALI_DIR)/framework-res/res/values/public.xml

SOURCE_JARS += \
        framework.jar \
        services.jar

SOURCE_APPS += \
        framework-res

############## Prepare Baidu Smali Source #################
PREPARE_BAIDU_SOURCE :=

define decode_framework_app
PREPARE_BAIDU_SOURCE += decode_$(1)
.PHONY: decode_$(1)
decode_$(1): $(BAIDU_FRAMEWORK_DIR)/$(1).apk
	$(hide) mkdir -p $(BAIDU_SMALI_DIR)/$(1)
	$(hide) $(APKTOOL) d -f $(BAIDU_FRAMEWORK_DIR)/$(1).apk $(BAIDU_SMALI_DIR)/$(1)
endef


define decode_framework_jar
PREPARE_BAIDU_SOURCE += decode_$(1)
.PHONY: decode_$(1)
decode_$(1): $(BAIDU_FRAMEWORK_DIR)/$(1) decode_framework-res
	$(hide) mkdir -p $(BAIDU_SMALI_DIR)/$(1)
	$(hide) $(APKTOOL) d -f $(BAIDU_FRAMEWORK_DIR)/$(1) $(BAIDU_SMALI_DIR)/$(1).out
	$(hide) $(ID_TO_NAME_TOOL) $(BAIDU_FRAMEWORK-RES_PUBLIC_XML) $(BAIDU_SMALI_DIR)/$(1).out
endef

# Firstly, decode framework apps to prepare the framework-res
$(foreach app,$(SOURCE_APPS),\
        $(eval $(call decode_framework_app,$(app))))

# Secondly, decode framework jars
$(foreach jar,$(SOURCE_JARS),\
        $(eval $(call decode_framework_jar,$(jar))))

############## Execute bringup #######################
.PHONY: bringup

bringup: $(PREPARE_BAIDU_SOURCE)
	@echo ">>> bringup"
	$(hide) $(REVISION_TOOL)
