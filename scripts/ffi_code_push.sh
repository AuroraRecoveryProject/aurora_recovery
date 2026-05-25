#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.."; pwd)

LOCAL_TWRP_DIR="/Volumes/Case-sensitive APFS/TWRP_Compile/twrp_a16_compile"

LOCAL_TWRP_FFI_DIR="$LOCAL_TWRP_DIR/bootable/recovery/twrp_ffi/"
LOCAL_RECOVERY_ANDROID_MK="$LOCAL_TWRP_DIR/bootable/recovery/Android.mk"

REMOTE_BASE="laurie@192.168.31.206:/home/laurie/twrp/bootable/recovery"

rsync -av --delete \
  "$LOCAL_TWRP_FFI_DIR" \
  "$REMOTE_BASE/twrp_ffi/"

rsync -av \
  "$LOCAL_RECOVERY_ANDROID_MK" \
  "$REMOTE_BASE/"