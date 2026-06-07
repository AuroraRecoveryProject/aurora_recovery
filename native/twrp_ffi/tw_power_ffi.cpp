#include "include/tw_power_ffi.h"

#include <errno.h>

#include <string>

#include "../recovery_utils/include/recovery_utils/battery_utils.h"
#include "include/tw_ffi_internal.h"

extern "C" int tw_power_get_battery_info(tw_battery_info_t* out_info) {
	if (out_info == nullptr) {
		return -EINVAL;
	}
	BatteryInfo info = GetBatteryInfo();
	out_info->capacity = info.capacity;
	out_info->charging = info.charging ? 1 : 0;
	return 0;
}

extern "C" int tw_power_get_battery_string(char* out_value, size_t out_len) {
	tw_battery_info_t info;
	int result = tw_power_get_battery_info(&info);
	if (result != 0) {
		return result;
	}
	std::string value = std::to_string(info.capacity) + "%" + (info.charging ? "+" : " ");
	return TwCopyStringOut(value, out_value, out_len);
}

// 2026.05.24 check