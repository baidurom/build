#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
UNPACBOOTIMG=$PORT_TOOLS/unpackbootimg
UNPACKBOOTIMGPL=$PORT_TOOLS/unpack-bootimg.pl

echo "$0"
$UNPACBOOTIMG -i recovery.img -o ./
$UNPACKBOOTIMGPL recovery.img
mv recovery.img-ramdisk  RAMDISK
mv recovery.img-zImage kernel
mv recovery.img-cmdline  cmdline
mv recovery.img-base  base
mv recovery.img-pagesize  pagesize
rm -rf recovery.img-*
