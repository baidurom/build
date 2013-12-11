OEM_TARGET_DIR			:= $(OUT_DIR)/oem_target_files
OEM_TARGET_ZIP			:= $(OUT_DIR)/oem_target_files.zip
OEM_TARGET_DEODEX_ZIP	:= $(OUT_DIR)/oem_target_files.zip.deodex.zip
OEM_OTA_ZIP				:= $(OUT_DIR)/oem_ota_rom.zip
METAINF					:= $(VENDOR_DIR)/METAINF
TARGET_FILES_FROM_DEVICE:= $(PORT_TOOLS)/target_files_from_device.sh

############# newproject, oemotarom #####################
./PHONY: newproject oemotarom
ifeq ($(PRJ_BOOT_IMG), $(wildcard $(PRJ_BOOT_IMG)))
newproject: prepare-vendor prepare-vendor-boot prepare-vendor-recovery prepare-metainf decodefile
	$(hide) if [ -f $(OUT_DIR)/build-info-to-user.txt ];then \
				cat $(OUT_DIR)/build-info-to-user.txt; \
			fi
	$(hide) echo ">>> newproject done"
else
newproject: prepare-vendor prepare-vendor-recovery prepare-metainf decodefile
	$(hide) if [ -f $(OUT_DIR)/build-info-to-user.txt ];then \
				cat $(OUT_DIR)/build-info-to-user.txt; \
			fi
	$(hide) echo ">>> newproject without preparing vendor/BOOT directory"
	$(hide) echo ">>> newproject done"
endif

oemotarom: $(OEM_OTA_ZIP)
	$(hide) echo ">>> oemotarom done"

$(OEM_TARGET_ZIP): $(PRJ_RECOVERY_FSTAB)
	$(hide) $(TARGET_FILES_FROM_DEVICE) target

$(OEM_OTA_ZIP): $(OEM_TARGET_ZIP)
	$(hide) $(TARGET_FILES_FROM_DEVICE) ota

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
	$(hide) cp $(OEM_TARGET_DEODEX_ZIP) $(VENDOR_DIR)/vendor.zip
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
	$(hide) mv $(OUT_OBJ_BOOT) $(VENDOR_BOOT)
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
	$(hide) rm -f $(METAINF)/classes.dex
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
