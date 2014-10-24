#!/bin/bash

apkBaseName=$1
tempSmaliDir=$2

if [ "$apkBaseName" = "Phone" ] || [ "$apkBaseName" = "TeleService" ];then
    rm -rf $tempSmaliDir/res/values-de
    rm -rf $tempSmaliDir/res/values-es
    rm -rf $tempSmaliDir/res/values-es-rUS
    rm -rf $tempSmaliDir/res/values-it
    rm -rf $tempSmaliDir/res/values-ru
    rm -rf $tempSmaliDir/res/values-zh-rTW
    rm -rf $tempSmaliDir/res/values-fr-rCA
fi
