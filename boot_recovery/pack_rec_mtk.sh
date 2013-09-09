#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
MKBOOTFS=$PORT_TOOLS/mkbootfs
MINIGZIP=$PORT_TOOLS/minigzip
MKMTKBOOTIMG=$PORT_TOOLS/mkmtkbootimg
MKIMAGE=$PORT_TOOLS/mkimage

echo "$0"
$MKBOOTFS ./RAMDISK | $MINIGZIP > ramdisk.img
$MKIMAGE ./ramdisk.img  RECOVERY > ramdisk_rec.img
$MKMTKBOOTIMG --kernel ./kernel --ramdisk ./ramdisk_rec.img  --output recovery.img
