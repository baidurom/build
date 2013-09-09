#!/bin/bash
#**************************************************#
# Make sony's boot.img
# Xperia
#**************************************************#

# Tools
TOOL_MKELF=$(dirname $0)/tools/mkelf.py

# Files
OUTPUT_BOOTIMG='boot.img'
ADDR_TAG='addr'

ls kernel 2>&1 > /dev/null
if [ "$?" != "0" ];then
	echo ">>> ERROR, kernel doesn't exist!"
	exit 1
fi

FILE_KERNEL="kernel"
FILE_KERNEL_ADDR=$(cat "$ADDR_TAG"_"$FILE_KERNEL")

DIR_RAMDISK="RAMDISK"
FILE_RAMDISK="ramdisk.img"
FILE_RAMDISK_ADDR=$(cat "$ADDR_TAG"_"ramdisk.img")

FILE_RPM="RPM.bin"
FILE_RPM_ADDR=$(cat "$ADDR_TAG"_"$FILE_RPM")

OTHER_PARAM=""
for file in `ls *-[0-9]*`
do
	addrValue=$(cat "$ADDR_TAG"_"$file")
	OTHER_PARAM="$OTHER_PARAM $file\@$addrValue"
done

# Generate ramdisk file
cd $DIR_RAMDISK && find . | cpio -o -H newc | gzip > ../$FILE_RAMDISK && cd ..

# Make kernel-updated.elf
echo "python $TOOL_MKELF -o $OUTPUT_BOOTIMG \
       $FILE_KERNEL@$FILE_KERNEL_ADDR \
       $FILE_RAMDISK@$FILE_RAMDISK_ADDR,ramdisk \
       $FILE_RPM@$FILE_RPM_ADDR,rpm \
       $OTHER_PARAM "

python $TOOL_MKELF -o $OUTPUT_BOOTIMG \
       $FILE_KERNEL@$FILE_KERNEL_ADDR \
       $FILE_RAMDISK@$FILE_RAMDISK_ADDR,ramdisk \
       $FILE_RPM@$FILE_RPM_ADDR,rpm \
       $OTHER_PARAM

# Clear temporary files
rm $FILE_RAMDISK
