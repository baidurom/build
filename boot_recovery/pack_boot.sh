#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
MKBOOTFS=$PORT_TOOLS/mkbootfs
MINIGZIP=$PORT_TOOLS/minigzip
MKBOOTIMG=$PORT_TOOLS/mkbootimg

echo "$0"
$MKBOOTFS ./RAMDISK | $MINIGZIP > ramdisk.img
BOOTBASE=$(cat ./base)
BOOTCMDLINE=$(cat ./cmdline)
BOOTPAGESIZE=$(cat ./pagesize)
$MKBOOTIMG --kernel ./kernel --cmdline "$BOOTCMDLINE" --pagesize "$BOOTPAGESIZE"  --base "$BOOTBASE" --ramdisk ./ramdisk.img --output boot.img
