#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"

MAGISKBOOT_DEFAULT="$ROOT_DIR/magiskboot"
WORK_ROOT_DEFAULT="$ROOT_DIR/.work/repack-recovery"
DEVICE_RUNTIME_DIR_DEFAULT="/tmp/flutter"
RAMDISK_RUNTIME_DIR_DEFAULT="/sbin/aurora"

INPUT_IMAGE=""
OUTPUT_IMAGE=""
MAGISKBOOT="$MAGISKBOOT_DEFAULT"
RUNTIME_FOLDER=""
WORK_ROOT="$WORK_ROOT_DEFAULT"
DEVICE_RUNTIME_DIR="$DEVICE_RUNTIME_DIR_DEFAULT"
RAMDISK_RUNTIME_DIR="$RAMDISK_RUNTIME_DIR_DEFAULT"
RUNNER_ARGS="--fullscreen"

usage() {
  cat <<EOF
用法:
  $(basename "$0") \
    --input 官方recovery.img \
    --output aurora-recovery.img \
    --runtime-folder 本地运行时目录

可选参数:
  --magiskboot PATH     指定 magiskboot，默认: $MAGISKBOOT_DEFAULT
  --runtime-folder DIR  指定完整运行时目录，目录结构应等同设备上的 /tmp/flutter
  --work-root DIR       指定工作目录根，默认: $WORK_ROOT_DEFAULT
  --device-runtime-dir  指定设备侧运行时目录，默认: $DEVICE_RUNTIME_DIR_DEFAULT
  --ramdisk-runtime-dir 指定 ramdisk 内实际注入目录，默认: $RAMDISK_RUNTIME_DIR_DEFAULT
  --runner-args STR     追加给 flutter-runner 的参数，默认: --fullscreen
  --help                显示帮助

脚本行为:
  1. 解包官方 recovery 镜像
  2. 提取 ramdisk
  3. 将本地运行时目录整体注入到 ramdisk
  4. 自动定位 recovery 服务对应的二进制
  5. 将原 recovery 备份为 *.orig，原路径替换成 launcher 脚本
  6. 重新打包输出新镜像

运行时目录要求至少包含:
  flutter-runner
  libflutter_engine.so
  bundle/

也就是 fort 最终在设备 /tmp 下运行时使用的那个完整目录。
EOF
}

log() {
  printf '[repack] %s\n' "$*"
}

fail() {
  printf '[repack] ERROR: %s\n' "$*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "文件不存在: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "目录不存在: $path"
}

ensure_parent_dir() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
}

ramdisk_path_to_host() {
  local ramdisk_root="$1"
  local ramdisk_path="$2"
  local relative="${ramdisk_path#/}"
  printf '%s/%s\n' "$ramdisk_root" "$relative"
}

copy_file_into_ramdisk() {
  local src="$1"
  local ramdisk_root="$2"
  local dst_in_ramdisk="$3"
  local dst_host
  dst_host="$(ramdisk_path_to_host "$ramdisk_root" "$dst_in_ramdisk")"
  ensure_parent_dir "$dst_host"
  cp -f "$src" "$dst_host"
}

copy_dir_contents() {
  local src_dir="$1"
  local dst_dir="$2"
  mkdir -p "$dst_dir"
  cp -R "$src_dir/." "$dst_dir/"
}

assert_runtime_folder() {
  local runtime_folder="$1"
  require_dir "$runtime_folder"
  require_file "$runtime_folder/flutter-runner"
  require_file "$runtime_folder/libflutter_engine.so"
  require_dir "$runtime_folder/bundle"
}

detect_shell_path() {
  local ramdisk_root="$1"
  if [[ -x "$ramdisk_root/sbin/sh" ]]; then
    printf '/sbin/sh\n'
    return
  fi
  if [[ -x "$ramdisk_root/system/bin/sh" ]]; then
    printf '/system/bin/sh\n'
    return
  fi
  printf '/bin/sh\n'
}

