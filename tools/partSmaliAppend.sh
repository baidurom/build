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
	#echo ">>> file: $file";
	filepath=`dirname $file`;
	filepath=${filepath##*/smali/};
	filename=`basename $file .part`;
	dstfile="$DST_SMALI_DIR/$filepath/$filename";
	cat $file >> $dstfile;
	echo -e ">>> append $file\n        -> $dstfile";
done;
