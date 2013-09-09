#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
UNPACKMTKBOOTIMG=$PORT_TOOLS/unpack-mtk-bootimg.pl

echo "$0"
$UNPACKMTKBOOTIMG boot.img
mv boot.img-ramdisk  RAMDISK
mv boot.img-kernel  kernel
rm -rf boot.img-*
