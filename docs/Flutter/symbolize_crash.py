#!/usr/bin/env python3
# 符号化 Flutter Runner 崩溃堆栈。
#
# 用法：
#   python3 symbolize_crash.py crash.txt       # 文件参数
#   python3 symbolize_crash.py < crash.txt     # 管道输入
#
# 依赖：
#   - ANDROID_NDK 环境变量（指向 NDK 根目录，脚本自动查找 llvm-addr2line）
#   - 未 strip 的 libflutter_engine.so 和 flutter-runner 符号文件
#
# 已知限制：
#   - ARM64 硬编码了返回地址 -4 修正（见下方注释），ARM32/x86 不适用
#   - 帧 #0（信号处理帧）来自 _Unwind_Backtrace 首步，IP 本身不可靠
#   - FML_CHECK / FML_DCHECK 等宏展开的崩溃点常显示 :0（无行号），
#     因为展开后的指令 DWARF 行号表未映射回宏调用行。函数名仍然准确。
#     非宏展开的帧行号完全精确（已通过 ARM64 -4 修正消除偏移）
#   - runner .sym 文件可能和设备 runner 不匹配，导致帧 #0 解析错误
#
# Symbolize Flutter Runner crash stacks.
# Usage:
#   python3 symbolize_crash.py crash.txt       # file argument
#   python3 symbolize_crash.py < crash.txt     # pipe input
# Dependencies:
#   - ANDROID_NDK environment variable (pointing to NDK root, script auto-finds llvm-addr2line)
#   - unstripped libflutter_engine.so and flutter-runner symbol files
# Known limitations:
#   - ARM64 hardcodes a -4 adjustment for return addresses (see comments below), not applicable to ARM32/x86
#   - Frame #0 (signal handler frame) comes from the first step of _Unwind_Backtrace, so its IP is inherently unreliable
#   - Crash points from macros like FML_CHECK / FML_DCHECK often show :0 (no line number) because the expanded instructions' DWARF line info doesn't map back to the macro
#     but function names are still accurate. Non-macro frames have precise line numbers (with ARM64 -4 adjustment eliminating offset)
#   - runner .sym file may not match the device runner, causing frame #0 to be misparsed
import sys
import re
import os
import subprocess
from collections import defaultdict

NDK = os.environ.get("ANDROID_NDK")
ADDR2LINE = None

if NDK:
    import os

    for root, _, files in os.walk(NDK):
        if "llvm-addr2line" in files:
            ADDR2LINE = os.path.join(root, "llvm-addr2line")
            break

if not ADDR2LINE:
    print("❌ 找不到 llvm-addr2line，请设置 ANDROID_NDK")
    sys.exit(1)

# 你本地符号文件路径（自己改）
SYMBOL_FILES = {
    "libflutter_engine.so": "/Users/Laurie/Desktop/nightmare-space/AuroraRecoveryProject/arp_render/flutter-3.38.5/engine/src/out/android_debug_unopt_arm64_embedder_vulkan/libflutter_engine.so",
    "flutter-runner": "/Users/Laurie/Desktop/nightmare-space/AuroraRecoveryProject/arp_render/flutter-embedded-linux/build/flutter-drm-dumb-backend.sym",
}

# 读取输入：优先文件参数，fallback 到管道
# Read input: prefer file argument, fallback to pipe
if len(sys.argv) > 1:
    with open(sys.argv[1]) as f:
        text = f.read()
elif not sys.stdin.isatty():
    text = sys.stdin.read()
else:
    print("用法: python3 symbolize.py crash.txt 或 pipe 输入")
    sys.exit(1)

lines = text.splitlines()

# =========================
# 分析内存映射，找到加载的共享对象及其地址范围
# Analyze memory maps to find loaded shared objects and their address ranges.
# =========================
maps = []

map_re = re.compile(
    r"^([0-9a-fA-F]+)-([0-9a-fA-F]+)\s+(\S+)\s+([0-9a-fA-F]+).*?\s(/.*)$"
)

for line in lines:
    m = map_re.match(line.strip())
    if not m:
        continue

    start, end, perm, offset, path = m.groups()
    start = int(start, 16)
    end = int(end, 16)
    offset = int(offset, 16)

    maps.append(
        {
            "start": start,
            "end": end,
            "perm": perm,
            "offset": offset,
            "path": path,
            "name": path.split("/")[-1],
        }
    )

