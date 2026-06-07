#pragma once

#include <stddef.h>
#include <stdint.h>

namespace twinstallcore {

int Init();
int SetPaths(const char* log_path, const char* install_file_path, const char* update_binary_path);
int StartZip(const char* path, bool check_digest);
int GetState();
int GetProgress();
int GetWipeCache();
int ReadLog(uint64_t offset, char* out_value, size_t out_len, uint64_t* out_next_offset);
int GetLastError(char* out_value, size_t out_len);
int GetLastResult();
int ResetSession();

}  // namespace twinstallcore