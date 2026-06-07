LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := libtwrp_core_ffi
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := \
	tw_ffi_internal.cpp \
	tw_settings_ffi.cpp \
	tw_display_ffi.cpp \
	tw_power_ffi.cpp \
	tw_install_ffi.cpp \
	tw_install_core.cpp

LOCAL_CFLAGS += -std=gnu++17 -Wno-unused-parameter -Wno-unused-function

LOCAL_C_INCLUDES += \
	$(LOCAL_PATH)/include \
	$(LOCAL_PATH)/.. \
	$(LOCAL_PATH)/../twrpinstall/include \
	$(LOCAL_PATH)/../recovery_utils/include \
	system/libziparchive/include

LOCAL_SHARED_LIBRARIES += \
	libbase \
	libc \
	libc++ \
	libcutils \
	libcrypto \
	liblog \
	libutils \
	libziparchive \
	libaosprecovery \
	libhidlbase \
	libbinder_ndk \
	android.hardware.health@2.0 \
	android.hardware.health@2.1 \
	android.hardware.health-V3-ndk \
	android.hardware.health-translate-ndk

LOCAL_STATIC_LIBRARIES += \
	libtwrpinstall \
	librecovery_utils \
	libhealthhalutils \
	libhealthshim

include $(BUILD_SHARED_LIBRARY)