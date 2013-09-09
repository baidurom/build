# boot_recovery.mk

# Some custom defines
# BOOT_IMG := bootname					custom boot image name
# RECOVERY_IMG := recoveryname			custom recovery image name
# PRJ_UNPACK_BOOT_IMG := false			not unpack boot.img to BOOT
# PRJ_UNPACK_RECOVERY_IMG := false		not unpack recovery.img to RECOVERY

# PREPUILT_BOOT_IMG := true				use prebuilt boot.img
# PREPUILT_BOOT_IMG := flase			pack boot.img from vendor/BOOT
# PREPUILT_BOOT_IMG :=					none boot.img

# PREPUILT_RECOVERY_IMG := true			use prebuilt recovery.img
# PREPUILT_RECOVERY_IMG := flase		pack recovery.img from source/RECOVERY
# PREPUILT_RECOVERY_IMG :=				none recovery.img

# Some custom shell
# $(PRJ_ROOT)/override_unpack_boot.sh	used for unpack boot.img
# $(PRJ_ROOT)/override_pack_boot.sh		used for pack boot.img
# $(PRJ_ROOT)/override_unpack_rec.sh	used for unpack recovery.img
# $(PRJ_ROOT)/override_pack_rec.sh		used for pack recovery.img

BOOT_REC_DIR := $(PORT_BUILD)/boot_recovery
PLATFORM := $(strip $(PLATFORM))
######################## boot #############################
ifeq ($(strip $(BOOT_IMG)),)
BOOT_IMG                 := boot.img
endif
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
ifeq ($(PRJ_ROOT)/override_unpack_boot.sh,$(wildcard $(PRJ_ROOT)/override_unpack_boot.sh))
UNPACK_BOOT_SH := $(PRJ_ROOT)/override_unpack_boot.sh
else
ifeq ($(BOOT_REC_DIR)/unpack_boot_$(PLATFORM).sh,$(wildcard $(BOOT_REC_DIR)/unpack_boot_$(PLATFORM).sh))
UNPACK_BOOT_SH := $(BOOT_REC_DIR)/unpack_boot_$(PLATFORM).sh
else
UNPACK_BOOT_SH := $(BOOT_REC_DIR)/unpack_boot.sh
endif
endif
$(info # use $(UNPACK_BOOT_SH))

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

ifneq ($(strip $(PRJ_UNPACK_BOOT_IMG)),false)
# unpack boot.img to out/obj/BOOT
unpack-boot:
	$(hide) rm -rf $(OUT_OBJ_BOOT)
	$(hide) mkdir -p $(OUT_OBJ_BOOT)
	$(hide) cp $(PRJ_BOOT_IMG) $(OUT_OBJ_BOOT)
	$(hide)	cd $(OUT_OBJ_BOOT); $(UNPACK_BOOT_SH); cd -
	$(hide) $(call enable_adb_root,$(OUT_OBJ_BOOT)/RAMDISK/default.prop)
	$(hide) rm $(OUT_OBJ_BOOT)/$(BOOT_IMG)
else
unpack-boot:
	$(hide) echo "Nothing to do: $@"
endif

###### pack boot ######
ifeq ($(PRJ_ROOT)/override_pack_boot.sh,$(wildcard $(PRJ_ROOT)/override_pack_boot.sh))
PACK_BOOT_SH := $(PRJ_ROOT)/override_pack_boot.sh
else
ifeq ($(BOOT_REC_DIR)/pack_boot_$(PLATFORM).sh,$(wildcard $(BOOT_REC_DIR)/pack_boot_$(PLATFORM).sh))
PACK_BOOT_SH := $(BOOT_REC_DIR)/pack_boot_$(PLATFORM).sh
else
PACK_BOOT_SH := $(BOOT_REC_DIR)/pack_boot.sh
endif
endif
$(info # use build/pack_boot.sh)

ifeq ($(strip $(PREBUILT_BOOT_IMG)),)
bootimage:
	@ echo ">>> Nothing to do: $@"

else
bootimage: $(OUT_BOOT_IMG)

ifeq ($(strip $(PREBUILT_BOOT_IMG)),true)
$(OUT_BOOT_IMG):
	$(hide) echo ">>> use prebuilt $(BOOT_IMG)"
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(PRJ_BOOT_IMG) $@
	$(hide) cp $(PRJ_BOOT_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(BOOT_IMG)"

else
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
	$(hide) cd $(OUT_OBJ_BOOT); $(PACK_BOOT_SH); cd -
	$(hide) if [ ! -d `dirname $(OUT_BOOT_IMG)` ]; then mkdir -p `dirname $(OUT_BOOT_IMG)`; fi;
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(OUT_OBJ_BOOT)/$(BOOT_IMG) $@
	$(hide) cp $(OUT_OBJ_BOOT)/$(BOOT_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(BOOT_IMG)"
endif
endif

######################## recovery #############################
ifeq ($(strip $(RECOVERY_IMG)),)
RECOVERY_IMG            := recovery.img
endif
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
ifeq ($(PRJ_ROOT)/override_unpack_rec.sh,$(wildcard $(PRJ_ROOT)/override_unpack_rec.sh))
UNPACK_REC_SH := $(PRJ_ROOT)/override_unpack_rec.sh
else
ifeq ($(BOOT_REC_DIR)/unpack_rec_$(PLATFORM).sh,$(wildcard $(BOOT_REC_DIR)/unpack_rec_$(PLATFORM).sh))
UNPACK_REC_SH := $(BOOT_REC_DIR)/unpack_rec_$(PLATFORM).sh
else
UNPACK_REC_SH := $(BOOT_REC_DIR)/unpack_rec.sh
endif
endif
$(info # use $(UNPACK_REC_SH))

ifneq ($(strip $(PRJ_UNPACK_REC_IMG)),false)
# unpack other/recovery.img to out/obj/RECOVERY
unpack-recovery:
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) mkdir -p $(OUT_OBJ_RECOVERY)
	$(hide) cp $(PRJ_RECOVERY_IMG) $(OUT_OBJ_RECOVERY)
	$(hide)	cd $(OUT_OBJ_RECOVERY); $(UNPACK_REC_SH); cd -
	$(hide) rm $(OUT_OBJ_RECOVERY)/$(RECOVERY_IMG)
else
unpack-recovery:
	$(hide) echo ">>> Nothing to do: $@"
endif

###### pack recovery ######
ifeq ($(PRJ_ROOT)/override_pack_rec.sh,$(wildcard $(PRJ_ROOT)/override_pack_rec.sh))
PACK_REC_SH := $(PRJ_ROOT)/override_pack_rec.sh
else
ifeq ($(BOOT_REC_DIR)/pack_rec_$(PLATFORM).sh,$(wildcard $(BOOT_REC_DIR)/pack_rec_$(PLATFORM).sh))
PACK_REC_SH := $(BOOT_REC_DIR)/pack_rec_$(PLATFORM).sh
else
PACK_REC_SH := $(BOOT_REC_DIR)/pack_rec.sh
endif
endif
$(info # use $(PACK_REC_SH))

ifeq ($(strip $(PREBUILT_RECOVERY_IMG)),)
recoveryimage: $(OUT_RECOVERY_FSTAB)
	$(hide) echo ">>> Nothing to do: $@"
else
recoveryimage: $(OUT_RECOVERY_IMG) $(OUT_RECOVERY_FSTAB)

ifeq ($(strip $(PREBUILT_RECOVERY_IMG)),true)
$(OUT_RECOVERY_IMG): $(PRJ_RECOVERY_IMG)
	$(hide) echo ">>> use prebuilt $(RECOVERY_IMG)"
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(PRJ_RECOVERY_IMG) $@
	$(hide) cp $(PRJ_RECOVERY_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(RECOVERY_IMG)"

else
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
	$(hide) cd $(OUT_OBJ_RECOVERY); $(PACK_REC_SH); cd -
	$(hide) if [ ! -d `dirname $(OUT_RECOVERY_IMG)` ]; then mkdir -p `dirname $(OUT_RECOVERY_IMG)`; fi;
	$(hide) mkdir -p `dirname $@`
	$(hide) cp $(OUT_OBJ_RECOVERY)/$(RECOVERY_IMG) $@
	$(hide) cp $(OUT_OBJ_RECOVERY)/$(RECOVERY_IMG) $(OUT_DIR)
	$(hide) echo ">>> Target Out ==> $@, $(OUT_DIR)/$(RECOVERY_IMG)"
endif
endif

$(OUT_RECOVERY_FSTAB): $(VENDOR_RECOVERY_FSTAB)
	$(hide) $(call file_copy,$(VENDOR_RECOVERY_FSTAB),$(OUT_RECOVERY_FSTAB))
	$(hide) echo ">>> Target Out ==> $@"
##############################################################

