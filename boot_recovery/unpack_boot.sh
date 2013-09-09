#!/bin/bash

PORT_TOOLS=$PORT_ROOT/tools
UNPACBOOTIMG=$PORT_TOOLS/unpackbootimg
UNPACKBOOTIMGPL=$PORT_TOOLS/unpack-bootimg.pl

echo "$0"
$UNPACBOOTIMG -i boot.img -o ./
$UNPACKBOOTIMGPL boot.img
mv boot.img-ramdisk  RAMDISK
mv boot.img-zImage kernel
mv boot.img-cmdline  cmdline
mv boot.img-base  base
mv boot.img-pagesize  pagesize
rm -rf boot.img-*
