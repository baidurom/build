# otadiff.mk

PRJ_OUT_OTA_DIFF := $(OUT_DIR)/ota_diff_$(basename $(notdir $(PRE)))-$(VERSION_NUMBER).zip

.PHONY: otadiff

ifeq ($(wildcard $(PRJ_OUT_TARGET_ZIP)),)
otadiff: otapackage
endif

otadiff:
	$(hide) $(if $(wildcard $(PRE)),,echo "File $(PRE) doesn't exist!"; exit 1)
	$(hide) otadiff $(PRE) $(PRJ_OUT_TARGET_ZIP) $(PRJ_OUT_OTA_DIFF)
