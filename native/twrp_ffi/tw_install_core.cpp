#include "include/tw_install_core.h"

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

#include <atomic>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#ifndef MS_SLAVE
#define MS_SLAVE  (1UL<<19)
#endif
#ifndef MS_REC
#define MS_REC    16384UL
#endif
#ifndef CLONE_NEWNS
#define CLONE_NEWNS 0x00020000
#endif

#include "../../../system/libziparchive/include/ziparchive/zip_archive.h"

#include "../otautil/include/otautil/paths.h"
#include "../twrpinstall/include/installcommand.h"
#include "../twrpinstall/include/twinstall/install.h"
#include "../twrpinstall/include/twinstall/package.h"
#include "../twrpinstall/include/twinstall/verifier.h"
#include "../twrpinstall/include/twinstall/wipe_data.h"
#include "include/tw_ffi_internal.h"
#include "include/tw_install_ffi.h"

namespace twinstallcore {
namespace {

constexpr size_t kMaxLogBytes = 2 * 1024 * 1024;
constexpr float kVerificationPortion = VERIFICATION_PROGRESS_FRACTION;

std::mutex g_mutex;
std::string g_log_cache;
uint64_t g_log_start_offset = 0;
std::string g_last_error;
std::string g_active_path;
std::atomic<int> g_state(TW_INSTALL_STATE_IDLE);
std::atomic<int> g_progress(0);
std::atomic<int> g_last_result(0);
std::atomic<int> g_wipe_cache(0);
std::atomic<bool> g_thread_running(false);

double g_portion_start = 0.0;
double g_portion_size = 0.0;

int CopyStringOut(const std::string& value, char* out_value, size_t out_len) {
	if (out_value == nullptr || out_len == 0) {
		return -EINVAL;
	}
	if (value.size() + 1 > out_len) {
		return -ENOSPC;
	}
	memcpy(out_value, value.c_str(), value.size() + 1);
	return 0;
}

int CopyStringSliceOut(const std::string& value, size_t start, char* out_value, size_t out_len) {
	if (out_value == nullptr || out_len == 0) {
		return -EINVAL;
	}
	if (start > value.size()) {
		return -ERANGE;
	}
	size_t slice_len = value.size() - start;
	if (slice_len + 1 > out_len) {
		return -ENOSPC;
	}
	memcpy(out_value, value.data() + start, slice_len);
	out_value[slice_len] = '\0';
	return 0;
}

std::string Trim(const std::string& value) {
	size_t start = 0;
	while (start < value.size() && isspace(static_cast<unsigned char>(value[start])) != 0) {
		start++;
	}
	size_t end = value.size();
	while (end > start && isspace(static_cast<unsigned char>(value[end - 1])) != 0) {
		end--;
	}
	return value.substr(start, end - start);
}

std::vector<std::string> SplitWhitespace(const std::string& value) {
	std::vector<std::string> tokens;
	std::string current;
	for (char ch : value) {
		if (isspace(static_cast<unsigned char>(ch)) != 0) {
			if (!current.empty()) {
				tokens.push_back(current);
				current.clear();
			}
			continue;
		}
		current.push_back(ch);
	}
	if (!current.empty()) {
		tokens.push_back(current);
	}
	return tokens;
}

std::string ToLowerAscii(std::string value) {
	for (char& ch : value) {
		ch = static_cast<char>(tolower(static_cast<unsigned char>(ch)));
	}
	return value;
}

std::string ShellQuote(const std::string& value) {
	std::string quoted = "'";
	for (char ch : value) {
		if (ch == '\'') {
			quoted.append("'\\''");
		} else {
			quoted.push_back(ch);
		}
	}
	quoted.push_back('\'');
	return quoted;
}

bool ReadFileToString(const std::string& path, std::string* content) {
	FILE* file = fopen(path.c_str(), "rb");
	if (file == nullptr) {
		return false;
	}
	content->clear();
	char buffer[4096];
	while (true) {
		size_t read_bytes = fread(buffer, 1, sizeof(buffer), file);
		if (read_bytes > 0) {
			content->append(buffer, read_bytes);
		}
		if (read_bytes < sizeof(buffer)) {
			break;
		}
	}
	const bool ok = ferror(file) == 0;
	fclose(file);
	return ok;
}


bool WriteStringToFile(const std::string& path, const std::string& content) {
	FILE* file = fopen(path.c_str(), "wb");
	if (file == nullptr) {
		return false;
	}
	const bool ok = fwrite(content.data(), 1, content.size(), file) == content.size();
	fclose(file);
	return ok;
}

std::vector<char*> StringVectorToNullTerminatedArray(std::vector<std::string>* args) {
	std::vector<char*> out;
	out.reserve(args->size() + 1);
	for (std::string& arg : *args) {
		out.push_back(arg.empty() ? const_cast<char*>("") : &arg[0]);
	}
	out.push_back(nullptr);
	return out;
}

bool ParseDoubleString(const std::string& value, double* result) {
	char* end = nullptr;
	const double parsed = strtod(value.c_str(), &end);
	if (end == value.c_str()) {
		return false;
	}
	while (end != nullptr && *end != '\0') {
		if (isspace(static_cast<unsigned char>(*end)) == 0) {
			return false;
		}
		end++;
	}
	*result = parsed;
	return true;
}

std::string FormatInstallResult(int result) {
	char buffer[64];
	snprintf(buffer, sizeof(buffer), "Install finished with result %d.", result);
	return buffer;
}

std::string ReadFirstTokenFromCommand(const std::string& command) {
	FILE* pipe = popen(command.c_str(), "r");
	if (pipe == nullptr) {
		return std::string();
	}
	char buffer[512] = {0};
	std::string output;
	if (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
		output = buffer;
	}
	pclose(pipe);
	std::vector<std::string> tokens = SplitWhitespace(output);
	if (tokens.empty()) {
		return std::string();
	}
	return ToLowerAscii(tokens.front());
}

std::string ComputeDigestWithCommand(const std::string& binary, const std::string& path) {
	return ReadFirstTokenFromCommand(binary + " " + ShellQuote(path));
}

std::string TrimTrailingNewlines(std::string value) {
	while (!value.empty() && (value.back() == '\n' || value.back() == '\r')) {
		value.pop_back();
	}
	return value;
}

void AppendLogLineLocked(const std::string& line) {
	std::string normalized = TrimTrailingNewlines(line);
	if (normalized.empty()) {
		return;
	}
	g_log_cache.append(normalized);
	g_log_cache.push_back('\n');
	if (g_log_cache.size() > kMaxLogBytes) {
		size_t trim_bytes = g_log_cache.size() - kMaxLogBytes;
		g_log_cache.erase(0, trim_bytes);
		g_log_start_offset += trim_bytes;
	}
	const std::string log_path = Paths::Get().temporary_log_file();
	if (!log_path.empty()) {
		FILE* file = fopen(log_path.c_str(), "ab");
		if (file != nullptr) {
			fwrite(normalized.data(), 1, normalized.size(), file);
			fwrite("\n", 1, 1, file);
			fclose(file);
		}
	}
}

void SetErrorLocked(const std::string& message) {
	g_last_error = message;
	AppendLogLineLocked("ERROR: " + message);
}

double ClampFraction(double value) {
	if (value < 0.0) {
		return 0.0;
	}
	if (value > 1.0) {
		return 1.0;
	}
	return value;
}

void SetProgressFractionLocked(double fraction) {
	int percent = static_cast<int>(ClampFraction(fraction) * 100.0);
	g_progress.store(percent);
}


void ResetProgressLocked() {
	g_portion_start = 0.0;
	g_portion_size = 0.0;
	SetProgressFractionLocked(0.0);
}

void BeginProgressSegmentLocked(double portion) {
	g_portion_start += g_portion_size;
	if (portion + g_portion_start > 1.0) {
		portion = 1.0 - g_portion_start;
	}
	if (portion < 0.0) {
		portion = 0.0;
	}
	g_portion_size = portion;
	SetProgressFractionLocked(g_portion_start);
}

void SetSegmentProgressLocked(double fraction) {
	SetProgressFractionLocked(g_portion_start + g_portion_size * ClampFraction(fraction));
}

void ResetSessionLocked(const std::string& path) {
	g_log_cache.clear();
	g_log_start_offset = 0;
	g_last_error.clear();
	g_active_path = path;
	g_wipe_cache.store(0);
	g_last_result.store(0);
	ResetProgressLocked();
	const std::string log_path = Paths::Get().temporary_log_file();
	if (!log_path.empty()) {
		unlink(log_path.c_str());
	}
	const std::string install_path = Paths::Get().temporary_install_file();
	if (!install_path.empty()) {
		unlink(install_path.c_str());
	}
	const std::string binary_path = Paths::Get().temporary_update_binary();
	if (!binary_path.empty()) {
		unlink(binary_path.c_str());
	}
}

bool ReadDigestFile(const std::string& path, std::string* digest_value) {
	std::string content;
	if (!ReadFileToString(path, &content)) {
		return false;
	}
	std::vector<std::string> tokens = SplitWhitespace(Trim(content));
	for (const std::string& token : tokens) {
		std::string trimmed = Trim(token);
		if (!trimmed.empty()) {
			*digest_value = ToLowerAscii(trimmed);
			return true;
		}
	}
	return false;
}

bool CheckDigest(const std::string& package_path, std::string* error_message) {
	struct DigestCandidate {
		const char* suffix;
		bool use_sha256;
	};
	static const DigestCandidate kCandidates[] = {
		{".sha2", true},
		{".sha256", true},
		{".md5", false},
		{".md5sum", false},
	};

	for (const DigestCandidate& candidate : kCandidates) {
		const std::string digest_path = package_path + candidate.suffix;
		if (access(digest_path.c_str(), F_OK) != 0) {
			continue;
		}

		std::string expected_digest;
		if (!ReadDigestFile(digest_path, &expected_digest)) {
			*error_message = "Failed to read digest file: " + digest_path;
			return false;
		}

		std::string actual_digest;
		if (candidate.use_sha256) {
			if (access("/system/bin/sha256sum", X_OK) == 0) {
				actual_digest = ComputeDigestWithCommand("/system/bin/sha256sum", package_path);
			} else {
				actual_digest = ComputeDigestWithCommand("sha256sum", package_path);
			}
		} else {
			if (access("/system/bin/md5sum", X_OK) == 0) {
				actual_digest = ComputeDigestWithCommand("/system/bin/md5sum", package_path);
			} else {
				actual_digest = ComputeDigestWithCommand("md5sum", package_path);
			}
		}
		if (actual_digest.empty()) {
			*error_message = "Failed to compute package digest: " + package_path;
			return false;
		}

		if (ToLowerAscii(actual_digest) != expected_digest) {
			*error_message = "Digest mismatch for package: " + package_path;
			return false;
		}
		return true;
	}

	return true;
}

int SetUpNonAbUpdateCommands(const std::string& package, ZipArchiveHandle zip, int retry_count,
					 int status_fd, std::vector<std::string>* cmd) {
	if (cmd == nullptr) {
		return INSTALL_ERROR;
	}

	std::string binary_name(UPDATE_BINARY_NAME);
	ZipEntry64 binary_entry;
	if (FindEntry(zip, binary_name, &binary_entry) != 0) {
		return INSTALL_CORRUPT;
	}

	const std::string binary_path = Paths::Get().temporary_update_binary();
	unlink(binary_path.c_str());
	int fd = open(binary_path.c_str(), O_CREAT | O_WRONLY | O_TRUNC | O_CLOEXEC, 0755);
	if (fd == -1) {
		return INSTALL_ERROR;
	}

	int32_t error = ExtractEntryToFile(zip, &binary_entry, fd);
	close(fd);
	if (error != 0) {
		return INSTALL_ERROR;
	}

	*cmd = {
		binary_path,
		"3",
		std::to_string(status_fd),
		package,
	};
	if (retry_count > 0) {
		cmd->push_back("retry");
	}
	return 0;
}

bool PackageHasUpdaterBinary(ZipArchiveHandle zip) {
	ZipEntry64 binary_entry;
	return FindEntry(zip, UPDATE_BINARY_NAME, &binary_entry) == 0;
}

void WriteInstallResultFile(int result, const std::string& path, int retry_count) {
	const std::string install_path = Paths::Get().temporary_install_file();
	if (install_path.empty()) {
		return;
	}
	std::vector<std::string> log_header = {
		path,
		result == INSTALL_SUCCESS ? "1" : "0",
		"retry: " + std::to_string(retry_count),
	};
	std::string log_content;
	{
		std::lock_guard<std::mutex> lock(g_mutex);
		for (size_t index = 0; index < log_header.size(); ++index) {
			log_content.append(log_header[index]);
			log_content.push_back('\n');
		}
		log_content.append(g_log_cache);
	}
	WriteStringToFile(install_path, log_content);
}

void UpdateVerificationProgress(float fraction) {
	std::lock_guard<std::mutex> lock(g_mutex);
	SetProgressFractionLocked(ClampFraction(fraction) * kVerificationPortion);
}

int RunInstall(const std::string& package_path) {
	auto package = Package::CreateMemoryPackage(package_path);
	if (!package) {
		return INSTALL_CORRUPT;
	}

	{
		std::lock_guard<std::mutex> lock(g_mutex);
		AppendLogLineLocked("Verifying package signature...");
	}
	const std::vector<Certificate> loaded_keys = LoadKeysFromZipfile("/system/etc/security/otacerts.zip");
	if (!loaded_keys.empty()) {
		const int verify_result = verify_file(package.get(), loaded_keys, UpdateVerificationProgress);
		std::lock_guard<std::mutex> lock(g_mutex);
		if (verify_result == VERIFY_SUCCESS) {
			AppendLogLineLocked("Zip signature verified.");
		} else {
			AppendLogLineLocked("Signature verification failed, continuing with compatibility checks.");
		}
	} else {
		std::lock_guard<std::mutex> lock(g_mutex);
		AppendLogLineLocked("No OTA certificates found, skipping signature verification.");
	}

	ZipArchiveHandle zip = package->GetZipArchiveHandle();
	if (!zip) {
		return INSTALL_CORRUPT;
	}

	if (!verify_package_compatibility(zip)) {
		std::lock_guard<std::mutex> lock(g_mutex);
		SetErrorLocked("Package compatibility verification failed.");
		return INSTALL_CORRUPT;
	}

	int pipe_fds[2] = {-1, -1};
	if (pipe(pipe_fds) != 0) {
		std::lock_guard<std::mutex> lock(g_mutex);
		SetErrorLocked("Failed to create updater pipe.");
		return INSTALL_ERROR;
	}

	std::vector<std::string> args;
	const bool is_ab = !PackageHasUpdaterBinary(zip);
	const int setup_result = is_ab ? abupdate_binary_command(package_path.c_str(), 0, pipe_fds[1], &args)
					      : SetUpNonAbUpdateCommands(package_path, zip, 0, pipe_fds[1], &args);
	if (setup_result != 0) {
		close(pipe_fds[0]);
		close(pipe_fds[1]);
		std::lock_guard<std::mutex> lock(g_mutex);
		SetErrorLocked("Failed to prepare updater command. setup_result=" + std::to_string(setup_result));
		return setup_result;
	}

	// Convert args before fork to avoid heap allocation in the child,
	// which can deadlock if another thread held the malloc lock during fork.
	std::vector<char*> chr_args = StringVectorToNullTerminatedArray(&args);

	pid_t pid = fork();
	if (pid == -1) {
		close(pipe_fds[0]);
		close(pipe_fds[1]);
		std::lock_guard<std::mutex> lock(g_mutex);
		SetErrorLocked("Failed to fork updater process.");
		return INSTALL_ERROR;
	}

	if (pid == 0) {
		// === 子进程 ===
		// 行为对齐 TWRP install.cpp 的原版（umask + 关 pipe 读端 + execv），
		// 仅额外加一个**可开关**的 mount namespace 隔离用于对照实验。
		close(pipe_fds[0]);

		// 唯一保留的修复：独立 mount namespace + 把根置为 slave，
		// 防止 Magisk 的 umount 操作通过共享 namespace 反噬父进程。
		// 开关：父进程通过 `touch /tmp/tw_ffi_no_unshare` 关闭本隔离用于对照实验。
		if (access("/tmp/tw_ffi_no_unshare", F_OK) != 0) {
			if (unshare(CLONE_NEWNS) == 0) {
				mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
			}
		}

		umask(022);
		execv(chr_args[0], chr_args.data());
		fprintf(stdout, "E:Can't run %s (%s)\n", chr_args[0], strerror(errno));
		_exit(EXIT_FAILURE);
	}

	close(pipe_fds[1]);
	char buffer[1024];
	FILE* from_child = fdopen(pipe_fds[0], "r");
	bool retry_update = false;
	int local_wipe_cache = 0;

	while (from_child != nullptr && fgets(buffer, sizeof(buffer), from_child) != nullptr) {
		std::string line(buffer);
		size_t space = line.find_first_of(" \n");
		std::string command(line.substr(0, space));
		if (command.empty()) {
			continue;
		}
		std::string command_args = space == std::string::npos ? std::string() : Trim(line.substr(space));

		if (command == "progress") {
			std::vector<std::string> tokens = SplitWhitespace(command_args);
			double fraction = 0.0;
			if (tokens.size() == 2 && ParseDoubleString(tokens[0], &fraction)) {
				std::lock_guard<std::mutex> lock(g_mutex);
				BeginProgressSegmentLocked(ClampFraction(fraction) * (1.0 - kVerificationPortion));
			}
		} else if (command == "set_progress") {
			double fraction = 0.0;
			if (ParseDoubleString(command_args, &fraction)) {
				std::lock_guard<std::mutex> lock(g_mutex);
				SetSegmentProgressLocked(fraction);
			}
		} else if (command == "ui_print") {
			std::lock_guard<std::mutex> lock(g_mutex);
			AppendLogLineLocked(command_args);
		} else if (command == "wipe_cache") {
			local_wipe_cache = 1;
			g_wipe_cache.store(1);
			std::lock_guard<std::mutex> lock(g_mutex);
			AppendLogLineLocked("Updater requested cache wipe.");
		} else if (command == "retry_update") {
			retry_update = true;
		} else if (command == "log") {
			std::lock_guard<std::mutex> lock(g_mutex);
			AppendLogLineLocked(command_args);
		}
	}

	if (from_child != nullptr) {
		fclose(from_child);
	}

	int status = 0;
	pid_t wait_ret = waitpid(pid, &status, 0);
	(void)wait_ret;

	if (retry_update) {
		return INSTALL_RETRY;
	}
	if (WIFEXITED(status)) {
		if (WEXITSTATUS(status) != EXIT_SUCCESS) {
			std::lock_guard<std::mutex> lock(g_mutex);
			SetErrorLocked("Updater exited with code " + std::to_string(WEXITSTATUS(status)));
			return INSTALL_ERROR;
		}
	} else if (WIFSIGNALED(status)) {
		std::lock_guard<std::mutex> lock(g_mutex);
		SetErrorLocked("Updater killed by signal " + std::to_string(WTERMSIG(status)));
		return INSTALL_ERROR;
	}

	if (local_wipe_cache != 0) {
		std::lock_guard<std::mutex> lock(g_mutex);
		AppendLogLineLocked("Updater requested cache wipe; deferred to caller.");
	}

	std::lock_guard<std::mutex> lock(g_mutex);
	SetProgressFractionLocked(1.0);
	AppendLogLineLocked(FormatInstallResult(INSTALL_SUCCESS));
	return INSTALL_SUCCESS;
}

void InstallWorker(std::string package_path, bool check_digest) {
	int result = INSTALL_ERROR;
	{
		std::lock_guard<std::mutex> lock(g_mutex);
		ResetSessionLocked(package_path);
		AppendLogLineLocked("Installing zip file '" + package_path + "'");
	}

	if (check_digest && !package_path.empty() && package_path[0] != '@') {
		std::string digest_error;
		if (!CheckDigest(package_path, &digest_error)) {
			std::lock_guard<std::mutex> lock(g_mutex);
			SetErrorLocked(digest_error);
			result = INSTALL_CORRUPT;
			goto finish;
		}
		std::lock_guard<std::mutex> lock(g_mutex);
		AppendLogLineLocked("Digest check passed.");
	}

	result = RunInstall(package_path);

finish:
	WriteInstallResultFile(result, package_path, 0);
	g_last_result.store(result);
	g_state.store(result == INSTALL_SUCCESS ? TW_INSTALL_STATE_SUCCESS : TW_INSTALL_STATE_FAILED);
	g_thread_running.store(false);
}

}  // namespace

int Init() {
	std::lock_guard<std::mutex> lock(g_mutex);
	if (Paths::Get().temporary_log_file().empty()) {
		Paths::Get().set_temporary_log_file("/tmp/recovery.log");
	}
	if (Paths::Get().temporary_install_file().empty()) {
		Paths::Get().set_temporary_install_file("/tmp/last_install");
	}
	if (Paths::Get().temporary_update_binary().empty()) {
		Paths::Get().set_temporary_update_binary("/tmp/update-binary");
	}
	ResetSessionLocked(std::string());
	// === 构建版本标记：每次 Init 必写一行，确认设备上跑的是新 .so ===
	// 用一个手写常量代替 __DATE__/__TIME__（被 -Werror,-Wdate-time 拦下了）。
	// 每次改这里递增一下就能区分新旧 .so。
	AppendLogLineLocked("[ffi] tw_install_core Init() build_tag=twrp_ffi-r8-min");
	g_state.store(TW_INSTALL_STATE_IDLE);
	return 0;
}

int SetPaths(const char* log_path, const char* install_file_path, const char* update_binary_path) {
	std::lock_guard<std::mutex> lock(g_mutex);
	if (g_thread_running.load()) {
		return -EBUSY;
	}
	if (log_path != nullptr && log_path[0] != '\0') {
		Paths::Get().set_temporary_log_file(log_path);
	}
	if (install_file_path != nullptr && install_file_path[0] != '\0') {
		Paths::Get().set_temporary_install_file(install_file_path);
	}
	if (update_binary_path != nullptr && update_binary_path[0] != '\0') {
		Paths::Get().set_temporary_update_binary(update_binary_path);
	}
	return 0;
}

int StartZip(const char* path, bool check_digest) {
	if (path == nullptr || path[0] == '\0') {
		return -EINVAL;
	}
	if (access(path, F_OK) != 0) {
		return -ENOENT;
	}
	if (g_thread_running.exchange(true)) {
		return -EBUSY;
	}
	{
		std::lock_guard<std::mutex> lock(g_mutex);
		AppendLogLineLocked(std::string("[ffi] StartZip path=") + path +
				" check_digest=" + (check_digest ? "1" : "0"));
	}
	g_state.store(TW_INSTALL_STATE_RUNNING);
	std::thread(InstallWorker, std::string(path), check_digest).detach();
	return 0;
}

int GetState() {
	return g_state.load();
}

int GetProgress() {
	return g_progress.load();
}

int GetWipeCache() {
	return g_wipe_cache.load();
}

int ReadLog(uint64_t offset, char* out_value, size_t out_len, uint64_t* out_next_offset) {
	if (out_next_offset == nullptr) {
		return -EINVAL;
	}
	std::lock_guard<std::mutex> lock(g_mutex);
	uint64_t start_offset = g_log_start_offset;
	uint64_t end_offset = g_log_start_offset + g_log_cache.size();
	uint64_t effective_offset = offset;
	if (effective_offset < start_offset) {
		effective_offset = start_offset;
	}
	if (effective_offset > end_offset) {
		effective_offset = end_offset;
	}
	int result = CopyStringSliceOut(g_log_cache, static_cast<size_t>(effective_offset - start_offset), out_value, out_len);
	if (result != 0) {
		// 注意：即便失败，也把"下次该从哪里读"写回去，避免调用方死循环。
		// - ENOSPC 时回写 effective_offset，调用方放大 buffer 重试同一段；
		// - 其他错误时回写当前 end_offset 之后的位置（保守起见仍给 effective_offset）。
		*out_next_offset = effective_offset;
		return result;
	}
	*out_next_offset = end_offset;
	return 0;
}

int GetLastError(char* out_value, size_t out_len) {
	std::lock_guard<std::mutex> lock(g_mutex);
	return TwCopyStringOut(g_last_error, out_value, out_len);
}

int GetLastResult() {
	return g_last_result.load();
}

int ResetSession() {
	if (g_thread_running.load()) {
		return -EBUSY;
	}
	std::lock_guard<std::mutex> lock(g_mutex);
	ResetSessionLocked(std::string());
	g_state.store(TW_INSTALL_STATE_IDLE);
	return 0;
}

}  // namespace twinstallcore