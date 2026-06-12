#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_LZ4=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAGISKBOOT="/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/rom_extract/tools/magiskboot"

usage() {
	cat <<EOF
用法:
	$SCRIPT_NAME IMAGE

示例:
	$SCRIPT_NAME /path/to/vendor_boot.img

参数:
	IMAGE              输入镜像路径，例如 rom/images/vendor_boot.img
	--lz4 PATH         可选，指定 lz4 可执行文件；不传则自动从 PATH 查找
	--help             显示帮助

脚本行为:
	1. 输出目录自动使用镜像同级、去掉 .img 后缀后的目录名
	2. 调用 magiskboot unpack -h 解包
	3. 若存在 ramdisk.cpio，则自动判断是否为 LZ4/LZ4 legacy
	4. 自动展开 ramdisk 到输出目录下的 ramdisk_out

固定工具路径:
	$MAGISKBOOT
EOF
}

log() {
	printf '[extract] %s\n' "$*"
}

fail() {
	printf '[extract] ERROR: %s\n' "$*" >&2
	exit 1
}

require_file() {
	local path="$1"
	[[ -f "$path" ]] || fail "文件不存在: $path"
}

require_exec() {
	local path="$1"
	[[ -x "$path" ]] || fail "文件不可执行: $path"
}

resolve_lz4() {
	local explicit_path="$1"

	if [[ -n "$explicit_path" ]]; then
		require_exec "$explicit_path"
		printf '%s\n' "$explicit_path"
		return 0
	fi

	if command -v lz4 >/dev/null 2>&1; then
		command -v lz4
		return 0
	fi

	return 1
}

detect_lz4_magic() {
	local file_path="$1"
	local magic

	magic="$(xxd -p -l 4 "$file_path" 2>/dev/null || true)"
	case "$magic" in
		04224d18|02214c18)
			return 0
			;;
	esac
	return 1
}

is_lz4_file() {
	local file_path="$1"

	if command -v file >/dev/null 2>&1; then
		if file "$file_path" 2>/dev/null | grep -qi 'lz4'; then
			return 0
		fi
	fi

	detect_lz4_magic "$file_path"
}

INPUT_IMAGE=""
LZ4_BIN="$DEFAULT_LZ4"

if [[ $# -eq 0 ]]; then
	usage
	exit 0
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--lz4)
			LZ4_BIN="${2:-}"
			shift 2
			;;
		--help|-h)
			usage
			exit 0
			;;
		-*)
			fail "未知参数: $1"
			;;
		*)
			if [[ -n "$INPUT_IMAGE" ]]; then
				fail "只能传递一个 IMAGE 路径"
			fi
			INPUT_IMAGE="$1"
			shift
			;;
	esac
done

[[ -n "$INPUT_IMAGE" ]] || fail "缺少 IMAGE 参数"

require_file "$INPUT_IMAGE"
require_file "$MAGISKBOOT"
require_exec "$MAGISKBOOT"

IMAGE_NAME="$(basename "$INPUT_IMAGE")"
IMAGE_DIR="$(cd "$(dirname "$INPUT_IMAGE")" && pwd)"
OUTPUT_NAME="${IMAGE_NAME%.img}"
ABS_OUT_DIR="$IMAGE_DIR/$OUTPUT_NAME"
COPIED_IMAGE="$ABS_OUT_DIR/$IMAGE_NAME"

if [[ "$ABS_OUT_DIR" == "$INPUT_IMAGE" ]]; then
	fail "无法推导输出目录: $INPUT_IMAGE"
fi

if [[ -e "$ABS_OUT_DIR" ]]; then
	fail "输出目录已存在: $ABS_OUT_DIR"
fi

mkdir -p "$ABS_OUT_DIR"
cp -f "$INPUT_IMAGE" "$COPIED_IMAGE"

log "解包镜像: $INPUT_IMAGE"
log "输出目录: $ABS_OUT_DIR"
cd "$ABS_OUT_DIR"
"$MAGISKBOOT" unpack -h "$IMAGE_NAME"

if [[ ! -f ramdisk.cpio ]]; then
	log "未发现 ramdisk.cpio，解包完成"
	exit 0
fi

RAMDISK_SOURCE="ramdisk.cpio"
if is_lz4_file ramdisk.cpio; then
	if ! LZ4_BIN="$(resolve_lz4 "$LZ4_BIN")"; then
		fail "检测到 ramdisk.cpio 为 LZ4，但未找到 lz4 可执行文件，请通过 --lz4 指定"
	fi

	log "检测到 LZ4 ramdisk，先解压"
	"$LZ4_BIN" -d -c ramdisk.cpio > ramdisk.decomp.cpio
	RAMDISK_SOURCE="ramdisk.decomp.cpio"
else
	log "ramdisk.cpio 为普通 cpio，直接展开"
fi

rm -rf ramdisk_out
mkdir -p ramdisk_out
cd ramdisk_out
"$MAGISKBOOT" cpio "../$RAMDISK_SOURCE" extract

log "ramdisk 已展开到: $ABS_OUT_DIR/ramdisk_out"