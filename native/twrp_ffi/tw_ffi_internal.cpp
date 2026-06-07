#include "include/tw_ffi_internal.h"

#include <dirent.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <fstream>
#include <sstream>

namespace {

constexpr char kSettingsDir[] = "/persist/TWRP";
constexpr char kSettingsFile[] = "/persist/TWRP/.twrp_settings";
constexpr int kSettingsFileVersion = 0x00010010;

std::string FindBrightnessFileInDir(const std::string& root) {
	DIR* dir = opendir(root.c_str());
	if (dir == nullptr) {
		return "";
	}
	std::string result;
	struct dirent* entry = nullptr;
	while ((entry = readdir(dir)) != nullptr) {
		if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
			continue;
		}
		std::string candidate = root + "/" + entry->d_name + "/brightness";
		if (access(candidate.c_str(), R_OK | W_OK) == 0) {
			result = candidate;
			break;
		}
	}
	closedir(dir);
	return result;
}

}  // namespace

std::mutex g_tw_ffi_mutex;
std::map<std::string, std::string> g_tw_settings;
std::vector<TwSettingsSubscriber> g_tw_settings_subscribers;
std::atomic<bool> g_tw_settings_initialized(false);

int TwCopyStringOut(const std::string& value, char* out_value, size_t out_len) {
	if (out_value == nullptr || out_len == 0) {
		return -EINVAL;
	}
	if (value.size() + 1 > out_len) {
		return -ENOSPC;
	}
	memcpy(out_value, value.c_str(), value.size() + 1);
	return 0;
}

int TwParseInt(const std::string& value, int32_t* out_value) {
	if (out_value == nullptr) {
		return -EINVAL;
	}
	char* end = nullptr;
	long parsed = strtol(value.c_str(), &end, 10);
	if (end == value.c_str() || *end != '\0') {
		return -EINVAL;
	}
	*out_value = static_cast<int32_t>(parsed);
	return 0;
}

bool TwPathExists(const std::string& path) {
	return access(path.c_str(), F_OK) == 0;
}

void TwSetDefaultSettingsLocked() {
	g_tw_settings.clear();
	g_tw_settings["tw_button_vibrate"] = "80";
	g_tw_settings["tw_keyboard_vibrate"] = "40";
	g_tw_settings["tw_action_vibrate"] = "160";
	g_tw_settings["tw_install_reboot"] = "0";
	g_tw_settings["tw_signed_zip_verify"] = "0";
	g_tw_settings["tw_disable_free_space"] = "0";
	g_tw_settings["tw_force_digest_check"] = "0";
	g_tw_settings["tw_use_compression"] = "0";
	g_tw_settings["tw_time_zone"] = "CST6CDT,M3.2.0,M11.1.0";
	g_tw_settings["tw_gui_sort_order"] = "1";
	g_tw_settings["tw_rm_rf"] = "0";
	g_tw_settings["tw_skip_digest_check"] = "0";
	g_tw_settings["tw_skip_digest_check_zip"] = "1";
	g_tw_settings["tw_skip_digest_generate"] = "0";
	g_tw_settings["tw_sdext_size"] = "0";
	g_tw_settings["tw_swap_size"] = "0";
	g_tw_settings["tw_sdpart_file_system"] = "ext3";
	g_tw_settings["tw_time_zone_guisel"] = "CST6;CDT,M3.2.0,M11.1.0";
	g_tw_settings["tw_time_zone_guioffset"] = "0";
	g_tw_settings["tw_time_zone_guidst"] = "0";
	g_tw_settings["tw_auto_reflashtwrp"] = "0";
	g_tw_settings["tw_auto_disable_avb2"] = "0";
	g_tw_settings["tw_military_time"] = "0";
	g_tw_settings["tw_screen_timeout_secs"] = "60";
	g_tw_settings["tw_no_screen_timeout"] = "0";
	g_tw_settings["tw_brightness_pct"] = "100";
}

int TwLoadSettingsLocked() {
	TwSetDefaultSettingsLocked();
	FILE* in = fopen(kSettingsFile, "rb");
	if (in == nullptr) {
		return errno == ENOENT ? 0 : -errno;
	}

	int file_version = 0;
	if (fread(&file_version, 1, sizeof(int), in) != sizeof(int)) {
		fclose(in);
		return -EIO;
	}
	if (file_version != kSettingsFileVersion) {
		fclose(in);
		return 0;
	}

	while (true) {
		unsigned short key_length = 0;
		if (fread(&key_length, 1, sizeof(unsigned short), in) != sizeof(unsigned short)) {
			break;
		}
		if (key_length == 0 || key_length >= 512) {
			fclose(in);
			return -EIO;
		}
		char key_buffer[513] = {0};
		if (fread(key_buffer, 1, key_length, in) != key_length) {
			fclose(in);
			return -EIO;
		}

		unsigned short value_length = 0;
		if (fread(&value_length, 1, sizeof(unsigned short), in) != sizeof(unsigned short)) {
			fclose(in);
			return -EIO;
		}
		if (value_length == 0 || value_length >= 512) {
			fclose(in);
			return -EIO;
		}
		char value_buffer[513] = {0};
		if (fread(value_buffer, 1, value_length, in) != value_length) {
			fclose(in);
			return -EIO;
		}

		g_tw_settings[key_buffer] = value_buffer;
	}

	fclose(in);
	return 0;
}

