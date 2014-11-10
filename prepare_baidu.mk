# use for preparing baidu resource from baidu.zip

$(BAIDU_ZIP): tempDir := $(shell mktemp -u)
$(BAIDU_ZIP):
	@ echo ">>> zip from $(BAIDU_RELEASE) to $@"
	$(hide) rm -rf $(BAIDU_ZIP)
	$(hide) mkdir -p $(tempDir)
	$(hide) cp -rf $(BAIDU_RELEASE)/* $(tempDir)
	$(hide) $(PORT_CUSTOM_BAIDU_ZIP) $(tempDir) $(DENSITY)
	@ echo ">>> Prepare baidu.zip ..."
	$(hide) cd $(tempDir) 2>&1 > /dev/null && zip baidu.zip * -rqy && cd - 2>&1 > /dev/null
	$(hide) mkdir -p `dirname $@`
	$(hide) mv $(tempDir)/baidu.zip $@
	$(hide) rm -rf $(tempDir)
	@ echo ">>> Prepare baidu.zip done!"

$(PREPARE_SOURCE): deodex_thread_num := $(shell echo "$(MAKE)" | awk '{print $$2}')
$(PREPARE_SOURCE): $(BAIDU_ZIP)
	$(hide) echo ">>> Deodex $(BAIDU_ZIP)"
	$(hide) $(DEODEX) $(BAIDU_ZIP) $(deodex_thread_num)
	$(hide) if [ -f $(BAIDU_ZIP).deodex.zip ];then \
				mv $(BAIDU_ZIP).deodex.zip $(BAIDU_ZIP); \
			else \
				echo ">>> ERROR: deodex $(BAIDU_ZIP) failed!!";\
				exit 1;\
		fi;
	$(hide) echo ">>> Deodex done!"
	$(hide) echo ">>> Prepare baidu sources";
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)
	$(hide) unzip -q -o $(BAIDU_ZIP) -d $(BAIDU_DIR);
	$(hide) if [ -d $(BAIDU_DIR)/SYSTEM ];then mv $(BAIDU_DIR)/SYSTEM $(BAIDU_DIR)/system;fi
ifneq ($(THEME_RES),)
	$(hide) unzip -q -o $(THEME_RES) -d $(BAIDU_DIR)/theme_full_res
endif
	$(hide) $(PORT_CUSTOM_BAIDU_ZIP) $(BAIDU_DIR) $(DENSITY)
	$(hide) if [ ! -d $(BAIDU_FRAMEWORK) ] \
			|| [ ! -d $(BAIDU_SYSTEM)/lib ] \
			|| [ ! -d $(BAIDU_SYSTEM)/app ];then \
				echo ">>> ERROR: source is not complete, please check."; \
				exit 1; \
			fi;
	$(hide) if [ -f $(BAIDU_DIR)/boot.img ]; then \
				boot_image=$(BAIDU_DIR)/boot.img; \
			else  \
				if [ -f $(BAIDU_DIR)/BOOTABLE_IMAGES/boot.img ]; then \
					boot_image=$(BAIDU_DIR)/BOOTABLE_IMAGES/boot.img; \
				fi; \
			fi; \
			if [ "x$$boot_image" != "x" -a ! -f $(BAIDU_DIR)/BOOT/RAMDISK/init ];then \
				echo ">>> unpack source/boot.img to source/BOOT"; \
				rm -rf $(BAIDU_DIR)/BOOT; \
				$(UNPACK_BOOT_PY) $$boot_image $(BAIDU_DIR)/BOOT; \
				rm -rf $(OUT_OBJ_BOOT)/boot.img; \
				echo ">>> prepare-source-boot done"; \
			fi;
	$(hide) if [ -f $(BAIDU_DIR)/recovery.img ]; then \
				recovery_image=$(BAIDU_DIR)/recovery.img; \
			else  \
				if [ -f $(BAIDU_DIR)/BOOTABLE_IMAGES/recovery.img ]; then \
					recovery_image=$(BAIDU_DIR)/BOOTABLE_IMAGES/recovery.img; \
				fi; \
			fi; \
			if [ "x$$recovery_image" != "x" -a ! -f $(BAIDU_DIR)/RECOVERY/RAMDISK/init ];then \
				echo ">>> unpack source/recovery.img to source/RECOVERY"; \
				rm -rf $(BAIDU_DIR)/RECOVERY; \
				$(UNPACK_BOOT_PY) $$recovery_image $(BAIDU_DIR)/RECOVERY; \
				rm -rf $(OUT_OBJ_BOOT)/recovery.img; \
				echo ">>> prepare-source-recovery done"; \
			fi;
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@
