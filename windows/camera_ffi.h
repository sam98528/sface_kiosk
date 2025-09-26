#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// FFI-compatible function exports
__declspec(dllexport) int camera_initialize();
__declspec(dllexport) int camera_terminate();
__declspec(dllexport) int camera_start_liveview();
__declspec(dllexport) int camera_stop_liveview();
__declspec(dllexport) int camera_get_frame(unsigned char** buffer, unsigned long long* size);
__declspec(dllexport) void camera_free_buffer(unsigned char* buffer);

#ifdef __cplusplus
}
#endif