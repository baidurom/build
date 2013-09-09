BUILD_BOOT_RECOVERY=$PORT_ROOT/build/boot_recovery

function pack_boot_mtk()
{
	if [ ! -f kernel -o ! -d RAMDISK ];then
		echo ">>> can not find kernel or RAMDISK in current directory"
		return 1
	fi
	$BUILD_BOOT_RECOVERY/pack_boot_mtk.sh

	if [ -f boot.img ];then
		echo ">>> out ==> boot.img"
	else
		echo ">>> pack boot.img failed"
	fi
}

function pack_boot()
{
	if [ ! -f kernel -o ! -d RAMDISK ];then
		echo ">>> can not find kernel or RAMDISK in current directory"
		return 1
	fi
	$BUILD_BOOT_RECOVERY/pack_boot.sh

	if [ -f boot.img ];then
		echo ">>> out ==> boot.img"
	else
		echo ">>> pack boot.img failed"
	fi
}

function pack_boot_sony()
{
	if [ ! -f kernel -o ! -d RAMDISK ];then
		echo ">>> can not find kernel or RAMDISK in current directory"
		return 1
	fi
	$BUILD_BOOT_RECOVERY/pack_boot_sony.sh

	if [ -f boot.img ];then
		echo ">>> out ==> boot.img"
	else
		echo ">>> pack boot.img failed"
	fi
}

function pack_rec_mtk()
{
	if [ ! -f kernel -o ! -d RAMDISK ];then
		echo ">>> can not find kernel or RAMDISK in current directory"
		return 1
	fi
	$BUILD_BOOT_RECOVERY/pack_rec_mtk.sh

	if [ -f recovery.img ];then
		echo ">>> out ==> recovery.img"
	else
		echo ">>> pack recovery.img failed"
	fi
}

function pack_rec()
{
	if [ ! -f kernel -o ! -d RAMDISK ];then
		echo ">>> can not find kernel or RAMDISK in current directory"
		return 1
	fi
	$BUILD_BOOT_RECOVERY/pack_rec.sh

	if [ -f recovery.img ];then
		echo ">>> out ==> recovery.img"
	else
		echo ">>> pack recovery.img failed"
	fi
}

function unpack_boot_mtk()
{
	if [ $# != 1 ];then
		echo ">>> Usage: unpack_boot_mtk boot.img"
		return 1
	fi
	if [ ! -f $1 ];then
		echo ">>> can not find $1"
		return 1
	fi
	tempdir=`mktemp -d BOOT.XXX`
	cp $1 $tempdir/boot.img
	cd $tempdir
	$BUILD_BOOT_RECOVERY/unpack_boot_mtk.sh
	cd - > /dev/null
	if [ -d $tempdir/RAMDISK ];then
		echo ">>> out ==> $tempdir"
	else
		echo ">>> unpack boot.img failed"
	fi
	rm $tempdir/boot.img
}

function unpack_boot_sony()
{
	if [ $# != 1 ];then
		echo ">>> Usage: unpack_boot_sony boot.img"
		return 1
	fi
	if [ ! -f $1 ];then
		echo ">>> can not find $1"
		return 1
	fi
	tempdir=`mktemp -d BOOT.XXX`
	cp $1 $tempdir/boot.img
	cd $tempdir
	$BUILD_BOOT_RECOVERY/unpack_boot_sony.sh
	cd - > /dev/null
	if [ -d $tempdir/RAMDISK ];then
		echo ">>> out ==> $tempdir"
	else
		echo ">>> unpack boot.img failed"
	fi
	rm $tempdir/boot.img
}

function unpack_boot()
{
	if [ $# != 1 ];then
		echo ">>> Usage: unpack_boot boot.img"
		return 1
	fi
	if [ ! -f $1 ];then
		echo ">>> can not find $1"
		return 1
	fi
	tempdir=`mktemp -d BOOT.XXX`
	cp $1 $tempdir/boot.img
	cd $tempdir
	$BUILD_BOOT_RECOVERY/unpack_boot.sh
	cd - > /dev/null
	if [ -d $tempdir/RAMDISK ];then
		echo ">>> out ==> $tempdir"
	else
		echo ">>> unpack boot.img failed"
	fi
	rm $tempdir/boot.img
}

function unpack_rec_mtk()
{
	if [ $# != 1 ];then
		echo ">>> Usage: unpack_rec_mtk recovery.img"
		return 1
	fi
	if [ ! -f $1 ];then
		echo ">>> can not find $1"
		return 1
	fi
	tempdir=`mktemp -d RECOVERY.XXX`
	cp $1 $tempdir/recovery.img
	cd $tempdir
	$BUILD_BOOT_RECOVERY/unpack_rec_mtk.sh
	cd - > /dev/null
	if [ -d $tempdir/RAMDISK ];then
		echo ">>> out ==> $tempdir"
	else
		echo ">>> unpack recovery.img failed"
	fi
	rm $tempdir/recovery.img
}

function unpack_rec()
{
	if [ $# != 1 ];then
		echo ">>> Usage: unpack_rec recovery.img"
		return 1
	fi
	if [ ! -f $1 ];then
		echo ">>> can not find $1"
		return 1
	fi
	tempdir=`mktemp -d RECOVERY.XXX`
	cp $1 $tempdir/recovery.img
	cd $tempdir
	$BUILD_BOOT_RECOVERY/unpack_rec.sh
	cd - > /dev/null
	if [ -d $tempdir/RAMDISK ];then
		echo ">>> out ==> $tempdir"
	else
		echo ">>> unpack recovery.img failed"
	fi
	rm $tempdir/recovery.img
}
