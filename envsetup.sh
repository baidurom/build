#!/bin/bash
#**************************************************#
#This shell used to export PORT_ROOT 			      	
#**************************************************#
TOPFILE=build/envsetup.sh
PROJECT_MAX_DEPTH=3

if [ -f $TOPFILE ] ; then
   PORT_ROOT=$PWD
else
   while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
       cd .. > /dev/null
   done
   if [ -f $PWD/$TOPFILE ]; then
       PORT_ROOT=$PWD
       #echo "PORT: $PORT_ROOT"
   else
       echo "Failed! run me under you porting workspace"
       return
   fi
fi

if [ -n "$PORT_ROOT" ]; then
    MATCH=$(echo $PATH | grep $PORT_ROOT)
    if [ "$MATCH" = "" ];then
		PATH=$PORT_ROOT/tools:$PATH
		LD_LIBRARY_PATH=$PORT_ROOT/build/lib/:$LD_LIBRARY_PATH
	export PATH LD_LIBRARY_PATH
    fi
    PORT_BUILD="$PORT_ROOT/build"
    #echo "set port_build, PORT_BUILD:$PORT_BUILD"
    export PORT_ROOT PORT_BUILD
fi


# Command "coron" complete
function __cmd_coron()
{
    local cur="${COMP_WORDS[COMP_CWORD]}"
    case $COMP_CWORD in
    0)
      ;;
    1)
      local options="fire config patchall autofix fullota upgrade clean cleanall help"
      COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
      ;;
    2)
      ;;
    esac
}

complete -F __cmd_coron coron

function ifdir()
{
    $PORT_BUILD/tools/ifdir.sh $1
}

function croot()
{
    cd $PORT_ROOT
}

# setup the function to cd to the project under the smali dir
function setupCdFunction()
{
    local projectName
    local projectPath
    local temp_sh=`mktemp -t temp.sh.XXXXXX`
    local temp_info=`mktemp -t temp.info.XXXXX`

    echo "#!/bin/bash \n" > $temp_sh
    echo ">>> All valid projects: "
    printf "name path fast_cd_command\n" >> $temp_info
    for makefile in `find $PORT_ROOT/devices -maxdepth $PROJECT_MAX_DEPTH -iname "makefile"`
    do
        projectPath=`dirname $makefile`
        projectName=`basename $projectPath`
        echo -e "$projectName $projectPath c$projectName" >> $temp_info
	echo "
function c$projectName()
{
    cd \"$projectPath\"
}"  >> $temp_sh
    done
    chmod a+x $temp_sh
    source "$temp_sh"
    cat $temp_info | column -t
    rm -rf "$temp_sh"
    rm -rf "$temp_info"
}


setupCdFunction

if [ -f $PORT_BUILD/custom/Makefile ]; then
    cp $PORT_BUILD/custom/Makefile $PORT_ROOT
fi

