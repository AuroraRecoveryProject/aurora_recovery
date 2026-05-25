#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
	TW_INSTALL_STATE_IDLE = 0,
	TW_INSTALL_STATE_RUNNING = 1,
	TW_INSTALL_STATE_SUCCESS = 2,
	TW_INSTALL_STATE_FAILED = 3,
};

int tw_install_init(void);
int tw_install_set_paths(const char* log_path, const char* install_file_path, const char* update_binary_path);
int tw_install_start_zip(const char* path, int check_digest);
int tw_install_get_state(void);
int tw_install_get_progress(void);
int tw_install_get_wipe_cache(void);
int tw_install_read_log(uint64_t offset, char* out_value, size_t out_len, uint64_t* out_next_offset);
int tw_install_get_last_error(char* out_value, size_t out_len);
int tw_install_get_last_result(void);
int tw_install_reset_session(void);

#ifdef __cplusplus
}
#endif