int TwSaveSettingsLocked() {
	if (!TwPathExists(kSettingsDir) && mkdir(kSettingsDir, 0777) != 0 && errno != EEXIST) {
		return -errno;
	}

	FILE* out = fopen(kSettingsFile, "wb");
	if (out == nullptr) {
		return -errno;
	}

	int file_version = kSettingsFileVersion;
	if (fwrite(&file_version, 1, sizeof(int), out) != sizeof(int)) {
		fclose(out);
		return -EIO;
	}

	for (const auto& entry : g_tw_settings) {
		unsigned short key_length = static_cast<unsigned short>(entry.first.size() + 1);
		unsigned short value_length = static_cast<unsigned short>(entry.second.size() + 1);
		if (fwrite(&key_length, 1, sizeof(unsigned short), out) != sizeof(unsigned short) ||
		    fwrite(entry.first.c_str(), 1, key_length, out) != key_length ||
		    fwrite(&value_length, 1, sizeof(unsigned short), out) != sizeof(unsigned short) ||
		    fwrite(entry.second.c_str(), 1, value_length, out) != value_length) {
			fclose(out);
			return -EIO;
		}
	}

	fclose(out);
	return 0;
}

void TwNotifySubscribersLocked(int event_type, const char* key, const char* value) {
	for (const auto& subscriber : g_tw_settings_subscribers) {
		if (subscriber.callback != nullptr) {
			subscriber.callback(event_type, key, value, subscriber.user_data);
		}
	}
}

int TwEnsureInitializedLocked() {
	if (!g_tw_settings_initialized.load()) {
		int result = TwLoadSettingsLocked();
		if (result != 0) {
			return result;
		}
		g_tw_settings_initialized.store(true);
	}
	return 0;
}

std::string TwSerializeSettingsLocked() {
	std::ostringstream stream;
	for (const auto& entry : g_tw_settings) {
		stream << entry.first << '=' << entry.second << '\n';
	}
	return stream.str();
}

bool TwReadFirstLine(const std::string& path, std::string* out_value) {
	if (out_value == nullptr) {
		return false;
	}
	std::ifstream stream(path);
	if (!stream.is_open()) {
		return false;
	}
	std::getline(stream, *out_value);
	return !stream.fail() || !out_value->empty();
}

bool TwWriteLine(const std::string& path, const std::string& value) {
	FILE* file = fopen(path.c_str(), "wb");
	if (file == nullptr) {
		return false;
	}
	bool ok = fwrite(value.c_str(), 1, value.size(), file) == value.size();
	fclose(file);
	return ok;
}

std::string TwGetBrightnessFile() {
	std::string brightness_file = FindBrightnessFileInDir("/sys/class/backlight");
	if (!brightness_file.empty()) {
		return brightness_file;
	}
	return FindBrightnessFileInDir("/sys/class/leds/lcd-backlight");
}

int TwGetBrightnessMaxValue() {
	std::string brightness_file = TwGetBrightnessFile();
	if (brightness_file.empty()) {
		return -ENOENT;
	}
	size_t slash = brightness_file.rfind('/');
	if (slash == std::string::npos) {
		return -EINVAL;
	}
	std::string max_path = brightness_file.substr(0, slash + 1) + "max_brightness";
	std::string max_value;
	if (!TwReadFirstLine(max_path, &max_value)) {
		return 255;
	}
	char* end = nullptr;
	long parsed = strtol(max_value.c_str(), &end, 10);
	if (end == max_value.c_str() || *end != '\0' || parsed <= 0) {
		return 255;
	}
	return static_cast<int>(parsed);
}

int TwPercentToRawValue(int32_t percent, int32_t* out_value) {
	if (out_value == nullptr) {
		return -EINVAL;
	}
	if (percent < 0 || percent > 100) {
		return -ERANGE;
	}
	int max_value = TwGetBrightnessMaxValue();
	if (max_value < 0) {
		return max_value;
	}
	*out_value = static_cast<int32_t>((static_cast<long long>(percent) * max_value) / 100);
	return 0;
}