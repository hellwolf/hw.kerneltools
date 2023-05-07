#!/bin/bash

function oops() {
  echo "$@" >&2
  exit 1
}

export HWKTOOLS_VARS=
function checkvar() {
    VARNAME=$1
    OPTIONAL=$2
    if [ -z "$OPTIONAL" ];then
        [ -z "${!VARNAME}" ] && oops $VARNAME not specified
    fi
    if [ ! -z "${!VARNAME}" ];then
        export ${VARNAME}
        HWKTOOLS_VARS+="${VARNAME}:"
    fi
}

export TOOLNAME=$(basename "$0")
checkvar TOOLNAME
if [ -z "$TOP_TOOLNAME" ] && [ "${TOOLNAME}" != "shell" ];then
    export TOP_TOOLNAME="$TOOLNAME"
fi
export TOOLSDIR=$(readlink -f "$(dirname $0)")
checkvar TOOLSDIR
export RCFILE=$(readlink -f "${RCFILE:-hwktools.rc}")
checkvar RCFILE
export PROJECTDIR=$(dirname "$(readlink -f "${RCFILE}")")
checkvar PROJECTDIR

cd $PROJECTDIR
. $RCFILE || oops read rc file failed

checkvar DEVNAME

checkvar ARCH
checkvar KDIR
KDIR=$(readlink -f "$KDIR")
checkvar KMODSDIR
KMODSDIR=$(readlink -f "$KMODSDIR")
checkvar OUTPUTDIR
OUTPUTDIR=$(readlink -f "$OUTPUTDIR")
checkvar CROSS_COMPILE 1

checkvar DEVEL_BRANCH
checkvar REMOTE_BRANCHES
checkvar MERGE_REMOTE_BRANCHES
checkvar MERGE_BRANCH
checkvar UPDATE_POSTCMD 1

checkvar ROOTFS
ROOTFS=$(readlink -f "$ROOTFS")
checkvar ROOTFS_YUM_ARGS 1
checkvar ROOTFS_CHROOT_USER 1

checkvar GDB_HOST
checkvar GDB_TCPPORT
checkvar GDB_SOURCES 1
checkvar GDB_GDBBIN 1

checkvar QEMU_ARGS
checkvar KERNEL_CMDLINE

export INSTALL_PATH=$ROOTFS/boot
checkvar INSTALL_PATH
export INSTALL_MOD_PATH=$ROOTFS
checkvar INSTALL_MOD_PATH
export KVERSION=`cat $OUTPUTDIR/.config | sed -n 's/# Linux kernel version: //p'`
checkvar KVERSION
export KLOCALVERSION=`cat $OUTPUTDIR/.config | sed -n 's/CONFIG_LOCALVERSION="\(.*\)"/\1/p'`
checkvar KLOCALVERSION
export KFULLVER=${KVERSION}${KLOCALVERSION}
checkvar KFULLVER
mkdir -p "$OUTPUTDIR"
export VMLINUX=$OUTPUTDIR/vmlinux
checkvar VMLINUX
export VMLINUZ="$ROOTFS"/boot/vmlinuz-$KFULLVER
checkvar VMLINUZ

# check git repository
(
    cd "${KDIR}"
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse ${DEVEL_BRANCH})" ];then
        git checkout ${DEVEL_BRANCH}
    fi
)
