# boot_recovery.mk

# Some custom defines
# vendor_modify_images := boot/boot.img recovery/recovery.img

UNPACK_BOOT_PY := $(PORT_ROOT)/tools/bootimgpack/unpack_bootimg.py
PACK_BOOT_PY := $(PORT_ROOT)/tools/bootimgpack/pack_bootimg.py

######################## boot #############################
BOOT_IMG                 := boot.img
PRJ_BOOT_IMG             := $(PRJ_ROOT)/$(BOOT_IMG)
VENDOR_BOOT              := $(VENDOR_DIR)/BOOT
SOURCE_BOOT              := $(BAIDU_DIR)/BOOT
OUT_OBJ_BOOT             := $(OUT_OBJ_DIR)/BOOT
OUT_BOOT_IMG             := $(OUT_BOOTABLE_IMAGES)/$(BOOT_IMG)

SOURCE_BOOT_RAMDISK_SERVICEEXT  := $(SOURCE_BOOT)/RAMDISK/sbin/serviceext
OUT_OBJ_BOOT_RAMDISK_SERVICEEXT	:= $(OUT_OBJ_BOOT)/RAMDISK/sbin/serviceext
VENDOR_BOOT_KERNEL              := $(VENDOR_BOOT)/kernel
OUT_OBJ_BOOT_KERNEL             := $(OUT_OBJ_BOOT)/kernel

###### unpack boot ######

define enable_adb_root
if [ -f $(1) ]; then \
    sed -i 's/\(ro.secure=\).*/\10/g' $(1); \
    sed -i 's/\(ro.debuggable=\).*/\11/g' $(1); \
    if [ "x`grep 'persist.sys.usb.config=' $(1)`" = "x" ]; then \
        echo 'persist.sys.usb.config=adb' >> $(1); \
    elif [ "x`grep 'persist.sys.usb.config=' $(1) | grep adb`" = "x" ]; then \
        sed -i 's/\(persist.sys.usb.config=.*\)/\1,adb/g' $(1); \
    fi; \
    if [ "x`grep 'persist.service.adb.enable' $(1)`" != "x" ]; then \
        sed -i 's/\(persist.service.adb.enable=\).*/\11/g' $(1); \
    fi; \
fi
endef

ifeq ($(strip $(filter boot boot.img, $(vendor_modify_images))),)
unpack-boot:
	$(hide) echo ">>> Nothing to do: $@"
	$(hide) echo ">>> Warning: newproject without preparing vendor/BOOT directory"
else
# unpack boot.img to out/obj/BOOT
unpack-boot: $(PRJ_BOOT_IMG)
	$(hide) rm -rf $(OUT_OBJ_BOOT)
	$(hide)	$(UNPACK_BOOT_PY) $(PRJ_BOOT_IMG) $(OUT_OBJ_BOOT);
	$(hide) $(call enable_adb_root,$(OUT_OBJ_BOOT)/RAMDISK/default.prop)
endif

