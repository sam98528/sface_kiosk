// native_probe/main.cpp
// Purpose: Minimal EVF (Live View) probe for EDSDK without Flutter.
// - Initialize SDK -> open session -> enable PC LiveView -> download a few EVF frames -> shutdown
// - All logs are English-only.
//
// References (EDSDK API Programming Reference):
//  - Start EVF by setting kEdsPropID_Evf_OutputDevice |= kEdsEvfOutputDevice_PC,
//    then start downloading AFTER property-change notification (we simulate wait/retry). [See Sample10]
//  - Download sequence: EdsCreateMemoryStream -> EdsCreateEvfImageRef -> EdsDownloadEvfImage; 
//    if EDS_ERR_OBJECT_NOTREADY, retry. (kEdsPropID_Evf_OutputDevice docs) 
//  - Error 0x81 = EDS_ERR_DEVICE_BUSY (retry later).

#include <Windows.h>
#include <wincodec.h>
#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include "edsdk_bridge.h"
#include <atomic>
#include <condition_variable>
#include <mutex>

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "windowscodecs.lib")

static const EdsError E_OBJECT_NOTREADY = 0xA102;  // EDS_ERR_OBJECT_NOTREADY (doc: retry)
static const EdsError E_DEVICE_BUSY     = 0x0081;  // EDS_ERR_DEVICE_BUSY    (doc: retry)
static constexpr EdsUInt32 kSaveToHost  = 2; // kEdsSaveTo_Host
static constexpr EdsUInt32 kEvfModeOn   = 1; // EVF on
static constexpr EdsUInt32 kEvfPC       = 2; // kEdsEvfOutputDevice_P

// Optional: quick JPEG size check via WIC (no pixels copied)
static bool DecodeJpegHeader(const uint8_t* data, size_t len, int& outW, int& outH) {
  outW = outH = 0;
  if (!data || !len) return false;
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  bool needUninit = SUCCEEDED(hr);

  IWICImagingFactory* fac = nullptr;
  hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&fac));
  if (FAILED(hr)) { if (needUninit) CoUninitialize(); return false; }

  IWICStream* stream = nullptr;
  hr = fac->CreateStream(&stream);
  if (FAILED(hr)) { fac->Release(); if (needUninit) CoUninitialize(); return false; }

  hr = stream->InitializeFromMemory(const_cast<BYTE*>(reinterpret_cast<const BYTE*>(data)),
                                    static_cast<DWORD>(len));
  if (FAILED(hr)) { stream->Release(); fac->Release(); if (needUninit) CoUninitialize(); return false; }

  IWICBitmapDecoder* dec = nullptr;
  hr = fac->CreateDecoderFromStream(stream, nullptr, WICDecodeMetadataCacheOnDemand, &dec);
  if (FAILED(hr)) { stream->Release(); fac->Release(); if (needUninit) CoUninitialize(); return false; }

  IWICBitmapFrameDecode* frame = nullptr;
  hr = dec->GetFrame(0, &frame);
  if (FAILED(hr)) { dec->Release(); stream->Release(); fac->Release(); if (needUninit) CoUninitialize(); return false; }

  UINT w=0, h=0; frame->GetSize(&w, &h);
  outW = static_cast<int>(w); outH = static_cast<int>(h);

  frame->Release(); dec->Release(); stream->Release(); fac->Release();
  if (needUninit) CoUninitialize();
  return true;
}

static void SleepMs(int ms) { std::this_thread::sleep_for(std::chrono::milliseconds(ms)); }

