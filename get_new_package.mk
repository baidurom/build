# use for get package from baidu inner server

################## unpack boot ################
BOOT_REC_DIR := $(PORT_BUILD)/boot_recovery
BASE_PLATFORM := $(strip $(BASE_PLATFORM))
ifeq ($(BOOT_REC_DIR)/unpack_boot_$(BASE_PLATFORM).sh,$(wildcard $(BOOT_REC_DIR)/unpack_boot_$(BASE_PLATFORM).sh))
PREPARE_UNPACK_BOOT_SH := $(BOOT_REC_DIR)/unpack_boot_$(BASE_PLATFORM).sh
else
PREPARE_UNPACK_BOOT_SH := $(BOOT_REC_DIR)/unpack_boot.sh
endif
$(info # use $(PREPARE_UNPACK_BOOT_SH))

# modify PACKAGE_PATH dynamically when make
ifneq ($(strip $(serverdir)),)
PACKAGE_PATH := $(serverdir)
endif

GET_PACKAGE_PARAMS :=
ifneq ($(strip $(PACKAGE_PATH)),)
GET_PACKAGE_PARAMS += -p $(PACKAGE_PATH)
endif
ifneq ($(strip $(BAIDU_BASE_BRANCH)),)
GET_PACKAGE_PARAMS += -b $(BAIDU_BASE_BRANCH)
endif
ifneq ($(strip $(BAIDU_BASE_DEVICE)),)
GET_PACKAGE_PARAMS += -d $(BAIDU_BASE_DEVICE)
endif
ifneq ($(strip $(BAIDU_ZIP)),)
GET_PACKAGE_PARAMS += -o $(BAIDU_ZIP)
endif

.PHONY: get-new-package prepare-source prepare-new-source
get-new-package $(BAIDU_BASE_ZIP): deodex_thread_num := $(shell echo "$(MAKE)" | awk '{print $$2}')
get-new-package $(BAIDU_BASE_ZIP):
	$(hide) echo ">>> Deodex $(BAIDU_ZIP)"
	$(hide) $(DEODEX) $(BAIDU_ZIP) $(deodex_thread_num)
	$(hide) if [ -f $(BAIDU_ZIP).deodex.zip ];then \
				mv $(BAIDU_ZIP).deodex.zip $(BAIDU_BASE_ZIP); \
			else \
				echo ">>> ERROR: deodex $(BAIDU_ZIP) failed!!";\
				exit 1;\
		fi;
	$(hide) echo ">>> Deodex done!"

ifeq ($(USER),baidu)
.PHONY: download-new-package
download-new-package $(BAIDU_ZIP):
	$(hide) echo ">>> Begin download-new-package"
	$(hide) if [ -n "$(BAIDU_BASE_VERSION)" ];then \
				$(GET_PACKAGE) $(GET_PACKAGE_PARAMS) -v $(BAIDU_BASE_VERSION); \
			else \
				$(GET_PACKAGE) $(GET_PACKAGE_PARAMS); \
			fi;
	$(hide) echo ">>> Finish getting package from server"	

ifeq ($(strip $(serverdir)),)
$(BAIDU_BASE_ZIP): $(BAIDU_ZIP)
else
$(BAIDU_BASE_ZIP): download-new-package
endif
get-new-package: download-new-package

prepare-new-source: clean get-new-package
	$(hide) echo ">>> Prepare baidu sources";
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)
	$(hide) unzip -q -o $(BAIDU_BASE_ZIP) -d $(BAIDU_DIR);
	$(hide) if [ -d $(BAIDU_DIR)/SYSTEM ];then mv $(BAIDU_DIR)/SYSTEM $(BAIDU_DIR)/system;fi
	$(hide) if [ ! -d $(BAIDU_FRAMEWORK) ] \
			|| [ ! -d $(BAIDU_META) ] \
			|| [ ! -d $(BAIDU_SYSTEM)/lib ] \
			|| [ ! -d $(BAIDU_SYSTEM)/app ];then \
				echo ">>> ERROR: source is not complete, please check."; \
				exit 1; \
			fi;
	$(hide) if [ -f $(BAIDU_DIR)/boot.img -a ! -d $(BAIDU_DIR)/BOOT ];then \
				echo ">>> unpack source/boot.img to source/BOOT"; \
				rm -rf $(OUT_OBJ_BOOT); \
				mkdir -p $(OUT_OBJ_BOOT); \
				cp $(BAIDU_DIR)/boot.img $(OUT_OBJ_BOOT); \
				cd $(OUT_OBJ_BOOT); $(PREPARE_UNPACK_BOOT_SH); cd -; \
				if [ ! -d $(OUT_OBJ_BOOT)/RAMDISK ];then \
					echo ">>> ERROR: can not find $(OUT_OBJ_BOOT)/RAMDISK, please check weather $(PREPARE_UNPACK_BOOT_SH) is right"; \
					exit 1; \
				fi; \
				rm $(OUT_OBJ_BOOT)/boot.img; \
				mv $(OUT_OBJ_BOOT) $(BAIDU_DIR); \
				echo ">>> prepare-source-boot done"; \
			fi;
else

$(BAIDU_BASE_ZIP): $(BAIDU_ZIP)

prepare-new-source:
	$(hide) echo ">>> Nothing to do: $@"
endif

prepare-source: $(BAIDU_BASE_ZIP)
	$(hide) echo ">>> Prepare baidu sources";
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)
	$(hide) unzip -q -o $(BAIDU_BASE_ZIP) -d $(BAIDU_DIR);
	$(hide) if [ -d $(BAIDU_DIR)/SYSTEM ];then mv $(BAIDU_DIR)/SYSTEM $(BAIDU_DIR)/system;fi
	$(hide) if [ ! -d $(BAIDU_FRAMEWORK) ] \
			|| [ ! -d $(BAIDU_SYSTEM)/lib ] \
			|| [ ! -d $(BAIDU_SYSTEM)/app ];then \
				echo ">>> ERROR: source is not complete, please check."; \
				exit 1; \
			fi;
	$(hide) if [ -f $(BAIDU_DIR)/boot.img -a ! -d $(BAIDU_DIR)/BOOT ];then \
				echo ">>> unpack source/boot.img to source/BOOT"; \
				rm -rf $(OUT_OBJ_BOOT); \
				mkdir -p $(OUT_OBJ_BOOT); \
				cp $(BAIDU_DIR)/boot.img $(OUT_OBJ_BOOT); \
				cd $(OUT_OBJ_BOOT); $(PREPARE_UNPACK_BOOT_SH); cd -; \
				if [ ! -d $(OUT_OBJ_BOOT)/RAMDISK ];then \
					echo ">>> ERROR: can not find $(OUT_OBJ_BOOT)/RAMDISK, please check weather $(PREPARE_UNPACK_BOOT_SH) is right"; \
					exit 1; \
				fi; \
				rm $(OUT_OBJ_BOOT)/boot.img; \
				mv $(OUT_OBJ_BOOT) $(BAIDU_DIR); \
				echo ">>> prepare-source-boot done"; \
			fi;