# =========================
# 解析 backtrace，同时捕获原始行中 PC 后面的上下文
# （如 [vdso] (__kernel_rt_sigreturn) 或 /system/lib64/libc.so (abort)）
# Parse backtrace, capturing the context after PC in the original line
# (e.g., [vdso] (__kernel_rt_sigreturn) or /system/lib64/libc.so (abort))
# =========================
pc_re = re.compile(r"pc\s+([0-9a-fA-F]+)")

frames = []       # list of (pc, raw_context)
frame_contexts = []  # per-frame extra info from the backtrace line

for line in lines:
    m = pc_re.search(line)
    if not m:
        continue
    pc = int(m.group(1), 16)
    rest = line[m.end():].strip()
    frames.append(pc)
    frame_contexts.append(rest)

# =========================
# pc → so 匹配
# For each PC, find which shared object it belongs to and calculate the offset for addr2line.
# =========================
symbolize_requests = defaultdict(list)
resolved_frames = []

for index, pc in enumerate(frames):
    found = False
    for m in maps:
        if m["start"] <= pc < m["end"]:
            # ─── ARM64 返回地址修正 ───
            #
            # ARM64 (AArch64) 所有指令固定 4 字节宽。
            # bl (branch-and-link) 执行时会将 PC+4（即下一条指令地址）
            # 写入 LR (x30) 作为返回地址。堆栈回溯从栈帧中取出这些返回
            # 地址作为帧 PC 上报。
            #
            # 但 addr2line 假设传入的是「正在执行的指令」而非
            # 「调用返回后的下一条指令」。不修正时返回地址恰好落在
            # 调用指令的下一条——往往是下一个函数的入口，导致
            # addr2line 将调用帧错误归属到相邻的无关函数。
            #
            # 例：bl <abort> 位于 0x19085a4，LR 存 0x19085a8，
            #     0x19085a8 恰好是 FileMapping::CreateReadOnly 入口，
            #     减 4 → 0x19085a4 正确解析为 logging.cc 的 OS::Abort()。
            #
            # ─── 帧 #0 特殊处理 ───
            #
            # 帧 #0 来自 _Unwind_Backtrace → _Unwind_GetIP() 在信号
            # 处理器 (signal_handler) 上下文中的首帧 IP，不是 bl 的
            # 返回地址。ARM64 libunwind 从信号栈帧起步时，首帧的
            # _Unwind_GetIP 拿不到正确的 caller IP（这是已知局限），
            # 因此帧 #0 的 PC 本身就不在 signal_handler 函数内。
            # 再减 4 不会改善，跳过以保留 _Unwind_GetIP 的原始值。
            #
            # 实际调试时看帧 #2+ 即可，关键调用链（abort →
            # LogMessage → 崩溃点）都在后面几帧。
            arm64_adj = 0 if index == 0 else 4
            offset = pc - m["start"] + m["offset"] - arm64_adj
            symbolize_requests[m["name"]].append(offset)
            resolved_frames.append(
                {
                    "index": index,
                    "pc": pc,
                    "name": m["name"],
                    "offset": offset,
                    "symbolized": None,
                }
            )
            found = True
            break
    if not found:
        resolved_frames.append(
            {
                "index": index,
                "pc": pc,
                "name": None,
                "offset": None,
                "symbolized": None,
            }
        )


# =========================
# addr2line
# =========================
def symbolize(so_name, offsets):
    so_path = SYMBOL_FILES.get(so_name)
    if not so_path:
        return {offset: (f"{so_name}（无符号文件）", f"0x{offset:x}") for offset in offsets}

    args = [ADDR2LINE, "-C", "-f", "-e", so_path] + [f"0x{o:x}" for o in offsets]

    try:
        out = subprocess.check_output(args, text=True)
        lines = out.splitlines()
        result = {}
        for idx, offset in enumerate(offsets):
            func = lines[idx * 2].strip() if idx * 2 < len(lines) else "???"
            src = lines[idx * 2 + 1].strip() if idx * 2 + 1 < len(lines) else "??:0"
            result[offset] = (func, src)
        return result
    except Exception as e:
        error = f"addr2line 失败: {e}"
        return {offset: (error, "??:0") for offset in offsets}


