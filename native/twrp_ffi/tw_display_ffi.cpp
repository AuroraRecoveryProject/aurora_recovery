#include "include/tw_display_ffi.h"

#include <errno.h>
#include <stdint.h>

#include <mutex>
#include <string>

#include "include/tw_ffi_internal.h"

namespace {

constexpr int kEventSet = 1;

}  // namespace

extern "C" int tw_display_percent_to_brightness_value(int32_t percent, int32_t* out_value) {
	return TwPercentToRawValue(percent, out_value);
}

extern "C" int tw_display_set_brightness_percent(int32_t percent) {
	int32_t raw_value = 0;
	int result = TwPercentToRawValue(percent, &raw_value);
	if (result != 0) {
		return result;
	}
	std::string brightness_file = TwGetBrightnessFile();
	if (brightness_file.empty()) {
		return -ENOENT;
	}
	std::string raw_string = std::to_string(raw_value);
	if (!TwWriteLine(brightness_file, raw_string)) {
		return -EIO;
	}
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	TwEnsureInitializedLocked();
	g_tw_settings["tw_brightness"] = raw_string;
	g_tw_settings["tw_brightness_pct"] = std::to_string(percent);
	TwNotifySubscribersLocked(kEventSet, "tw_brightness", g_tw_settings["tw_brightness"].c_str());
	TwNotifySubscribersLocked(kEventSet, "tw_brightness_pct", g_tw_settings["tw_brightness_pct"].c_str());
	return 0;
}

extern "C" int tw_display_get_brightness_percent(int32_t* out_percent) {
	if (out_percent == nullptr) {
		return -EINVAL;
	}
	std::lock_guard<std::mutex> lock(g_tw_ffi_mutex);
	int result = TwEnsureInitializedLocked();
	if (result != 0) {
		return result;
	}
	auto iter = g_tw_settings.find("tw_brightness_pct");
	if (iter != g_tw_settings.end()) {
		return TwParseInt(iter->second, out_percent);
	}
	iter = g_tw_settings.find("tw_brightness");
	if (iter == g_tw_settings.end()) {
		return -ENOENT;
	}
	int32_t raw_value = 0;
	result = TwParseInt(iter->second, &raw_value);
	if (result != 0) {
		return result;
	}
	int max_value = TwGetBrightnessMaxValue();
	if (max_value < 0) {
		return max_value;
	}
	*out_percent = static_cast<int32_t>((static_cast<long long>(raw_value) * 100) / max_value);
	return 0;
}

// 2026.05.24 check