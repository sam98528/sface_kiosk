#pragma once
#include <Windows.h>
#include <cstdint>
#include <string>

// ---- Canon EDSDK basic typedefs ----
using EdsError       = uint32_t;
using EdsUInt32      = uint32_t;
using EdsUInt64      = uint64_t;
using EdsInt32       = int32_t;
using EdsBaseRef     = void*;
using EdsCameraListRef = void*;
using EdsCameraRef     = void*;
using EdsStreamRef     = void*;
using EdsEvfImageRef   = void*;
using EdsVoid          = void*;
using EdsPropertyEventHandler = EdsError(__stdcall*)(EdsUInt32 inEvent, EdsUInt32 inPropertyID, EdsUInt32 inParam, EdsBaseRef inContext);
using PFN_EdsSetPropertyEventHandler = EdsError(__stdcall*)(EdsCameraRef, EdsPropertyEventHandler, EdsBaseRef);



// ---- Properties / constants we use ----
constexpr EdsUInt32 kEdsPropID_Evf_OutputDevice = 0x00000500;
constexpr EdsUInt32 kEdsEvfOutputDevice_PC      = 0x00000002;

constexpr EdsUInt32 kEdsPropID_SaveTo           = 0x0000000B;
constexpr EdsUInt32 kEdsSaveTo_Camera           = 0;
constexpr EdsUInt32 kEdsSaveTo_Host             = 2;

constexpr EdsUInt32 kEdsPropID_Capacity         = 0x0000000A;

// Camera status commands (UILock/UIUnLock)
constexpr EdsUInt32 kEdsCameraStatusCommand_UILock   = 0x00000001;
constexpr EdsUInt32 kEdsCameraStatusCommand_UIUnLock = 0x00000002;

// Shutter button command (optional wake)
constexpr EdsUInt32 kEdsCameraCommand_PressShutterButton = 0x00000004;
constexpr EdsInt32  kEdsCameraCommand_ShutterButton_OFF     = 0;
constexpr EdsInt32  kEdsCameraCommand_ShutterButton_Halfway = 1;

// Capacity structure (required when SaveTo=Host on some bodies)
struct EdsCapacity {
  EdsUInt32 NumberOfFreeClusters;
  EdsUInt32 BytesPerSector;
  EdsUInt32 Reset; // 1 to (re)initialize
};
static constexpr EdsUInt32 kEdsPropID_Evf_Mode = 0x00000500;
// ---- EDSDK error codes (subset we use) ----
static constexpr EdsError EDS_ERR_OK             = 0x00000000;
static constexpr EdsError EDS_ERR_DEVICE_BUSY    = 0x00000081; // same as 0x81
static constexpr EdsError EDS_ERR_OBJECT_NOTREADY= 0x0000A102; // same as 0xA102


// ---- Bridge class: dynamically loads needed EDSDK symbols ----
class EdsdkBridge {
public:
  EdsdkBridge() : dll_(nullptr) {}
  ~EdsdkBridge();

  // Load EDSDK.dll (must be in DLL search path)
  bool Load(const std::wstring& dll_path);

  // Core API
  EdsError (*EdsInitializeSDK)();
  EdsError (*EdsTerminateSDK)();
  EdsError (*EdsGetCameraList)(EdsCameraListRef*);
  EdsError (*EdsGetChildCount)(EdsBaseRef, EdsUInt32*);
  EdsError (*EdsGetChildAtIndex)(EdsBaseRef, EdsInt32, EdsBaseRef*);
  EdsError (*EdsOpenSession)(EdsCameraRef);
  EdsError (*EdsCloseSession)(EdsCameraRef);
  EdsError (*EdsRelease)(EdsBaseRef);

  // Properties / streams
  EdsError (*EdsGetPropertyData)(EdsBaseRef, EdsUInt32, EdsInt32, EdsUInt32, void*);
  EdsError (*EdsSetPropertyData)(EdsBaseRef, EdsUInt32, EdsInt32, EdsUInt32, const void*);

  // EVF (Live View)
  EdsError (*EdsCreateMemoryStream)(EdsUInt64, EdsStreamRef*);
  EdsError (*EdsCreateEvfImageRef)(EdsStreamRef, EdsEvfImageRef*);
  EdsError (*EdsDownloadEvfImage)(EdsCameraRef, EdsEvfImageRef);
  EdsError (*EdsGetPointer)(EdsBaseRef, EdsVoid**);
  EdsError (*EdsGetLength)(EdsBaseRef, EdsUInt64*);

  // Commands
  EdsError (*EdsSendCommand)(EdsCameraRef, EdsUInt32, EdsInt32);          // shutter half-press, etc.
  EdsError (*EdsSendStatusCommand)(EdsCameraRef, EdsUInt32, EdsUInt32);
     // UILock/UIUnLock
  PFN_EdsSetPropertyEventHandler EdsSetPropertyEventHandler = nullptr;
private:
  HMODULE dll_;
};