int main() {
  std::cout << "=== EDSDK Native Probe ===\n";

  // 0) Load EDSDK dynamically through our bridge.
  EdsdkBridge sdk;
  if (!sdk.Load(L"EDSDK.dll")) {
    std::cerr << "[ERR] LoadLibrary failed: EDSDK.dll (check DLL path and bitness)\n";
    return 1;
  }
  std::cout << "[OK] EDSDK.dll loaded.\n";

  // 1) Initialize SDK.
  if (sdk.EdsInitializeSDK() != 0) {
    std::cerr << "[ERR] EdsInitializeSDK failed.\n";
    return 1;
  }
  std::cout << "[OK] EdsInitializeSDK.\n";

  // 2) Get first camera.
  EdsCameraListRef list = nullptr;
  if (sdk.EdsGetCameraList(&list) != 0 || !list) {
    std::cerr << "[ERR] EdsGetCameraList failed.\n";
    sdk.EdsTerminateSDK();
    return 1;
  }
  EdsUInt32 count = 0;
  sdk.EdsGetChildCount(list, &count);
  std::cout << "[OK] Camera count: " << count << "\n";
  if (count == 0) {
    std::cerr << "[ERR] No camera found.\n";
    sdk.EdsRelease(list);
    sdk.EdsTerminateSDK();
    return 1;
  }
  EdsCameraRef cam = nullptr;
  if (sdk.EdsGetChildAtIndex(list, 0, (EdsBaseRef*)&cam) != 0 || !cam) {
    std::cerr << "[ERR] EdsGetChildAtIndex failed.\n";
    sdk.EdsRelease(list);
    sdk.EdsTerminateSDK();
    return 1;
  }
  sdk.EdsRelease(list);
  std::cout << "[OK] Camera acquired.\n";

  // 3) Open session.
  if (sdk.EdsOpenSession(cam) != 0) {
    std::cerr << "[ERR] EdsOpenSession failed.\n";
    sdk.EdsRelease(cam);
    sdk.EdsTerminateSDK();
    return 1;
  }
  std::cout << "[OK] Session opened.\n";

 EdsError err = EDS_ERR_OK;

// Get current Evf_OutputDevice
EdsUInt32 device = 0;
err = sdk.EdsGetPropertyData(cam, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
if (err != EDS_ERR_OK) {
    std::cerr << "[ERR] EdsGetPropertyData(Evf_OutputDevice) failed: 0x"
              << std::hex << (unsigned)err << std::dec << "\n";
} else {
    // Set PC as output device
    device |= kEdsEvfOutputDevice_PC;
    err = sdk.EdsSetPropertyData(cam, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
    if (err != EDS_ERR_OK) {
        std::cerr << "[ERR] EdsSetPropertyData(Evf_OutputDevice=PC) failed: 0x"
                  << std::hex << (unsigned)err << std::dec << "\n";
    } else {
        std::cout << "[OK] Evf_OutputDevice set to PC successfully.\n";
    }
}

// If needed, return err so caller can stop when not OK
if (err != EDS_ERR_OK) {
    sdk.EdsCloseSession(cam);
    sdk.EdsRelease(cam);
    sdk.EdsTerminateSDK();
    return 1;
}

  // 5) EVF frame loop with retry on OBJECT_NOTREADY (0xA102).
  const int frames_to_grab = 20;
  for (int i = 0; i < frames_to_grab; ++i) {
    EdsStreamRef mem = nullptr;
    EdsEvfImageRef evf = nullptr;

    EdsError e = sdk.EdsCreateMemoryStream(0, &mem);
    if (e != 0 || !mem) {
      std::cerr << "[WARN] EdsCreateMemoryStream failed: 0x" << std::hex << (unsigned)e << std::dec << "\n";
      SleepMs(60);
      continue;
    }
    e = sdk.EdsCreateEvfImageRef(mem, &evf);
    if (e != 0 || !evf) {
      std::cerr << "[WARN] EdsCreateEvfImageRef failed: 0x" << std::hex << (unsigned)e << std::dec << "\n";
      sdk.EdsRelease(mem);
      SleepMs(60);
      continue;
    }

    // Retry a few times if OBJECT_NOTREADY.
    const int MAX_DL_TRY = 6;
    int t = 0;
    for (; t < MAX_DL_TRY; ++t) {
      e = sdk.EdsDownloadEvfImage(cam, evf);
      if (e == 0) break;
      if (e == E_OBJECT_NOTREADY || e == E_DEVICE_BUSY) {
        std::cerr << "[INFO] EdsDownloadEvfImage not ready/busy, retry " << (t+1) << "...\n";
        SleepMs(60);
        continue;
      }
      std::cerr << "[WARN] EdsDownloadEvfImage error: 0x" << std::hex << (unsigned)e << std::dec << "\n";
      break;
    }

    if (e == 0) {
      EdsVoid* ptr = nullptr; EdsUInt64 len = 0;
      sdk.EdsGetPointer(mem, &ptr);
      sdk.EdsGetLength(mem, &len);
      std::cout << "[EVF] frame " << i << " size=" << len << " bytes\n";

      int w=0, h=0;
      if (DecodeJpegHeader(reinterpret_cast<uint8_t*>(ptr), static_cast<size_t>(len), w, h)) {
        std::cout << "      jpeg: " << w << "x" << h << "\n";
      }
    }

    if (evf) sdk.EdsRelease(evf);
    if (mem) sdk.EdsRelease(mem);
    SleepMs(50);
  }

  // 6) Disable EVF(PC) and cleanup.
  {
    EdsUInt32 device = 0;
    if (sdk.EdsGetPropertyData(cam, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device) == 0) {
      device &= ~kEdsEvfOutputDevice_PC;
      sdk.EdsSetPropertyData(cam, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
    }
  }

  sdk.EdsCloseSession(cam);
  sdk.EdsRelease(cam);
  sdk.EdsTerminateSDK();
  std::cout << "[DONE] Probe finished.\n";
  return 0;
}