SIMGTOIMG=$PORT_BUILD/tools/bin/simg2img
function unpack_systemimg()
{
    local systemimg=$1
    local outdir=$2

    echo ">>> begin unpack $systemimg"
    if [ "x$outdir" = "x" ]; then
        outdir=$PWD
    fi

    if [ -f $systemimg ]; then
        mkdir -p $outdir
        if [ -x $SIMGTOIMG ]; then
            tmpImg=`mktemp -t system.XXXX.img`
            tmpMnt=`mktemp -dt system.XXXX.mnt`

            $SIMGTOIMG $systemimg $tmpImg
            sudo mount -t ext4 -o loop $tmpImg $tmpMnt
            
            sudo cp -rf $tmpMnt/* $outdir
            sudo umount $tmpMnt

            rm -rf $tmpImg
            rm -rf $tmpMnt
            
            echo ">>> success unpack $systemimg to $outdir"
            return 0
        else
            echo ">>> $SIMGTOIMG can not be execute!"
        fi
    else
        echo ">>> $systemimg doesn't exist! "
    fi

    echo ">>> failed to unpack $systemimg"
    return 1
}

function imgtoota()
{
    local systemimg=$1
    local outzip=$2

    echo ">>> begin generate ota zip from $systemimg"
    if [ "x$outzip" = "x" ]; then
        outzip=$PWD
    fi

    if [ -d "$outzip" ]; then
        outzip=$outzip/ota.zip
    fi

    outdir=`mktemp -dt ota.XXX`
    unpack_systemimg $systemimg $outdir

    if [ $? = "0" ]; then
        echo ">>> begin zip $outdir to $outzip"
        cd $outdir
        sudo zip ota.zip * -q -r -y
        cd -
        mv $outdir/ota.zip $outzip

        echo ">>> genera ota zip: $outzip"
        return 0
    else
        echo ">>> unpack $systemimg failed! "
        rm -rf $outdir
        return 1
    fi
}


function otadiff()
{
    OTA_FROM_TARGET=$PORT_BUILD/tools/releasetools/ota_from_target_files
    TEST_KEY=$PORT_BUILD/security/testkey
    out_zip=$3

    if [ $# -lt 2 ]; then
        echo "Usage: otadiff pre-target-files.zip target-files.zip [ota-diff.zip]"
        echo "       pre-target-files.zip: the previous target files"
        echo "       target-files.zip: the current target files"
        echo "       [ota-diff.zip]: the ota update zip"
        return
    elif [ $# -eq 2 ]; then
        out_zip=ota-diff.zip
    fi

    $OTA_FROM_TARGET -k $TEST_KEY -i $1 $2 $out_zip
    echo ">>> out: $out_zip"
}


SIGN_JAR="$PORT_BUILD/tools/signapk.jar"

KEY_DIR="$PORT_BUILD/security"
TESTKEY_PEM="$KEY_DIR/testkey.x509.pem"
TESTKEY_PK="$KEY_DIR/testkey.pk8"

function sign()
{
    apkName=$1

    if [ $# = "0" ];then
        echo ">>> usage: sign XXX.apk"
        echo "           use testkey to sign XXX.apk"
        return
    fi

    if [ ! -f $apkName ];then
        echo ">>> $apkName doesn't exist!"
        return
    fi

    echo ">>> use \"testkey\" to sign $apkName"
    rm -rf $apkName.signed $apkName.signed.aligned

    zip -d $apkName "META-INF/*" 2>&1 > /dev/null
    java -jar $SIGN_JAR $TESTKEY_PEM $TESTKEY_PK $apkName $apkName.signed
    echo ">>> signed out: $apkName.signed"

    zipalign 4 $apkName.signed $apkName.signed.aligned
    echo ">>> zipalign out: $apkName.signed.aligned"
}

function sign_key()
{
    keyType=$1
    apkName=$2

    if [ $# = "0" ];then
        echo ">>> usage: sign_key platform/media/share/testkey/releasekey XXX.apk"
        echo "           used to sign XXX.apk"
        return
    fi

    if [ ! -f "$apkName" ];then
        echo ">>> $apkName doesn't exist!"
        return
    fi

    if [ ! -f "$KEY_DIR/$keyType.x509.pem" ] || [ ! -f "$KEY_DIR/$keyType.pk8" ];then
        echo ">>> \"$keyType\" key doesn't exist!"
        return
    fi

    echo ">>> use \"$keyType\" to sign $apkName"
    rm -rf $apkName.signed $apkName.signed.aligned

    zip -d $apkName "META-INF/*" 2>&1 > /dev/null
    java -jar $SIGN_JAR "$KEY_DIR/$keyType.x509.pem" "$KEY_DIR/$keyType.pk8" $apkName $apkName.signed
    echo ">>> signed out: $apkName.signed"

    zipalign 4 $apkName.signed $apkName.signed.aligned
    echo ">>> zipalign out: $apkName.signed.aligned"
}
