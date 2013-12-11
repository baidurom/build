#!/bin/bash

PART_SMALI_DIR=$1
DST_SMALI_DIR=$2

echo ">>> in partSmaliAppend.sh";

if [ ! -d $PART_SMALI_DIR ];then
	exit 0;
fi;

if [ ! -d $DST_SMALI_DIR ];then
	echo ">>> ERROR: $DST_SMALI_DIR doesn't exsit!!";
	exit 1;
fi;


for file in `find $PART_SMALI_DIR -name "*.part"`
do
	FILEPATH=${file##*/smali/};
	PARTFILE=$PART_SMALI_DIR/$FILEPATH;
	DSTFILE=$DST_SMALI_DIR/${FILEPATH%.part};

	FUNCS=$(cat $PARTFILE | grep "^.method")
	echo "$FUNCS" | while read func
	do
		functmp=$(echo "$func" | sed 's/\//\\\//g;s/\[/\\\[/g')
		TMP=$(sed -n "/$functmp/p" $DSTFILE)
		if [ x"$TMP" != x"" ];then
			echo ">>> remove $func from $DSTFILE"
			sed -i "/^$functmp/,/^.end method/d" $DSTFILE
		fi
	done

	cat $PARTFILE >> $DSTFILE
	echo ">>> append $PARTFILE"
	echo "        to $DSTFILE"
done;