find_recovery_binary_from_rc() {
  local ramdisk_root="$1"
  local rc_file
  while IFS= read -r rc_file; do
    while IFS= read -r line; do
      case "$line" in
        service\ recovery\ *|service\ twrp\ *|service\ recovery_* )
          set -- $line
          if [[ $# -ge 3 ]]; then
            printf '%s\n' "$3"
            return 0
          fi
          ;;
      esac
    done < "$rc_file"
  done < <(find "$ramdisk_root" -type f -name '*.rc' | sort)
  return 1
}

find_existing_recovery_binary() {
  local ramdisk_root="$1"
  local candidate
  local host_path

  if candidate="$(find_recovery_binary_from_rc "$ramdisk_root")"; then
    host_path="$(ramdisk_path_to_host "$ramdisk_root" "$candidate")"
    if [[ -e "$host_path" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  for candidate in /sbin/recovery /system/bin/recovery /system/bin/twrp; do
    host_path="$(ramdisk_path_to_host "$ramdisk_root" "$candidate")"
    if [[ -e "$host_path" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

install_runtime_folder() {
  local runtime_folder="$1"
  local ramdisk_root="$2"
  local runtime_dir_host

  runtime_dir_host="$(ramdisk_path_to_host "$ramdisk_root" "$RAMDISK_RUNTIME_DIR")"
  rm -rf "$runtime_dir_host"
  mkdir -p "$runtime_dir_host"
  copy_dir_contents "$runtime_folder" "$runtime_dir_host"
  chmod 0755 "$runtime_dir_host/flutter-runner"
}

write_launcher() {
  local ramdisk_root="$1"
  local recovery_bin_in_ramdisk="$2"
  local shell_path="$3"
  local recovery_host
  local recovery_base
  local backup_in_ramdisk
  local backup_host
  local runtime_dir_host
  local launcher_tmp

  recovery_host="$(ramdisk_path_to_host "$ramdisk_root" "$recovery_bin_in_ramdisk")"
  [[ -e "$recovery_host" ]] || fail "未找到 recovery 二进制: $recovery_bin_in_ramdisk"

  recovery_base="$(basename "$recovery_bin_in_ramdisk")"
  backup_in_ramdisk="$(dirname "$recovery_bin_in_ramdisk")/${recovery_base}.orig"
  backup_host="$(ramdisk_path_to_host "$ramdisk_root" "$backup_in_ramdisk")"
  runtime_dir_host="$(ramdisk_path_to_host "$ramdisk_root" "$RAMDISK_RUNTIME_DIR")"
  mkdir -p "$runtime_dir_host"

  if [[ ! -e "$backup_host" ]]; then
    mv "$recovery_host" "$backup_host"
  else
    rm -f "$recovery_host"
  fi

  launcher_tmp="$runtime_dir_host/${recovery_base}.launcher"
  cat > "$launcher_tmp" <<EOF
#!$shell_path
echo "[aurora] launcher start: \$0 \$*"
mkdir -p "$(dirname "$DEVICE_RUNTIME_DIR")"
rm -rf "$DEVICE_RUNTIME_DIR"
ln -s "$RAMDISK_RUNTIME_DIR" "$DEVICE_RUNTIME_DIR"

export LD_LIBRARY_PATH="$DEVICE_RUNTIME_DIR:\$LD_LIBRARY_PATH"
export AURORA_BUNDLE_DIR="$DEVICE_RUNTIME_DIR/bundle"
export AURORA_RUNTIME_DIR="$DEVICE_RUNTIME_DIR"

cd "$DEVICE_RUNTIME_DIR"

./flutter-runner \
  --bundle="$DEVICE_RUNTIME_DIR/bundle" \
  $RUNNER_ARGS
status=\$?

echo "[aurora] flutter-runner exit: \$status"
echo "[aurora] fallback to original recovery: $backup_in_ramdisk"
exec "$backup_in_ramdisk" "\$@"
EOF
  chmod 0755 "$launcher_tmp"
  mv "$launcher_tmp" "$recovery_host"
}

repack_ramdisk() {
  local ramdisk_root="$1"
  local ramdisk_cpio="$2"
  rm -f "$ramdisk_cpio"
  (
    cd "$ramdisk_root"
    find . | LC_ALL=C sort | cpio -o -H newc > "$ramdisk_cpio"
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      INPUT_IMAGE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_IMAGE="$2"
      shift 2
      ;;
    --magiskboot)
      MAGISKBOOT="$2"
      shift 2
      ;;
    --runtime-folder)
      RUNTIME_FOLDER="$2"
      shift 2
      ;;
    --work-root)
      WORK_ROOT="$2"
      shift 2
      ;;
    --device-runtime-dir)
      DEVICE_RUNTIME_DIR="$2"
      shift 2
      ;;
    --ramdisk-runtime-dir)
      RAMDISK_RUNTIME_DIR="$2"
      shift 2
      ;;
    --runner-args)
      RUNNER_ARGS="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "未知参数: $1"
      ;;
  esac
done

[[ -n "$INPUT_IMAGE" ]] || fail "缺少 --input"
[[ -n "$OUTPUT_IMAGE" ]] || fail "缺少 --output"
[[ -n "$RUNTIME_FOLDER" ]] || fail "缺少 --runtime-folder"

require_file "$MAGISKBOOT"
require_file "$INPUT_IMAGE"
assert_runtime_folder "$RUNTIME_FOLDER"

mkdir -p "$WORK_ROOT"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
WORK_DIR="$WORK_ROOT/$STAMP"
UNPACK_DIR="$WORK_DIR/unpack"
RAMDISK_DIR="$WORK_DIR/ramdisk"
mkdir -p "$UNPACK_DIR" "$RAMDISK_DIR"

cleanup() {
  if [[ -d "$WORK_DIR" ]]; then
    log "保留工作目录: $WORK_DIR"
  fi
}
trap cleanup EXIT

log "输入镜像: $INPUT_IMAGE"
log "输出镜像: $OUTPUT_IMAGE"
log "本地运行时目录: $RUNTIME_FOLDER"
log "设备侧运行时目录: $DEVICE_RUNTIME_DIR"
log "ramdisk 注入目录: $RAMDISK_RUNTIME_DIR"
log "工作目录: $WORK_DIR"

cp -f "$INPUT_IMAGE" "$UNPACK_DIR/$(basename "$INPUT_IMAGE")"
INPUT_COPY="$UNPACK_DIR/$(basename "$INPUT_IMAGE")"

log "开始解包 recovery 镜像"
(
  cd "$UNPACK_DIR"
  "$MAGISKBOOT" unpack "$INPUT_COPY"
)

RAMDISK_CPIO="$UNPACK_DIR/ramdisk.cpio"
[[ -f "$RAMDISK_CPIO" ]] || fail "magiskboot 解包后未找到 ramdisk.cpio"

log "提取 ramdisk"
(
  cd "$RAMDISK_DIR"
  cpio -idu -F "$RAMDISK_CPIO"
)

RECOVERY_BIN_IN_RAMDISK="$(find_existing_recovery_binary "$RAMDISK_DIR")" || \
  fail "未能在 ramdisk 中定位 recovery 二进制"
SHELL_PATH="$(detect_shell_path "$RAMDISK_DIR")"

log "定位 recovery 二进制: $RECOVERY_BIN_IN_RAMDISK"
log "使用 shell: $SHELL_PATH"

log "注入完整运行时目录"
install_runtime_folder "$RUNTIME_FOLDER" "$RAMDISK_DIR"

log "替换 recovery 启动入口"
write_launcher "$RAMDISK_DIR" "$RECOVERY_BIN_IN_RAMDISK" "$SHELL_PATH"

log "重新打包 ramdisk"
repack_ramdisk "$RAMDISK_DIR" "$RAMDISK_CPIO"

log "重新打包 recovery 镜像"
(
  cd "$UNPACK_DIR"
  "$MAGISKBOOT" repack "$INPUT_COPY" "$OUTPUT_IMAGE"
)

log "完成: $OUTPUT_IMAGE"