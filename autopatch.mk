# autopatch.mk
#
# bringup : Patch necessary modifications for bringup the ROM.
# patchall: Patch all the modifications.
# upgrade:  Patch upgrade patches one by one.
#

### Includes Definition
include $(PORT_BUILD)/locals.mk

### Constants Definition
AUTOPATCH_DIR   := ${PORT_TOOLS}/autopatch
PRECONDITION    := ${AUTOPATCH_DIR}/check_precondition.sh

AUTOPATCH_TOOL  := ${AUTOPATCH_DIR}/autopatch.py
UPGRADE_TOOL    := ${AUTOPATCH_DIR}/upgrade.py
PORTING_TOOL    := ${AUTOPATCH_DIR}/porting_from_device.sh

PATCH_ALL_XML   := ${PRJ_ROOT}/autopatch/changelist/patchall.xml
PATCH_ONE_XML   := ${PRJ_ROOT}/autopatch/changelist/patchone.xml
UPGRADE_DIR     := ${PRJ_ROOT}/autopatch/upgrade/

AOSP_DIR           := ${PRJ_ROOT}/autopatch/aosp

AUTOCOM_MERGED_NEED_COM_DIR := $(patsub %,$(AUTOCOM_MERGED_DIR)/%,$(NEED_COMPELETE_MODULE))

### Variables Definition
#hide :=

### Target Definition


### autocom definition
.PHONY: autocom bringup_autopatch

# Before running this target, all framework-res should be installed.
# Otherwise, some baksmali error might come out.
$(eval $(call decode_baidu,baidu/system/app/Phone.apk,/tmp/Phone))

#ifeq ($(strip $(wildcard $(BAIDU_SYSTEM))),)
#$(AUTOCOM_PREPARE_BAIDU): | preparesource
#endif

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
	$(hide) $(SCHECK) --autocomplete \
				$(AUTOCOM_VENDOR) \
				$(AOSP_DIR) \
				$(AUTOCOM_BAIDU) \
				$(AUTOCOM_MERGED) \
				$(PRJ_ROOT) \
				$(NEED_COMPELETE_MODULE)
	$(hide) touch $(AUTOCOM_PRECONDITION)
	@echo "<<< checking precondition for autocomplete missed methods Done."


bringup:
	@echo ""
	@echo "  bringup is obsoleted, use patchall directly!!"
	@echo ""

### bringup patchall definition
.PHONY: precondition patchall

$(AUTOCOM_PRECONDITION): | precondition

# check precondition of auto patch
precondition: $(PREPARE_SOURCE)
	@echo ">>> checking precondition for auto patch ..."
	$(hide) $(PRECONDITION) $(PRJ_ROOT)
	@echo "<<< checking precondition Done."

# Patch the bringup modifications
modify_boot := $(filter boot,$(strip $(vendor_modify_images)))
ifeq ($(modify_boot),)
REVISE_OPTION := False
else
REVISE_OPTION := True
endif

patchall $(PATCHALL_JOB): $(AUTOCOM_PRECONDITION)
	@echo ""
	@echo ">>> auto patch all ..."
	$(hide) $(AUTOPATCH_TOOL) $(PATCH_ALL_XML) $(REVISE_OPTION)
	$(hide) mkdir -p `dirname $(PATCHALL_JOB)`
	$(hide) touch $(PATCHALL_JOB)


patchone: $(AUTOCOM_PRECONDITION)
	@echo ""
	@echo ">>> auto patch one ..."
	$(hide) $(AUTOPATCH_TOOL) $(PATCH_ONE_XML)

### upgrade definition
.PHONY: upgrade_precondition upgrade

UPGRADE_USAGE="\n  Usage: make upgrade FROM=XX [TO=XX]                                  " \
	      "\n                                                                       " \
              "\n    - FROM current version of ROM.                                     " \
	      "\n                                                                       " \
              "\n    - TO   ROM version that upgrade to. Default to the lastest version." \
	      "\n                                                                       " \
              "\n    e.g. make upgrade FROM=44                                          " \
	      "\n         Upgrade your ROM from ROM44 to the latest                     " \
              "\n                                                                       " \
              "\n    e.g. make upgrade FROM=44 TO=45                                    " \
	      "\n         Upgrade your ROM from ROM44 to ROM45                          " \
              "\n                                                                       " \
              "\n   Skill: Define FROM or TO in your Makefile, next time you could      " \
              "\n          use [make upgrade] directly, it is more effective.           " \
              "\n                                                                       " \

# check precondition of upgrade
upgrade_precondition:
	$(hide) if [ -z $(FROM) ]; then echo $(UPGRADE_USAGE); exit 1; fi
	@echo ">>> sync patches to latest ..."
	repo sync -c --no-clone-bundle --no-tags -j4 ${PORT_TOOLS}
	repo sync -c --no-clone-bundle --no-tags -j4 ${PORT_ROOT}/reference
	@echo ">>> checking precondition for upgrade ..."
	$(hide) $(PRECONDITION) --upgrade $(PRJ_ROOT)
	@echo "<<< checking precondition for upgrade Done."

upgrade: upgrade_precondition
	@echo ""
	@echo ">>> upgrade ..."
	$(hide) $(UPGRADE_TOOL) $(FROM) $(TO)


### porting definition
.PHONY: porting

PORTING_USAGE="\n  Usage: make porting MASTER=XX [NUM=XX]                               " \
              "\n                                                                       " \
              "\n  - MASTER the source device you porting from, it is like a master     " \
              "\n                                                                       " \
              "\n  - NUM    the number of latest commits you would like to pick         " \
              "\n           if not present, an interactive UI will show for you         " \
              "\n                                                                       " \
              "\n    e.g. porting_from_device.sh MASTER=demo                            " \
              "\n         Porting commits from demo interactively                       " \
              "\n                                                                       " \
              "\n    e.g. porting_from_device.sh MASTER=demo NUM=3                      " \
              "\n         Porting the latest 3 commits from maguro quietly.             " \
              "\n                                                                       " \
              "\n   Skill: Define MASTER or NUM in your Makefile, next time you could   " \
              "\n          use [make porting] directly, it is more effective.           " \
              "\n                                                                       " \

# Porting commits from reference device
porting:
	@echo ">>> Porting commits from device ${MASTER} ..."
	$(hide) if [ -z $(MASTER) ]; then echo $(PORTING_USAGE); exit 1; fi
	$(hide) $(PORTING_TOOL) ${MASTER} ${NUM}


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
autofix_prepare_target $(AUTOFIX_PREPARE_TARGET): autofix_check $(IF_VENDOR_RES)
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

$(SMALI_TO_BOSP_PYTHON_JOB): autofix_prepare_target
	$(hide) $(SCHECK) --smalitobosp `cat $(SMALI_FILE)`

.PHONY: smalitobosp
smalitobosp: $(SMALI_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)

.PHONY: methodtobosp
$(METHOD_TO_BOSP_PYTHON_JOB): autofix_prepare_target
	$(hide) $(SCHECK) --methodtobosp $(SMALI_FILE) `if [ -f $(METHOD) ]; then cat $(METHOD); else echo $(METHOD); fi;`
	$(hide) touch $(METHOD_TO_BOSP_PYTHON_JOB)

methodtobosp:
methodtobosp: $(METHOD_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)

