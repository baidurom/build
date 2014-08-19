
DECODE_TARGET_BAIDU :=
DECODE_TARGET_VENDOR :=
DECODE_TARGET_MERGED :=
NEED_COMPELETE_MODULE :=
$(foreach pair,$(NEED_COMPELETE_MODULE_PAIR),\
     $(eval src := $(call word-colon,1,$(pair)))\
     $(eval dst := $(call word-colon,2,$(pair)))\
     $(eval baidu_src := $(patsubst %,$(BAIDU_SYSTEM)/%,$(strip $(src))))\
     $(eval baidu_target := $(patsubst %,$(AUTOCOM_BAIDU)/%,$(strip $(dst))))\
     $(eval $(call decode_baidu,$(baidu_src),$(baidu_target)))\
     $(eval $(baidu_src): $(PREPARE_SOURCE))\
     $(eval DECODE_TARGET_BAIDU += $(baidu_target)/apktool.yml)\
     $(eval vendor_src := $(patsubst %,$(VENDOR_SYSTEM)/%,$(strip $(src))))\
     $(eval vendor_target := $(patsubst %,$(AUTOCOM_VENDOR)/%,$(strip $(dst))))\
     $(if $(wildcard $(vendor_src)),\
          $(eval NEED_COMPELETE_MODULE += $(dst))\
          $(eval $(call decode_vendor,$(vendor_src),$(vendor_target)))\
          $(eval DECODE_TARGET_VENDOR += $(vendor_target)/apktool.yml)))


$(foreach pair,$(VENDOR_COM_MODULE_PAIR),\
     $(eval src := $(call word-colon,1,$(pair)))\
     $(eval dst := $(call word-colon,2,$(pair)))\
     $(eval vendor_src := $(patsubst %,$(VENDOR_SYSTEM)/%,$(strip $(src))))\
     $(eval vendor_target := $(patsubst %,$(AUTOCOM_MERGED)/%,$(strip $(dst))))\
     $(eval $(call decode_vendor,$(vendor_src),$(vendor_target)))\
     $(eval DECODE_TARGET_MERGED += $(vendor_target)/apktool.yml))

.PHONY: autocom_prepare_baidu autocom_prepare_vendor autocom_prepare_merged

autocom_prepare_baidu $(AUTOCOM_PREPARE_BAIDU): $(DECODE_TARGET_BAIDU)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_BAIDU)`
	$(hide) touch $(AUTOCOM_PREPARE_BAIDU)

autocom_prepare_vendor $(AUTOCOM_PREPARE_VENDOR): $(DECODE_TARGET_VENDOR)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_VENDOR)`
	$(hide) touch $(AUTOCOM_PREPARE_VENDOR)