# =========================
# Output formatting
# =========================
def clean_src_path(path):
    """Remove build directory prefix from addr2line output, leaving only the source relative path."""
    # out/<variant>/../../flutter/... → flutter/...
    # out/<variant>/../../third_party/... → third_party/...
    m = re.search(r'out/[^/]+/\.\./\.\./(.+)$', path)
    return m.group(1) if m else path


def strip_template(func):
    """Remove C++ template parameters (<> and their contents, supporting nesting), keeping only the template name."""
    # Example: shared_ptr<Pipeline<FrameItem>> → shared_ptr
    result = []
    depth = 0
    for ch in func:
        if ch == '<':
            depth += 1
        elif ch == '>':
            depth -= 1
        elif depth == 0:
            result.append(ch)
    return ''.join(result)


def strip_params(func):
    """Remove all (...) parameters/template parameters from C++ function signatures, leaving only the main function name."""
    # Example: OnAnimatorDraw(shared_ptr)::operator()() → OnAnimatorDraw::operator
    result = []
    depth = 0
    for ch in func:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif depth == 0:
            result.append(ch)
    return ''.join(result)


def clean_func(func):
    """Clean function name: remove template parameters, remove function parameters, remove qualifiers."""
    clean = strip_params(strip_template(func))
    clean = clean.rstrip()
    for suffix in (' const', ' noexcept'):
        if clean.endswith(suffix):
            clean = clean[:-len(suffix)]
    return clean


symbolized_results = {}
for so, offsets in symbolize_requests.items():
    symbolized_results[so] = symbolize(so, offsets)

# ── 收集所有帧数据（两遍：第一遍收集，第二遍对齐输出）──
PRELUDE_END = 2
prelude = []       # (idx, func_name, extra, note)
crash_chain = []   # (idx, func_name, extra)
tail = []           # (idx, func_name, note)

for frame in resolved_frames:
    idx = frame["index"]
    ctx = frame_contexts[idx] if idx < len(frame_contexts) else ""

    if frame["name"] is None:
        if idx == 0:
            note = "libunwind 首帧 IP 不可靠"
            prelude.append((idx, "[unreliable]", "", note))
        elif "vdso" in ctx:
            m = re.search(r'\((\w+)\)', ctx)
            func = m.group(1) if m else "__kernel_rt_sigreturn"
            prelude.append((idx, func, "vdso", ""))
        elif "libc" in ctx:
            m = re.search(r'\((\w+)\)', ctx)
            func = m.group(1) if m else "abort"
            prelude.append((idx, func, "libc.so", ""))
        elif idx > PRELUDE_END:
            note = "Dart JIT" if frame["pc"] > 0x7000000000 else ""
            tail.append((idx, "[unknown]", "", note))
        else:
            prelude.append((idx, "[unknown]", "", ""))
        continue

    func, src = symbolized_results[frame["name"]][frame["offset"]]
    name = clean_func(func)
    extra = clean_src_path(src)
    if extra == "??:0":
        extra = ""

    if idx <= PRELUDE_END:
        note = "libunwind 首帧 IP 不可靠" if idx == 0 else ""
        prelude.append((idx, name, extra, note))
    else:
        crash_chain.append((idx, name, extra))

# ── 计算最大函数名宽度 ──
all_names = [f[1] for f in prelude + crash_chain + tail]
max_w = max((len(n) for n in all_names), default=0)

def print_aligned(idx, name, extra, note=""):
    line = f" #{idx:x}   {name:<{max_w}s}"
    if extra:
        line += f"  ({extra})"
    if note:
        line += f"  ← {note}"
    print(line)

# ── 输出 ──
for item in prelude:
    print_aligned(*item)

if crash_chain:
    print(f"\n{'─' * 20} 崩溃调用链 {'─' * 20}")
    for item in crash_chain:
        print_aligned(*item)

if tail:
    print(f"\n{'─' * 20} JIT / 未知代码 {'─' * 20}")
    for item in tail:
        print_aligned(*item)
