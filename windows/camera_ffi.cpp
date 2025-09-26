#include "camera_ffi.h"
#include "../native_probe/edsdk_bridge.h"
#include <iostream>
#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <vector>
#include <chrono>

// Global state
static std::unique_ptr<EdsdkBridge> g_sdk = nullptr;
static EdsCameraRef g_camera = nullptr;
static std::atomic<bool> g_liveview_active{false};
static std::mutex g_frame_mutex;
static std::vector<unsigned char> g_latest_frame;

// Initialize EDSDK and camera
extern "C" __declspec(dllexport) int camera_initialize() {
    try {
        g_sdk = std::make_unique<EdsdkBridge>();

        // Load EDSDK
        if (!g_sdk->Load(L"EDSDK.dll")) {
            std::cerr << "[ERR] Failed to load EDSDK.dll\n";
            return -1;
        }

        // Initialize SDK
        if (g_sdk->EdsInitializeSDK() != 0) {
            std::cerr << "[ERR] EdsInitializeSDK failed\n";
            return -2;
        }

        // Get camera list
        EdsCameraListRef list = nullptr;
        if (g_sdk->EdsGetCameraList(&list) != 0 || !list) {
            std::cerr << "[ERR] EdsGetCameraList failed\n";
            g_sdk->EdsTerminateSDK();
            return -3;
        }

        // Get camera count
        EdsUInt32 count = 0;
        g_sdk->EdsGetChildCount(list, &count);
        if (count == 0) {
            std::cerr << "[ERR] No camera found\n";
            g_sdk->EdsRelease(list);
            g_sdk->EdsTerminateSDK();
            return -4;
        }

        // Get first camera
        if (g_sdk->EdsGetChildAtIndex(list, 0, (EdsBaseRef*)&g_camera) != 0 || !g_camera) {
            std::cerr << "[ERR] EdsGetChildAtIndex failed\n";
            g_sdk->EdsRelease(list);
            g_sdk->EdsTerminateSDK();
            return -5;
        }

        g_sdk->EdsRelease(list);

        // Open session
        if (g_sdk->EdsOpenSession(g_camera) != 0) {
            std::cerr << "[ERR] EdsOpenSession failed\n";
            g_sdk->EdsRelease(g_camera);
            g_camera = nullptr;
            g_sdk->EdsTerminateSDK();
            return -6;
        }

        std::cout << "[OK] Camera initialized successfully\n";
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "[ERR] Exception in camera_initialize: " << e.what() << "\n";
        return -999;
    }
}

// Terminate EDSDK and cleanup
extern "C" __declspec(dllexport) int camera_terminate() {
    try {
        g_liveview_active = false;

        if (g_camera && g_sdk) {
            // Disable EVF
            EdsUInt32 device = 0;
            if (g_sdk->EdsGetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device) == 0) {
                device &= ~kEdsEvfOutputDevice_PC;
                g_sdk->EdsSetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
            }

            g_sdk->EdsCloseSession(g_camera);
            g_sdk->EdsRelease(g_camera);
            g_camera = nullptr;
        }

        if (g_sdk) {
            g_sdk->EdsTerminateSDK();
            g_sdk.reset();
        }

        std::cout << "[OK] Camera terminated successfully\n";
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "[ERR] Exception in camera_terminate: " << e.what() << "\n";
        return -999;
    }
}

// Start live view
extern "C" __declspec(dllexport) int camera_start_liveview() {
    try {
        if (!g_camera || !g_sdk) {
            std::cerr << "[ERR] Camera not initialized\n";
            return -1;
        }

        // Get current EVF output device
        EdsUInt32 device = 0;
        EdsError err = g_sdk->EdsGetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
        if (err != EDS_ERR_OK) {
            std::cerr << "[ERR] EdsGetPropertyData(Evf_OutputDevice) failed: 0x"
                      << std::hex << (unsigned)err << std::dec << "\n";
            return -2;
        }

        // Enable PC output
        device |= kEdsEvfOutputDevice_PC;
        err = g_sdk->EdsSetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
        if (err != EDS_ERR_OK) {
            std::cerr << "[ERR] EdsSetPropertyData(Evf_OutputDevice=PC) failed: 0x"
                      << std::hex << (unsigned)err << std::dec << "\n";
            return -3;
        }

        g_liveview_active = true;
        std::cout << "[OK] Live view started successfully\n";
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "[ERR] Exception in camera_start_liveview: " << e.what() << "\n";
        return -999;
    }
}

// Stop live view
extern "C" __declspec(dllexport) int camera_stop_liveview() {
    try {
        if (!g_camera || !g_sdk) {
            return -1;
        }

        g_liveview_active = false;

        // Disable PC output
        EdsUInt32 device = 0;
        if (g_sdk->EdsGetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device) == 0) {
            device &= ~kEdsEvfOutputDevice_PC;
            g_sdk->EdsSetPropertyData(g_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
        }

        std::cout << "[OK] Live view stopped successfully\n";
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "[ERR] Exception in camera_stop_liveview: " << e.what() << "\n";
        return -999;
    }
}

// Get latest frame
extern "C" __declspec(dllexport) int camera_get_frame(unsigned char** buffer, unsigned long long* size) {
    try {
        if (!g_camera || !g_sdk || !g_liveview_active) {
            return -1;
        }

        if (!buffer || !size) {
            return -2;
        }

        EdsStreamRef mem = nullptr;
        EdsEvfImageRef evf = nullptr;

        // Create memory stream
        EdsError err = g_sdk->EdsCreateMemoryStream(0, &mem);
        if (err != EDS_ERR_OK || !mem) {
            return -3;
        }

        // Create EVF image reference
        err = g_sdk->EdsCreateEvfImageRef(mem, &evf);
        if (err != EDS_ERR_OK || !evf) {
            g_sdk->EdsRelease(mem);
            return -4;
        }

        // Download EVF image with retry logic
        const int MAX_RETRY = 5;
        for (int i = 0; i < MAX_RETRY; i++) {
            err = g_sdk->EdsDownloadEvfImage(g_camera, evf);
            if (err == EDS_ERR_OK) {
                break;
            }
            if (err == 0xA102 || err == 0x0081) { // OBJECT_NOTREADY or DEVICE_BUSY
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                continue;
            }
            // Other error
            break;
        }

        if (err != EDS_ERR_OK) {
            g_sdk->EdsRelease(evf);
            g_sdk->EdsRelease(mem);
            return -5;
        }

        // Get image data
        EdsVoid* ptr = nullptr;
        EdsUInt64 len = 0;
        g_sdk->EdsGetPointer(mem, &ptr);
        g_sdk->EdsGetLength(mem, &len);

        if (!ptr || len == 0) {
            g_sdk->EdsRelease(evf);
            g_sdk->EdsRelease(mem);
            return -6;
        }

        // Allocate buffer for Dart side
        unsigned char* frame_buffer = (unsigned char*)malloc(len);
        if (!frame_buffer) {
            g_sdk->EdsRelease(evf);
            g_sdk->EdsRelease(mem);
            return -7;
        }

        // Copy data
        memcpy(frame_buffer, ptr, len);

        *buffer = frame_buffer;
        *size = len;

        // Cleanup
        g_sdk->EdsRelease(evf);
        g_sdk->EdsRelease(mem);

        return 0;

    } catch (const std::exception& e) {
        std::cerr << "[ERR] Exception in camera_get_frame: " << e.what() << "\n";
        return -999;
    }
}

// Free buffer allocated by camera_get_frame
extern "C" __declspec(dllexport) void camera_free_buffer(unsigned char* buffer) {
    if (buffer) {
        free(buffer);
    }
}