autocom_prepare_merged $(AUTOCOM_PREPARE_MERGED): $(AUTOCOM_PREPARE_VENDOR) $(AUTOCOM_PREPARE_BAIDU) $(DECODE_TARGET_MERGED)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_MERGED)`
	$(hide) $(foreach vModifyJar,$(vendor_modify_jars),cp -rf $(PRJ_ROOT)/$(vModifyJar).jar.out $(AUTOCOM_MERGED);)
	$(hide) cp -rf $(AUTOCOM_BAIDU)/* $(AUTOCOM_MERGED);
	$(hide) touch $(AUTOCOM_PREPARE_MERGED)

autocom $(AUTOCOM_PRECONDITION): $(AUTOCOM_PREPARE_BAIDU) $(AUTOCOM_PREPARE_VENDOR) $(AUTOCOM_PREPARE_MERGED)
	@echo ">>> checking precondition for autocomplete missed methods ..."
	$(hide) rm -rf $(AUTOCOM_PRECONDITION)
	$(if $(NEED_COMPELETE_MODULE),$(SCHECK) --autocomplete \
				$(AUTOCOM_VENDOR) \
				$(AOSP_DIR) \
				$(AUTOCOM_BAIDU) \
				$(AUTOCOM_MERGED) \
				$(PRJ_ROOT) \
				$(NEED_COMPELETE_MODULE),)
	$(hide) touch $(AUTOCOM_PRECONDITION)
	@echo "<<< checking precondition for autocomplete missed methods Done."

# auto fix reject
AUTOFIX_TARGET_LIST := $(patsubst %,%.jar.out,$(vendor_modify_jars))
AUTOFIX_DECODE_JARS := $(patsubst %,$(VENDOR_FRAMEWORK)/%,core.jar)
AUTOFIX_OBJ_TARGET_LIST := $(patsubst %,$(AUTOFIX_TARGET)/%,$(AUTOFIX_TARGET_LIST))

.PHONY: autofix_check
autofix_check:
	$(hide) if [ ! -d $(OUT_DIR)/reject ]; then \
				echo ">>>> Error: $(OUT_DIR)/reject doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;
	$(hide) if [ ! -d autopatch/bosp ]; then \
				echo ">>>> Error: autopatch/bosp doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;
	$(hide) if [ ! -d autopatch/aosp ]; then \
				echo ">>>> Error: autopatch/aosp doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;

.PHONY: autofix_prepare_target
$(AUTOFIX_PREPARE_TARGET): $(IF_VENDOR_RES)
	$(hide) rm -rf $(AUTOFIX_TARGET)
	$(hide) mkdir -p $(AUTOFIX_TARGET)
	$(hide) $(foreach jar,$(AUTOFIX_TARGET_LIST), \
				if [ -d $(jar) ]; then \
					$(call dir_copy,$(jar),$(AUTOFIX_TARGET)/$(jar)) \
					$(eval jarBaseName := $(call getBaseName,$(call getBaseName,$(jar)))) \
					$(foreach package,$(BAIDU_PREBUILT_PACKAGE_$(jarBaseName)),\
						$(eval srcDir := autopatch/bosp/$(jar)/smali/$(package)) \
						$(eval destDir := $(AUTOFIX_TARGET)/$(jar)/smali/$(package)) \
						$(call safe_dir_copy,$(srcDir),$(destDir))) \
				else \
					echo ">>> Warning: $(jar) doesn't exsit! Are you run 'makeconfig' and 'make newproject' before?"; \
					echo "             this may cause AttributeError when run reject.py"; \
				fi;)
	$(hide) $(foreach jar,$(AUTOFIX_DECODE_JARS),$(call decode,$(jar),$(AUTOFIX_TARGET)/$(notdir $(jar)).out,$(APKTOOL_VENDOR_TAG)))
	$(hide) touch $(AUTOFIX_PREPARE_TARGET)

autofix_prepare_target: autofix_check $(AUTOFIX_PREPARE_TARGET) $(AUTOCOM_PRECONDITION)

define copy_obj_target_to_device
	$(hide) $(foreach jar,$(AUTOFIX_TARGET_LIST), \
				$(eval jarBaseName := $(call getBaseName,$(call getBaseName,$(jar)))) \
				$(foreach package,$(BAIDU_PREBUILT_PACKAGE_$(jarBaseName)),\
					rm -rf $(AUTOFIX_TARGET)/$(jar)/smali/$(package);))
	$(hide) $(foreach jar,$(AUTOFIX_OBJ_TARGET_LIST),if [ -d $(jar) ]; then cp -rf $(jar) $(PRJ_ROOT); fi;)
endef

$(AUTOFIX_PYTHON_JOB): autofix_prepare_target
	$(hide) rm -rf $(AUTOFIX_OUT)
	$(hide) rm -rf $(OUT_DIR)/.reject_bak
	$(hide) cp -rf $(OUT_DIR)/reject $(OUT_DIR)/.reject_bak
	$(hide) $(AUTOFIX_TOOL)
	$(hide) rm -rf $(OUT_DIR)/reject
	$(hide) mv $(OUT_DIR)/.reject_bak $(OUT_DIR)/reject
	$(hide) touch $(AUTOFIX_PYTHON_JOB)

.PHONY: autofix
autofix $(AUTOFIX_JOB): $(AUTOFIX_PYTHON_JOB)
	$(call copy_obj_target_to_device)

$(SMALI_TO_BOSP_PYTHON_JOB): $(AUTOFIX_PREPARE_TARGET)
	$(hide) $(SCHECK) --smalitobosp `cat $(SMALI_FILE)`

.PHONY: smalitobosp
smalitobosp: $(SMALI_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)

.PHONY: methodtobosp
$(METHOD_TO_BOSP_PYTHON_JOB): $(AUTOFIX_PREPARE_TARGET)
	$(hide) $(SCHECK) --methodtobosp $(SMALI_FILE) `if [ -f $(METHOD) ]; then cat $(METHOD); else echo $(METHOD); fi;`
	$(hide) touch $(METHOD_TO_BOSP_PYTHON_JOB)

methodtobosp:
methodtobosp: $(METHOD_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)
