#!/usr/bin/env sh
# push twrp_ffi related code to the remote server for development and testing
# because I compile TWRP on my ubuntu on LAN
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.."; pwd)

LOCAL_TWRP_FFI_DIR="$ROOT_DIR/native/twrp_ffi/"

REMOTE_BASE="laurie@192.168.31.206:/home/laurie/twrp/bootable/recovery"

# ignore Android_TWRP.mk
rsync -av --exclude='Android_TWRP.mk' \
  "$LOCAL_TWRP_FFI_DIR" \
  "$REMOTE_BASE/twrp_ffi/"

rsync -av \
  "$LOCAL_TWRP_FFI_DIR/Android_TWRP.mk" \
  "$REMOTE_BASE/Android.mk"