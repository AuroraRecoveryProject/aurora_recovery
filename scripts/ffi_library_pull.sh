#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.."; pwd)

REMOTE_ROOT="laurie@192.168.31.206:/home/laurie/twrp"
REMOTE_FILE="out/target/product/ossi/system/lib64/libtwrp_core_ffi.so"
LOCAL_NATIVE_DIR="$ROOT_DIR/native"

mkdir -p "$LOCAL_NATIVE_DIR"

rsync -av \
  "$REMOTE_ROOT/$REMOTE_FILE" \
  "$LOCAL_NATIVE_DIR/"