# Recovery 构建时到底生效哪个 fstab

## TL;DR（结论）

- **最终生效**的是构建变量 `recovery_fstab` 选中的那个输入文件（通常就是设备目录下的 `recovery.fstab`）。
- 设备树里放在 `recovery/root/system/etc/recovery.fstab` 的“副本”，**会先被拷进 ramdisk**，但**通常会被后续步骤覆盖**，因此不应当作为“权威来源”。
- TWRP 运行时读取的是 `"/etc/twrp.fstab"`（优先）或 `"/etc/recovery.fstab"`（fallback）；而 rootfs 中 ` /etc -> /system/etc ` 是软链接，因此它最终落到同一份文件。

> 这份文档讲的是“recovery 镜像/ramdisk 的构建链路”，不是 ROM 解包出来的文件。

---

## 1) `recovery_fstab` 如何被选中（三选一优先级）

构建系统用下面的优先级来决定 `recovery_fstab` 指向谁（先命中先用）：

```makefile
ifdef TARGET_RECOVERY_FSTAB
  recovery_fstab := $(TARGET_RECOVERY_FSTAB)

else ifdef TARGET_RECOVERY_FSTAB_GENRULE
  # soong genrule 模块输出
  recovery_fstab := $(call intermediates-dir-for,ETC,$(TARGET_RECOVERY_FSTAB_GENRULE))/$(TARGET_RECOVERY_FSTAB_GENRULE)

else
  # 默认：设备目录下的 recovery.fstab
  recovery_fstab := $(strip $(wildcard $(TARGET_DEVICE_DIR)/recovery.fstab))
endif
```

解释：

- 如果你显式设置 `TARGET_RECOVERY_FSTAB`，那它就是唯一权威输入。
- 否则如果你设置 `TARGET_RECOVERY_FSTAB_GENRULE`，就用 genrule 生成的输出当 fstab。
- 否则走默认：去 `$(TARGET_DEVICE_DIR)/recovery.fstab` 找。

---

## 2) 为什么 `recovery/root/system/etc/recovery.fstab` 通常不生效（会被覆盖）

构建 recovery ramdisk 时，有两步会影响 `system/etc/recovery.fstab`，顺序决定结果：

### 2.1 先拷贝设备树的 `recovery/root/**`

设备树目录下的 `recovery/root` 会整体被拷贝进 recovery 输出目录，因此你放在 `recovery/root/system/etc/` 下的文件会进入 ramdisk：

```makefile
$(foreach item,$(recovery_root_private), \
  cp -rf $(item) $(TARGET_RECOVERY_OUT)/;)
```

### 2.2 后用 `recovery_fstab` 选中的输入“强制覆盖”目标位置

随后构建系统会把 `recovery_fstab` 选中的输入复制到固定目标：

```makefile
$(foreach item,$(recovery_fstab), \
  cp -f $(item) $(TARGET_RECOVERY_ROOT_OUT)/system/etc/recovery.fstab;)
```

`cp -f` 的含义是：**无条件覆盖**。因此，只要 `recovery_fstab` 非空，前一步带进去的同名文件就会被覆盖。

这也是为什么：

- 你维护两份 fstab 时，`recovery/root/system/etc/recovery.fstab` 很容易“看起来存在”，但并不是最终生效来源。

---

## 3) 运行时：TWRP 实际读取哪个路径

TWRP 启动时会按顺序尝试：

1. `"/etc/twrp.fstab"`
2. 若不存在，则读 `"/etc/recovery.fstab"`

（对应 TWRP 的启动逻辑：先找 twrp.fstab，再 fallback recovery.fstab）

---

## 4) 为什么构建落点是 `system/etc/recovery.fstab`，但运行时读 `"/etc/recovery.fstab"`

因为 rootfs 在生成时会创建软链接：

- `ln -sf /system/etc $(TARGET_ROOT_OUT)/etc`

也就是：

- ` /etc ` 实际指向 ` /system/etc `

因此运行时读取 `"/etc/recovery.fstab"`，实际上就是读取 `"/system/etc/recovery.fstab"`。

---

## 5) 如何验证“最终生效的是哪份”（不靠猜）

构建完成后，直接检查 recovery 输出目录中最终的目标文件内容即可：

- `$(TARGET_RECOVERY_ROOT_OUT)/system/etc/recovery.fstab`

它的内容应该与 `recovery_fstab` 选中的输入一致（默认情况下就是设备目录下的 `recovery.fstab`），而不是你在 `recovery/root/system/etc/` 下放的副本。

同时，TWRP 启动日志通常会打印类似：

- `=> Processing /etc/twrp.fstab` 或 `=> Processing /etc/recovery.fstab`

这能证明运行时走的是 `/etc/...` 路径（也就等价于 `/system/etc/...`）。
