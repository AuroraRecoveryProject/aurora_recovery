#ifndef TWRP_FFI_TW_DISPLAY_FFI_H_
#define TWRP_FFI_TW_DISPLAY_FFI_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Display-related runtime controls.

// Sets the backlight brightness as a percentage (0..100).
// Returns 0 on success; negative errno-style value on error.
int tw_display_set_brightness_percent(int32_t percent);

// Reads current brightness and converts to percentage (0..100).
// Returns 0 on success; negative errno-style value on error.
int tw_display_get_brightness_percent(int32_t* out_percent);

// Converts a percent value (0..100) to the raw integer value expected by the
// active brightness node (".../brightness").
//
// This performs the same percent->raw scaling used by tw_display_set_brightness_percent,
// but does not write anything.
// Returns 0 on success; negative errno-style value on error.
int tw_display_percent_to_brightness_value(int32_t percent, int32_t* out_value);

#ifdef __cplusplus
}
#endif

#endif  // TWRP_FFI_TW_DISPLAY_FFI_H_
