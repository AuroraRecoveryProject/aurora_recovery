#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TwrpVideoPlayer TwrpVideoPlayer;

/* Native implementation API. */
TwrpVideoPlayer* tvp_create(const char* path);
void tvp_destroy(TwrpVideoPlayer* player);

int tvp_play(TwrpVideoPlayer* player);
int tvp_pause(TwrpVideoPlayer* player);
int tvp_seek(TwrpVideoPlayer* player, int64_t position_ms);
int tvp_set_aw_volume(TwrpVideoPlayer* player, int aw_volume);

int32_t tvp_get_width(TwrpVideoPlayer* player);
int32_t tvp_get_height(TwrpVideoPlayer* player);
int64_t tvp_get_duration_ms(TwrpVideoPlayer* player);
int64_t tvp_get_position_ms(TwrpVideoPlayer* player);
int64_t tvp_get_file_size_bytes(TwrpVideoPlayer* player);
int64_t tvp_get_bitrate_bps(TwrpVideoPlayer* player);
int tvp_is_playing(TwrpVideoPlayer* player);
int tvp_has_new_frame(TwrpVideoPlayer* player);
const uint8_t* tvp_get_frame(TwrpVideoPlayer* player);
double tvp_get_fps(TwrpVideoPlayer* player);
const char* tvp_get_video_codec(TwrpVideoPlayer* player);
const char* tvp_get_audio_codec(TwrpVideoPlayer* player);
const char* tvp_last_error(void);

/* Dart FFI/exported ABI. Generate bindings from these vp_* symbols. */
typedef TwrpVideoPlayer VideoPlayerHandle;

VideoPlayerHandle* vp_create(const char* path);
void vp_destroy(VideoPlayerHandle* player);

int vp_play(VideoPlayerHandle* player);
int vp_pause(VideoPlayerHandle* player);
int vp_seek(VideoPlayerHandle* player, int64_t position_ms);
int vp_set_aw_volume(VideoPlayerHandle* player, int aw_volume);

int32_t vp_get_width(VideoPlayerHandle* player);
int32_t vp_get_height(VideoPlayerHandle* player);
int64_t vp_get_duration_ms(VideoPlayerHandle* player);
int64_t vp_get_position_ms(VideoPlayerHandle* player);
int64_t vp_get_file_size_bytes(VideoPlayerHandle* player);
int64_t vp_get_bitrate_bps(VideoPlayerHandle* player);
int vp_is_playing(VideoPlayerHandle* player);
int vp_has_new_frame(VideoPlayerHandle* player);
const uint8_t* vp_get_frame(VideoPlayerHandle* player);
double vp_get_fps(VideoPlayerHandle* player);
const char* vp_get_video_codec(VideoPlayerHandle* player);
const char* vp_get_audio_codec(VideoPlayerHandle* player);
const char* vp_last_error(void);

#ifdef __cplusplus
}
#endif