###### pack boot ######
ifeq ($(strip $(filter boot boot.img, $(vendor_modify_images))),)
ifeq ($(PRJ_BOOT_IMG), $(wildcard $(PRJ_BOOT_IMG)))
bootimage: $(OUT_BOOT_IMG)
$(OUT_BOOT_IMG):
	$(hide) echo ">>> use prebuilt $(BOOT_IMG)"
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(PRJ_BOOT_IMG) $@
	$(hide) cp $(PRJ_BOOT_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(BOOT_IMG)"
else
bootimage:
	$(hide) echo ">>> Nothing to do: $@"
endif

else
bootimage: $(OUT_BOOT_IMG)

BOOT_PREBUILT_FILES := $(SOURCE_BOOT_RAMDISK_SERVICEEXT):$(OUT_OBJ_BOOT_RAMDISK_SERVICEEXT)
.PHONY: prepare_boot_ramdisk
prepare_boot_ramdisk:
	$(hide) rm -rf $(OUT_OBJ_BOOT);
	$(hide) mkdir -p $(OUT_OBJ_BOOT);
	$(hide) cp -r $(VENDOR_BOOT)/* $(OUT_OBJ_BOOT);
	$(hide) $(foreach prebuilt_pair,$(BOOT_PREBUILT_FILES),\
			$(eval src_file := $(call word-colon,1,$(prebuilt_pair)))\
			$(eval dst_file := $(call word-colon,2,$(prebuilt_pair)))\
			$(call safe_file_copy,$(src_file),$(dst_file)))

$(OUT_BOOT_IMG): prepare_boot_ramdisk
	$(hide) echo ">>> pack $(BOOT_IMG)"
	$(hide) mkdir -p `dirname $@`
	$(hide) $(PACK_BOOT_PY) $(OUT_OBJ_BOOT) $@
	$(hide) cp $@ $(OUT_DIR)/$(BOOT_IMG)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(BOOT_IMG)"
endif

######################## recovery #############################
RECOVERY_IMG            := recovery.img
PRJ_RECOVERY_IMG        := $(PRJ_ROOT)/$(RECOVERY_IMG)
PRJ_RECOVERY_FSTAB      := $(PRJ_ROOT)/recovery.fstab
VENDOR_RECOVERY         := $(VENDOR_DIR)/RECOVERY
SOURCE_RECOVERY         := $(BAIDU_DIR)/RECOVERY
OUT_OBJ_RECOVERY        := $(OUT_OBJ_DIR)/RECOVERY
OUT_RECOVERY_IMG        := $(OUT_BOOTABLE_IMAGES)/$(RECOVERY_IMG)
OUT_RECOVERY_FSTAB      := $(OUT_RECOVERY)/RAMDISK/etc/recovery.fstab

VENDOR_RECOVERY_KERNEL       := $(VENDOR_RECOVERY)/kernel
VENDOR_RECOVERY_RAMDISK	     := $(VENDOR_RECOVERY)/RAMDISK
VENDOR_RECOVERY_FSTAB        := $(VENDOR_RECOVERY_RAMDISK)/etc/recovery.fstab
VENDOR_RECOVERY_DEFAULT_PROP := $(VENDOR_RECOVERY_RAMDISK)/default.prop
SOURCE_RECOVERY_RAMDISK      := $(SOURCE_RECOVERY)/RAMDISK
OUT_OBJ_RECOVERY_KERNEL      := $(OUT_OBJ_RECOVERY)/kernel
OUT_OBJ_RECOVERY_RAMDISK     := $(OUT_OBJ_RECOVERY)/RAMDISK
OUT_OBJ_RECOVERY_FSTAB       := $(OUT_OBJ_RECOVERY_RAMDISK)/etc/recovery.fstab
OUT_OBJ_RECOVERY_DEFAULT_PROP:= $(OUT_OBJ_RECOVERY_RAMDISK)/default.prop

###### unpack recovery ######

# unpack recovery.img to out/obj/RECOVERY
unpack-recovery:
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) $(UNPACK_BOOT_PY) $(PRJ_RECOVERY_IMG) $(OUT_OBJ_RECOVERY)

###### pack recovery ######
ifeq ($(strip $(filter recovery recovery.img, $(vendor_modify_images))),)
ifeq ($(PRJ_RECOVERY_IMG), $(wildcard $(PRJ_RECOVERY_IMG)))
recoveryimage: $(OUT_RECOVERY_IMG) $(OUT_RECOVERY_FSTAB)
$(OUT_RECOVERY_IMG): $(PRJ_RECOVERY_IMG)
	$(hide) echo ">>> use prebuilt $(RECOVERY_IMG)"
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(PRJ_RECOVERY_IMG) $@
	$(hide) cp $(PRJ_RECOVERY_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(RECOVERY_IMG)"
else
recoveryimage: $(OUT_RECOVERY_FSTAB)
	$(hide) echo ">>> Nothing to do: $@"
endif

else
recoveryimage: $(OUT_RECOVERY_IMG) $(OUT_RECOVERY_FSTAB)
RECOVERY_PREBUILT_FILES := $(VENDOR_RECOVERY_FSTAB):$(OUT_OBJ_RECOVERY_FSTAB)
RECOVERY_PREBUILT_FILES += $(VENDOR_BOOT_KERNEL):$(OUT_OBJ_RECOVERY_KERNEL)

.PHONY: prepare_recovery_ramdisk
prepare_recovery_ramdisk:
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) mkdir -p $(OUT_OBJ_RECOVERY);
	$(hide) cp -r $(VENDOR_BOOT)/* $(OUT_OBJ_RECOVERY);
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)/RAMDISK/;
	$(hide) cp -r $(SOURCE_RECOVERY)/RAMDISK/ $(OUT_OBJ_RECOVERY);
	$(hide) $(foreach prebuilt_pair,$(RECOVERY_PREBUILT_FILES),\
				$(eval src_file := $(call word-colon,1,$(prebuilt_pair)))\
				$(eval dst_file := $(call word-colon,2,$(prebuilt_pair)))\
				$(call file_copy,$(src_file),$(dst_file)))

$(OUT_RECOVERY_IMG): prepare_recovery_ramdisk
	$(hide) echo ">>> pack $(RECOVERY_IMG)"
	$(hide) if [ -f $(VENDOR_RECOVERY_DEFAULT_PROP) ];then \
				cat $(VENDOR_RECOVERY_DEFAULT_PROP) | grep -v '^ *#' | while read LINE; \
				do \
					prop_name=`echo $$LINE | awk -F= '{print $$1}' | sed 's/^ *//g;s/ *$$//g'`; \
					echo ">>> $(RECOVERY_IMG): override default.prop, prop name: $$prop_name, line: $$LINE"; \
					sed -i "/^ *$$prop_name *=/d" $(OUT_OBJ_RECOVERY_DEFAULT_PROP); \
				done; \
				cat $(VENDOR_RECOVERY_DEFAULT_PROP) >> $(OUT_OBJ_RECOVERY_DEFAULT_PROP); \
			fi
	$(hide) $(PACK_BOOT_PY) $(OUT_OBJ_RECOVERY) $@
	$(hide) cp $@ $(OUT_DIR)/$(RECOVERY_IMG)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(RECOVERY_IMG)"
endif

$(OUT_RECOVERY_FSTAB): $(VENDOR_RECOVERY_FSTAB)
	$(hide) $(call file_copy,$(VENDOR_RECOVERY_FSTAB),$(OUT_RECOVERY_FSTAB))
	$(hide) echo ">>> Target Out ==> $@"
##############################################################

