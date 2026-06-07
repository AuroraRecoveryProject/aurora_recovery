#include "include/tw_install_ffi.h"
#include "tw_install_core.h"

extern "C" int tw_install_init(void) {
	return twinstallcore::Init();
}

extern "C" int tw_install_set_paths(const char* log_path, const char* install_file_path, const char* update_binary_path) {
	return twinstallcore::SetPaths(log_path, install_file_path, update_binary_path);
}

extern "C" int tw_install_start_zip(const char* path, int check_digest) {
	return twinstallcore::StartZip(path, check_digest != 0);
}

extern "C" int tw_install_get_state(void) {
	return twinstallcore::GetState();
}

extern "C" int tw_install_get_progress(void) {
	return twinstallcore::GetProgress();
}

extern "C" int tw_install_get_wipe_cache(void) {
	return twinstallcore::GetWipeCache();
}

extern "C" int tw_install_read_log(uint64_t offset, char* out_value, size_t out_len, uint64_t* out_next_offset) {
	return twinstallcore::ReadLog(offset, out_value, out_len, out_next_offset);
}

extern "C" int tw_install_get_last_error(char* out_value, size_t out_len) {
	return twinstallcore::GetLastError(out_value, out_len);
}

extern "C" int tw_install_get_last_result(void) {
	return twinstallcore::GetLastResult();
}

extern "C" int tw_install_reset_session(void) {
	return twinstallcore::ResetSession();
}