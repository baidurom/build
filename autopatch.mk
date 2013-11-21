# autopatch.mk
#
# bringup : Patch necessary modifications. With these modifications, the device will boot into laucher successfully.
# patchall: Patch all the modifications after bringup.
#

### Includes Definition
include $(PORT_BUILD)/locals.mk

### Constants Definition
AUTOPATCH_DIR				:= ${PORT_TOOLS}/autopatch
AUTOPATCH_TOOL				:= ${AUTOPATCH_DIR}/autopatch.py
UPGRADE_TOOL				:= ${AUTOPATCH_DIR}/upgrade.py
PORTING_TOOL				:= ${AUTOPATCH_DIR}/porting_from_device.sh
PREDICATION_TOOL			:= ${AUTOPATCH_DIR}/predication.sh
FRAMEWORK_PARTITION_TOOL	:= ${AUTOPATCH_DIR}/framework_partition.sh

REFERENCE_DIR	:= ${PORT_ROOT}/reference/autopatch

BRING_UP_DIR	:= ${REFERENCE_DIR}/bringup/
BRING_UP_XML	:= ${BRING_UP_DIR}/bringup.xml

PATCH_ALL_DIR	:= ${REFERENCE_DIR}/patchall/
PATCH_ALL_XML	:= ${PATCH_ALL_DIR}/patchall.xml

UPGRADE_DIR		:= ${REFERENCE_DIR}/upgrade/

### Variables Definition
#hide :=

### Target Definition
.PHONY: predication bringup patchall upgrade

# Predication of auto patch
predication:
	@echo ">>> checking predication for auto patch..."
	$(hide) $(PREDICATION_TOOL) $(BAIDU_DIR)
	$(hide) $(FRAMEWORK_PARTITION_TOOL) -combine

# Patch the bringup modifications
bringup: predication
	@echo ">>> bringup..."
	$(hide) $(AUTOPATCH_TOOL) $(BRING_UP_DIR) $(BRING_UP_XML)
	$(hide) $(FRAMEWORK_PARTITION_TOOL) -revert

# Patch all the baidu features after bringup
patchall: predication
	@echo ">>> patchall..."
	$(hide) $(AUTOPATCH_TOOL) $(PATCH_ALL_DIR) $(PATCH_ALL_XML)
	$(hide) $(FRAMEWORK_PARTITION_TOOL) -revert

# Upgrade version
upgrade: predication
	@echo ">>> upgrade ..."
	$(hide) $(UPGRADE_TOOL) $(UPGRADE_DIR) $(ROM_VERSION) $(UPGRADE_VERSION)
	$(hide) $(FRAMEWORK_PARTITION_TOOL) -revert

### Target Definition
.PHONY: porting

# Porting commits from reference device
porting:
	@echo ">>> Porting commits from device ${PORTING_FROM_DEVICE}..."
	$(hide) $(PORTING_TOOL) ${PORTING_FROM_DEVICE} ${PORTING_FROM_BRANCH}
