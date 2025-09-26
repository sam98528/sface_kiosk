#include "edsdk_bridge.h"
#include <iostream>
#include <codecvt>
#include <locale>

EdsdkBridge::~EdsdkBridge() {
  if (dll_) {
    FreeLibrary(dll_);
    dll_ = nullptr;
  }
}

bool EdsdkBridge::Load(const std::wstring& dll_path) {
  dll_ = LoadLibraryW(dll_path.c_str());
  if (!dll_) {
    // print in English; avoid narrow conversion of wchar_t path
    std::cerr << "[ERR] LoadLibraryW failed for EDSDK.dll\n";
    return false;
  }

  auto sym = [this](const char* name) -> FARPROC {
    return GetProcAddress(dll_, name);
  };

  // Bind required symbols (nullptr check is fine; we only hard-require core ones)
  EdsInitializeSDK     = reinterpret_cast<EdsError(*)()>(sym("EdsInitializeSDK"));
  EdsTerminateSDK      = reinterpret_cast<EdsError(*)()>(sym("EdsTerminateSDK"));
  EdsGetCameraList     = reinterpret_cast<EdsError(*)(EdsCameraListRef*)>(sym("EdsGetCameraList"));
  EdsGetChildCount     = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsUInt32*)>(sym("EdsGetChildCount"));
  EdsGetChildAtIndex   = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsInt32, EdsBaseRef*)>(sym("EdsGetChildAtIndex"));
  EdsOpenSession       = reinterpret_cast<EdsError(*)(EdsCameraRef)>(sym("EdsOpenSession"));
  EdsCloseSession      = reinterpret_cast<EdsError(*)(EdsCameraRef)>(sym("EdsCloseSession"));
  EdsRelease           = reinterpret_cast<EdsError(*)(EdsBaseRef)>(sym("EdsRelease"));

  EdsGetPropertyData   = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsUInt32, EdsInt32, EdsUInt32, void*)>(sym("EdsGetPropertyData"));
  EdsSetPropertyData   = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsUInt32, EdsInt32, EdsUInt32, const void*)>(sym("EdsSetPropertyData"));

  EdsCreateMemoryStream= reinterpret_cast<EdsError(*)(EdsUInt64, EdsStreamRef*)>(sym("EdsCreateMemoryStream"));
  EdsCreateEvfImageRef = reinterpret_cast<EdsError(*)(EdsStreamRef, EdsEvfImageRef*)>(sym("EdsCreateEvfImageRef"));
  EdsDownloadEvfImage  = reinterpret_cast<EdsError(*)(EdsCameraRef, EdsEvfImageRef)>(sym("EdsDownloadEvfImage"));
  EdsGetPointer        = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsVoid**)>(sym("EdsGetPointer"));
  EdsGetLength         = reinterpret_cast<EdsError(*)(EdsBaseRef, EdsUInt64*)>(sym("EdsGetLength"));

  EdsSendCommand       = reinterpret_cast<EdsError(*)(EdsCameraRef, EdsUInt32, EdsInt32)>(sym("EdsSendCommand"));
  EdsSendStatusCommand = reinterpret_cast<EdsError(*)(EdsCameraRef, EdsUInt32, EdsUInt32)>(sym("EdsSendStatusCommand"));
  EdsSetPropertyEventHandler = reinterpret_cast<PFN_EdsSetPropertyEventHandler>(GetProcAddress(dll_, "EdsSetPropertyEventHandler"));


  // Hard-require the core ones:
  if (!EdsInitializeSDK || !EdsTerminateSDK || !EdsGetCameraList ||
      !EdsGetChildCount || !EdsGetChildAtIndex || !EdsOpenSession ||
      !EdsCloseSession || !EdsRelease ||
      !EdsGetPropertyData || !EdsSetPropertyData ||
      !EdsCreateMemoryStream || !EdsCreateEvfImageRef ||
      !EdsDownloadEvfImage || !EdsGetPointer || !EdsGetLength) {
    std::cerr << "[ERR] Required EDSDK symbols missing.\n";
    return false;
  }
  // EdsSendCommand/EdsSendStatusCommand can be null (we guard before use)

  return true;
}
