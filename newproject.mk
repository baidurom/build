OEM_TARGET_DIR			:= $(OUT_DIR)/oem_target_files
OEM_TARGET_ZIP			:= $(OUT_DIR)/oem_target_files.zip
OEM_TARGET_DEODEX_ZIP	:= $(OUT_DIR)/oem_target_files.zip.deodex.zip
VENDOR_TARGET_ZIP		:= $(OUT_DIR)/vendor_target_files.zip
VENDOR_TARGET_DIR		:= $(OUT_DIR)/vendor_target_files
VENDOR_OTA_ZIP			:= $(OUT_DIR)/vendor_ota.zip
METAINF					:= $(VENDOR_DIR)/METAINF
TARGET_FILES_FROM_DEVICE:= $(PORT_BUILD_TOOLS)/target_files_from_device.sh

##################### newproject ########################
./PHONY: newproject

newproject: prepare-vendor prepare-vendor-boot prepare-vendor-recovery prepare-metainf decodefile
	$(hide) if [ -f $(OUT_DIR)/build-info-to-user.txt ];then \
				cat $(OUT_DIR)/build-info-to-user.txt; \
			fi
	$(hide) echo ">>> newproject done"
	$(hide) echo "========================================================================================"
	$(hide) echo "Recommended Command:"
	$(hide) echo "    make vendorota  ->  build a vendor ota package to test whether newproject correctly."
	$(hide) echo "========================================================================================"

$(OEM_TARGET_ZIP): $(PRJ_RECOVERY_FSTAB)
	$(hide) $(TARGET_FILES_FROM_DEVICE) target

$(OEM_TARGET_DEODEX_ZIP): $(OEM_TARGET_ZIP)
	$(hide) $(DEODEX) $(OEM_TARGET_ZIP)

./PHONY: prepare-vendor
prepare-vendor: $(OEM_TARGET_DEODEX_ZIP)
	$(hide) rm -rf $(VENDOR_DIR)
	$(hide) echo ">>> unzip $(OEM_TARGET_DEODEX_ZIP) to $(VENDOR_DIR)"
	$(hide) unzip -q $(OEM_TARGET_DEODEX_ZIP) -d $(VENDOR_DIR)
	$(hide) if [ -d $(VENDOR_DIR)/SYSTEM ];then \
				mv $(VENDOR_DIR)/SYSTEM $(VENDOR_DIR)/system; \
			fi
	$(hide) echo ">>> prepare-vendor done"

ifeq ($(PRJ_RECOVERY_FSTAB),$(wildcard $(PRJ_RECOVERY_FSTAB)))
$(info # use $(PRJ_RECOVERY_FSTAB))
else
$(PRJ_RECOVERY_FSTAB): unpack-recovery
	$(hide) cp $(OUT_OBJ_RECOVERY_FSTAB) $@
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) echo ">>> get-recovery-fstab done"
endif

./PHONY: prepare-vendor-boot
prepare-vendor-boot : unpack-boot prepare-vendor
	$(hide) rm -rf $(VENDOR_BOOT)
	$(hide) if [ -d $(OUT_OBJ_BOOT) ]; then mv $(OUT_OBJ_BOOT) $(VENDOR_BOOT); fi;
	$(hide) echo ">>> prepare-vendor-boot done"

./PHONY: prepare-vendor-recovery
prepare-vendor-recovery: prepare-vendor
	$(hide) if [ -f $(VENDOR_SYSTEM)/build.prop ];then \
				echo ">>> auto catch the recovery prop"; \
				mkdir -p $(VENDOR_RECOVERY_RAMDISK); \
				TMPPROP=$$(grep "^ro.product.device=" $(VENDOR_SYSTEM)/build.prop); \
				if [ "$$TMPPROP" != "" ];then echo $$TMPPROP >  $(VENDOR_RECOVERY_RAMDISK)/default.prop; fi; \
				TMPPROP=$$(grep "^ro.build.product=" $(VENDOR_SYSTEM)/build.prop); \
				if [ "$$TMPPROP" != "" ];then echo $$TMPPROP >> $(VENDOR_RECOVERY_RAMDISK)/default.prop; fi; \
			fi
	$(hide) echo ">>> prepare-vendor-recovery done"

