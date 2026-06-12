传统 TWRP 刷入 ROM 的完整流程：

  main()  [twrp.cpp:344]
   │
   ├─ umask(0)
   ├─ 初始化 log → /tmp/recovery.log
   ├─ signal(SIGPIPE, SIG_IGN)
   ├─ DataManager::SetDefaultValues()
   ├─ PartitionManager.Process_Fstab()        ← 解析分区表
   ├─ gui_init() + gui_loadResources()        ← 加载 UI 资源
   ├─ DataManager::ReadSettingsFile()         ← 读取 /persist/TWRP/.twrp_settings
   │
   ├─ process_recovery_mode()                 ← 属性覆写、启动脚本、InjectTWRP
   │
   ├─ gui_start()   ← ★ 进入 GUI 主循环（阻塞直到用户退出）
   │     │
   │     │  用户在 GUI 中点击 "Install" 按钮
   │     │
   │     └─→ action.cpp:428
   │           TWinstall_zip(filename, &wipe_cache, check_digest)
   │             │
   │             ├─ 1. Digest 校验 (.md5/.sha256 文件)
   │             │
   │             ├─ 2. Package::CreateMemoryPackage(path)   ← mmap 整个 zip
   │             │
   │             ├─ 3. 签名验证 (otacerts.zip + verify_file)
   │             │
   │             ├─ 4. ★ 卸载 /system ★
   │             │      PartitionManager.UnMount_By_Path("/system")
   │             │      unlink("/system")
   │             │      mkdir("/system", 0755)
   │             │      → recovery 不再依赖 /system 上的任何文件!
   │             │
   │             ├─ 5. 判断 zip 类型:
   │             │      ├─ 有 META-INF/.../update-binary → 传统 ROM
   │             │      │   ├─ Prepare_Update_Binary()
   │             │      │   │   ├─ 提取 update-binary 到 /tmp/updater (0755)
   │             │      │   │   └─ 提取 file_contexts (SELinux)
   │             │      │   └─ Run_Update_Binary()
   │             │      │       ├─ fork()
   │             │      │       ├─ 子进程: execve(updater, args, environ)
   │             │      │       │   → 运行 ROM 的 Edify 脚本
   │             │      │       │   → mount/format/extract 各分区
   │             │      │       │   → 通过 pipe 发送 progress/ui_print/wipe_cache
   │             │      │       │   → 完成后 exit
   │             │      │       └─ 父进程: 读取 pipe 输出 → 更新进度条
   │             │      │
   │             │      └─ 有 payload_properties.txt → A/B OTA
   │             │          ├─ 挂载 system/vendor 供 backuptool 使用
   │             │          ├─ bind mount /system/bin/sh
   │             │          ├─ Run_Update_Binary() → update_engine_sideload
   │             │          └─ 卸载 + slot 切换 + Prepare_All_Super_Volumes
   │             │
   │             ├─ 6. 安装后处理:
   │             │      ├─ Disable_AVB2 (如果启用)
   │             │      └─ 检查 /system/bin/installTwrp → 重新安装 TWRP
   │             │
   │             └─ 7. 返回 INSTALL_SUCCESS / INSTALL_ERROR
   │
   │   GUI 继续运行，用户可以刷更多 zip 或点 "Reboot"
   │
   ├─ gui_start() 返回  ← 用户退出 GUI
   │
   └─ ★ reboot() ★  ← 无条件重启！[twrp.cpp:508]
        └─ TWFunc::tw_reboot(rb_system)   ← 默认重启进系统
             ├─ DataManager::Flush()        ← 保存设置
             ├─ sync()
             ├─ 卸载 /data
             ├─ 执行 /system/bin/rebootsystem.sh
             └─ property_set("sys.powerctl", "reboot,")  ← 内核重启

  关键设计

  ┌────────────────────┬─────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────┐
  │        顺序        │                     做什么                      │                                        为什么重要                                        │
  ├────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┤
  │ 安装前卸载 /system │ UnMount_By_Path → unlink → mkdir                │ recovery 主动断开对 /system 的依赖，后续 update-binary 可以安全地格式化/重写 system 分区 │
  ├────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┤
  │ 安装后无条件重启   │ gui_start() 返回 → reboot()                     │ recovery 不尝试在 flash 后继续操作；新 ROM 会在重启后加载                                │
  ├────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┤
  │ pipe 协议          │ progress / set_progress / ui_print / wipe_cache │ 子进程只通过 fd 与父进程通信，父进程不访问子进程操作的任何分区                           │
  └────────────────────┴─────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────┘

  对比 FFI 路径缺失的部分

  传统路径做但 FFI RunInstall 没做的：

  1. 没有在 fork 前卸载 /system — 导致 Magisk 的 umount -l /system 会影响仍依赖该挂载点的 recovery 进程
  2. 没有 execve + environ — 用的是 execv，子进程缺少环境变量
  3. 没有 file_contexts 提取 — SELinux 上下文可能不正确
  4. 没有 post-install 处理 — 不处理 AVB2、TWRP 重新打包
  5. 没有显式 reboot — 由外部调用者决定何时重启，如果外部调用者不重启，recovery 留在内存中但 /system 已被 Magisk 懒卸载

  这就是 Magisk 刷入后 rec 被杀死的原因：传统路径先卸载再执行 → Magisk 的 cleanup unmount 是空操作 → recovery 安全重启。FFI 路径跳过卸载 → Magisk 的 umount -l /system 生效 →
  recovery 进程失去 /system 依赖 → 崩溃。