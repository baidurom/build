#!/bin/bash

BAIDU_ZIP_DIR=$1
DENSITY=$2
THEME_FULL_RES=$BAIDU_ZIP_DIR/theme_full_res

function custom_theme()
{
	if [ -d $THEME_FULL_RES ]; then
		for theme in $(ls $THEME_FULL_RES | awk -F- '{print $1}' | sort | uniq); do
			package=$theme
			if [ -d $THEME_FULL_RES/$theme-$DENSITY ]; then
				package=$theme-$DENSITY
			fi
			if [ -d $THEME_FULL_RES/$package ]; then
				rm -rf $BAIDU_ZIP_DIR/system/etc/$theme
				rm -rf $BAIDU_ZIP_DIR/system/etc/$theme.btp
				mv $THEME_FULL_RES/$package $BAIDU_ZIP_DIR/system/etc/$theme

				cd $BAIDU_ZIP_DIR/system/etc/$theme 2>&1 > /dev/null
				zip -q ../$theme.btp description.xml
				cd - 2>&1 > /dev/null
			fi
		done
		rm -rf $THEME_FULL_RES
	fi
}

custom_theme
