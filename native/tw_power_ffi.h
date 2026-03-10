#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Battery / power related runtime information.
// Note: this is NOT persisted in /data/recovery/.twrps (settings file).

typedef struct tw_battery_info {
  // 0..100 normally. Some legacy paths may return 101 (unknown / no battery).
  int32_t capacity;

  // 1 if charging/on charger, 0 otherwise.
  int32_t charging;
} tw_battery_info_t;

// Returns 0 on success; negative errno-style value on error.
int tw_power_get_battery_info(tw_battery_info_t* out_info);

// Convenience: returns a UI-friendly string like "85%+" or "85% ".
// Returns 0 on success; negative errno-style value on error.
int tw_power_get_battery_string(char* out_value, size_t out_len);

#ifdef __cplusplus
}
#endif
