#pragma once

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*tw_settings_event_cb)(int event_type, const char* key, const char* value, void* user_data);

int tw_settings_init(void);
int tw_settings_get(const char* key, char* out_value, size_t out_len);
int tw_settings_get_all(char* out_value, size_t out_len);
int tw_settings_set(const char* key, const char* value);
int tw_settings_flush(void);
int tw_settings_reset_defaults(void);
int tw_settings_subscribe(tw_settings_event_cb callback, void* user_data);

#ifdef __cplusplus
}
#endif
