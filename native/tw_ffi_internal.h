#pragma once

#include <stddef.h>
#include <stdint.h>

#include <atomic>
#include <map>
#include <mutex>
#include <string>
#include <vector>

#include "tw_settings_ffi.h"

struct TwSettingsSubscriber {
	tw_settings_event_cb callback;
	void* user_data;
};

extern std::mutex g_tw_ffi_mutex;
extern std::map<std::string, std::string> g_tw_settings;
extern std::vector<TwSettingsSubscriber> g_tw_settings_subscribers;
extern std::atomic<bool> g_tw_settings_initialized;

int TwCopyStringOut(const std::string& value, char* out_value, size_t out_len);
int TwParseInt(const std::string& value, int32_t* out_value);
bool TwPathExists(const std::string& path);
void TwSetDefaultSettingsLocked();
int TwLoadSettingsLocked();
int TwSaveSettingsLocked();
void TwNotifySubscribersLocked(int event_type, const char* key, const char* value);
int TwEnsureInitializedLocked();
std::string TwSerializeSettingsLocked();
bool TwReadFirstLine(const std::string& path, std::string* out_value);
bool TwWriteLine(const std::string& path, const std::string& value);
std::string TwGetBrightnessFile();
int TwGetBrightnessMaxValue();
int TwPercentToRawValue(int32_t percent, int32_t* out_value);