#!/system/bin/sh
set -eu
cd /tmp/app-debug.apk
export LD_LIBRARY_PATH=/tmp/app-debug.apk/bundle/lib:/tmp/app-debug.apk:/vendor/lib64/hw:/system/lib64:/vendor/lib64:/system_root/system/lib64
export FLUTTER_LOG_LEVELS=INFO
export TMPDIR=/tmp/app-debug.apk
export RECOVERY_PIXEL_FORMAT=RGBX
export FLUTTER_MINUITWRP_LOG=1
exec ./flutter-runner --bundle=/tmp/app-debug.apk/bundle --fullscreen --force-scale-factor=2.5 --enable-impeller
