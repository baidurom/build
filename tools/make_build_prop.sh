#!/bin/bash

BAIDU_PROP=""
VENDOR_PROP=""
OUT_PROP=""
VERSION_NUM=""
help=""
TEMP_OUT_PROP=""

set -- `getopt "b:r:v:o:h:" "$@"`

while :
do
case "$1" in
    -b) shift; BAIDU_PROP=$1 ;;
    -r) shift; VENDOR_PROP="$1";;
    -v) shift; VERSION_NUM="$1";;
    -o) shift; OUT_PROP="$1";;
    -h) help=1;;
    --) break ;;
esac
shift
done
shift

#Update build.prop version file
function updatevesion()
{
    if [ "x$VERSION_NUM" != "x" ];then
        COUNT=$1
        VERSION=$2
        LINENUM=$(grep -n $VERSION $TEMP_OUT_PROP)
        LINESTART=${LINENUM%%:*}
        RIGHT=${LINENUM##*=}
        VERSIONFULL="$VERSION\=$VERSION_NUM"
        if [ -z "$LINESTART" ];then
            sed -i "$COUNT i $VERSIONFULL" $TEMP_OUT_PROP
            COUNT=`expr $COUNT + 1`
        else
            sed -i "s/$RIGHT/$VERSION_NUM/g" $TEMP_OUT_PROP
            sed -i "/$VERSION/d" $TEMP_OUT_PROP
            sed -i "$LINESTART i $VERSIONFULL" $TEMP_OUT_PROP
        fi
    fi
}

#Update build.prop version file
function updatebuildtime()
{
    COUNT=$1
    BUILDTIME=$(date)
    BUIDUTCTIME=$(date +%s)
    ROBUILDDATE="ro.build.date"
    ROBUILDDATEUTC="ro.build.date.utc"
    LINENUM=$(grep -n $ROBUILDDATE $TEMP_OUT_PROP)
    LINESTART=${LINENUM%%:*}

    ROBUILDDATEFULL="$ROBUILDDATE\=$BUILDTIME"
    ROBUILDDATEUTCFULL="$ROBUILDDATEUTC\=$BUIDUTCTIME"

    if [ -z "$LINESTART" ];then
        sed -i "$COUNT i $ROBUILDDATEFULL" $TEMP_OUT_PROP
        COUNT=`expr $COUNT + 1`
        sed -i "$COUNT i $ROBUILDDATEUTCFULL" $TEMP_OUT_PROP
    else
        sed -i "/$ROBUILDDATE/d" $TEMP_OUT_PROP
        sed -i "$LINESTART i $ROBUILDDATEFULL" $TEMP_OUT_PROP
        LINESTART=`expr $LINESTART + 1`
        sed -i "$LINESTART i $ROBUILDDATEUTCFULL" $TEMP_OUT_PROP
    fi
}

#Update build.prop file
function update_build_prop()
{
    TKEYNAME="test-keys"
    RKEYNAME="release-keys"
    COUNT=1
    while read LINE
    do 
        if [ "$LINE" != "" -a "${LINE:0:1}" != "#" ];then
            LEFT=${LINE%%=*}
            LINENUM=$(grep -n "$LEFT" $TEMP_OUT_PROP)
            LINESTART=${LINENUM%%:*}
            RIGHT=${LINE##*=}

            if [ -z "$LINESTART" ];then
                if [ $COUNT -lt "2" ];then
                   ARROW="#Baidu Yi ROM build properties"
                   sed -i "$COUNT i $ARROW" $TEMP_OUT_PROP
                   COUNT=`expr $COUNT + 1`
                fi
                if [ "$RIGHT" = "delete" ];then
                    continue
                fi
                sed -i "$COUNT i $LINE" $TEMP_OUT_PROP
                COUNT=`expr $COUNT + 1`
            else
                if [ "x$LEFT" != "x" -a "x$RIGHT" != "x" ];then
                    if [ "$RIGHT" != "delete" ];then
                        sed -i "/$LEFT/d" $TEMP_OUT_PROP
                        sed -i "$LINESTART i $LINE" $TEMP_OUT_PROP
                    else
                        sed -i "/$LEFT/d" $TEMP_OUT_PROP
                    fi
                fi
            fi
        fi      
    done < $1

    sed -i "s/$RKEYNAME/$TKEYNAME/g" $TEMP_OUT_PROP

    echo ">>> ROM_VERSION_TYPE: $ROM_VERSION_TYPE"
    if [ -n "$ROM_VERSION_TYPE" ];then
        rom_version_type="ro.version.type=$ROM_VERSION_TYPE"
        sed -i "$ a\\$rom_version_type" $TEMP_OUT_PROP
    fi

    echo ">>> ROM_OFFICIAL_VERSION: $ROM_OFFICIAL_VERSION"
    if [ -n "$ROM_OFFICIAL_VERSION" ];then
        rom_official_version="ro.official.version=$ROM_OFFICIAL_VERSION"
        sed -i "$ a\\$rom_official_version" $TEMP_OUT_PROP
    fi

    DISPLAYID="ro.build.display.id"
    CUSTOMBUILDVERSION="ro.custom.build.version"
    INCREMENTAL="ro.build.version.incremental"
    SWINTERNAL="ro.product.sw.internal.version"
    updatevesion $COUNT $DISPLAYID;
    updatevesion $COUNT $CUSTOMBUILDVERSION;
    updatevesion $COUNT $INCREMENTAL;
    updatevesion $COUNT $SWINTERNAL;
    updatebuildtime $COUNT;
}

if [ ! -f "$BAIDU_PROP" ];then
	echo ">>> WARNING: $BAIDU_PROP doesn't exist!!";
	exit 0;
fi

if [ ! -f $VENDOR_PROP ];then
	echo ">>> ERROR: $VENDOR_PROP doesn't exist!!";
	exit 1;
fi

TEMP_OUT_PROP=`mktemp "/tmp/build.prop.XXXX"`
if [ -f $TEMP_OUT_PROP ];then
	cp $VENDOR_PROP $TEMP_OUT_PROP -rf;
	update_build_prop $BAIDU_PROP;

	if [ ! -d `dirname $OUT_PROP` ];then
		mkdir -p `dirname $OUT_PROP`;
	fi
	mv $TEMP_OUT_PROP $OUT_PROP;
else
	echo ">>> ERROR: can't use mktemp to create temp file in /tmp";
	exit 1;
fi