./PHONY: prepare-metainf
prepare-metainf: prepare-vendor
	$(hide) rm -rf $(METAINF)
	$(hide) unzip -q $(VENDOR_FRAMEWORK)/framework.jar -d $(METAINF)
	$(hide) rm -rf $(METAINF)/classes.dex $(METAINF)/assets
	$(hide) echo ">>> prepare-metainf done"

################ decode files ###########################

define decode_files
$(2): ifoemvendor
	$(hide) echo "decode $(1) $(2)"
	$(hide) rm -rf $(2)
	$(hide) $(APKTOOL) d -t $(APKTOOL_VENDOR_TAG) $(1) $(2)
endef

PRJ_DECODE_APKS		:= $(strip framework-res)
PRJ_DECODE_JARS		:= $(strip $(vendor_modify_jars))
PRJ_DECODE_APKS_OUT	:= $(sort $(strip $(patsubst %,$(PRJ_ROOT)/%,$(PRJ_DECODE_APKS))))
PRJ_DECODE_JARS_OUT	:= $(sort $(strip $(patsubst %,$(PRJ_ROOT)/%.jar.out,$(PRJ_DECODE_JARS))))

$(foreach file,$(PRJ_DECODE_APKS),\
	$(eval $(call decode_files, \
		$(patsubst %,$(VENDOR_SYSTEM)/framework/%.apk,$(file)), \
		$(patsubst %,$(PRJ_ROOT)/%,$(file)))))

$(foreach file,$(PRJ_DECODE_JARS),\
	$(eval $(call decode_files, \
		$(patsubst %,$(VENDOR_SYSTEM)/framework/%.jar,$(file)), \
		$(patsubst %,$(PRJ_ROOT)/%.jar.out,$(file)))))

ifoemvendor: prepare-vendor
	$(hide) $(call apktool_if_vendor,$(VENDOR_FRAMEWORK))

./PHONY: decodefile
decodefile: $(PRJ_DECODE_APKS_OUT) $(PRJ_DECODE_JARS_OUT)
	$(hide) echo ">>> decodefile done"

###################### vendor ota ########################
./PHONY: vendorota oemotarom

vendorota oemotarom: $(VENDOR_OTA_ZIP)
	$(hide) echo ">>> OUT ==> $(VENDOR_OTA_ZIP)"
	$(hide) echo ">>> build vendor ota done"

$(VENDOR_TARGET_ZIP): $(VENDOR_RECOVERY_FSTAB)
	$(hide) echo ">>> build vendor target files ..."
	$(hide) if [ ! -d $(OUT_DIR) ]; then mkdir -p $(OUT_DIR); fi
	$(hide) cd $(VENDOR_DIR); zip -qry $(PRJ_ROOT)/$(VENDOR_TARGET_ZIP).tmp *; cd - > /dev/null
	$(hide) unzip -q $(VENDOR_TARGET_ZIP).tmp -d $(VENDOR_TARGET_DIR)
	$(hide) rm -rf $(VENDOR_TARGET_ZIP).tmp
	$(hide) mv $(VENDOR_TARGET_DIR)/system $(VENDOR_TARGET_DIR)/SYSTEM
	$(hide) rm -rf $(VENDOR_TARGET_DIR)/BOOTABLE_IMAGES/ $(VENDOR_TARGET_DIR)/BOOT
	$(hide) if [ x"false" = x"$(strip $(RECOVERY_OTA_ASSERT))" ]; then \
				echo "recovery_ota_assert=false" >> $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
			fi
	$(hide) cd $(VENDOR_TARGET_DIR); zip -qry $(PRJ_ROOT)/$(VENDOR_TARGET_ZIP) *; cd - > /dev/null

$(VENDOR_OTA_ZIP): $(VENDOR_TARGET_ZIP)
	$(hide) echo ">>> build vendor ota package ..."
	$(hide) $(TARGET_FILES_FROM_DEVICE) ota
