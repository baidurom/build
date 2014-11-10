# otadiff.mk

.PHONY: otadiff

ifeq ($(wildcard $(PRJ_OUT_TARGET_ZIP)),)
otadiff: otapackage
endif

ifneq ($(wildcard $(PRE)),)
PRE_TARGET_ZIP := $(PRE)
endif

ifneq ($(wildcard $(PRE_TARGET_ZIP)),)
otadiff:
	@echo ">>> build Incremental OTA Package from $(PRE_TARGET_ZIP) to $(PRJ_OUT_TARGET_ZIP)"
	$(hide) otadiff $(PRE_TARGET_ZIP) $(PRJ_OUT_TARGET_ZIP)
else
otadiff:
	@echo "USAGE:"
	@echo "   Preparing target_files.zip of previous version in current directory,   "
	@echo "   make otadiff => build an Incremental OTA Package.                      "
	@echo "   make otadiff PRE=xx/xx/target_files_xx.zip => specify previous package."
	@echo "   make otadiff PRE=xx/xx/ota_xx.zip => specify previous ota package.     "
	$(hide) exit 1
endif
	 