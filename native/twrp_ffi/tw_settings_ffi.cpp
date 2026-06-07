#include "include/tw_settings_ffi.h"

#include <errno.h>

#include <mutex>

#include "include/tw_ffi_internal.h"

namespace {

constexpr int kEventInit = 0;
constexpr int kEventSet = 1;
constexpr int kEventReset = 2;

}  // namespace

extern "C" int tw_settings_init(void) {
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	TwNotifySubscribersLocked(kEventInit, nullptr, nullptr);
	return 0;
}

extern "C" int tw_settings_get(const char* key, char* out_value, size_t out_len) {
	if (key == nullptr) {
		return -EINVAL;
	}
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	auto iter = g_tw_settings.find(key);
	if (iter == g_tw_settings.end()) {
		return -ENOENT;
	}
	return TwCopyStringOut(iter->second, out_value, out_len);
}

extern "C" int tw_settings_get_all(char* out_value, size_t out_len) {
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	return TwCopyStringOut(TwSerializeSettingsLocked(), out_value, out_len);
}

extern "C" int tw_settings_set(const char* key, const char* value) {
	if (key == nullptr || value == nullptr) {
		return -EINVAL;
	}
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	g_tw_settings[key] = value;
	TwNotifySubscribersLocked(kEventSet, key, value);
	return 0;
}

extern "C" int tw_settings_flush(void) {
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	return TwSaveSettingsLocked();
}

extern "C" int tw_settings_reset_defaults(void) {
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	TwSetDefaultSettingsLocked();
	g_tw_settings_initialized.store(true);
	TwNotifySubscribersLocked(kEventReset, nullptr, nullptr);
	return 0;
}

extern "C" int tw_settings_subscribe(tw_settings_event_cb callback, void* user_data) {
	if (callback == nullptr) {
		return -EINVAL;
	}
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	g_tw_settings_subscribers.push_back(TwSettingsSubscriber{callback, user_data});
	callback(kEventInit, nullptr, nullptr, user_data);
	return 0;
}

// 2026.05.24 check