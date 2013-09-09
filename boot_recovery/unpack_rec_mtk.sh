#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
UNPACKMTKBOOTIMG=$PORT_TOOLS/unpack-mtk-bootimg.pl

echo "$0"
$UNPACKMTKBOOTIMG recovery.img
mv recovery.img-ramdisk  RAMDISK
mv recovery.img-kernel  kernel
rm -rf recovery.img-*
