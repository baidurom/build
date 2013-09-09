#!/bin/bash

TOOLS_DIR=$PORT_ROOT/build/boot_recovery/tools

UNPACK_SONY_BOOT=$TOOLS_DIR/unpack_boot_sony.py

$UNPACK_SONY_BOOT boot.img
