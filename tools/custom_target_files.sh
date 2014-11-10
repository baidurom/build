#!/bin/bash

TARGET_FILES_DIR=$1
SYSTEM_DIR=$TARGET_FILES_DIR/SYSTEM

function save_fonts_files_to_defaultTheme_dir()
{
    echo ">>> save fonts files to defaultTheme dir"
    mkdir -p $SYSTEM_DIR/etc/defaultTheme/fonts/hdpi/
    cp $SYSTEM_DIR/fonts/Roboto-Regular.ttf $SYSTEM_DIR/etc/defaultTheme/fonts/hdpi/Roboto-Regular.ttf
    cp $SYSTEM_DIR/fonts/DroidSansFallback.ttf $SYSTEM_DIR/etc/defaultTheme/fonts/hdpi/DroidSansFallback.ttf
}

save_fonts_files_to_defaultTheme_dir
