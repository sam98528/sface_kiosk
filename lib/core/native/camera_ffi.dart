import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// C function signatures
typedef CameraInitializeNative = Int32 Function();
typedef CameraInitializeDart = int Function();

typedef CameraTerminateNative = Int32 Function();
typedef CameraTerminateDart = int Function();

typedef CameraStartLiveviewNative = Int32 Function();
typedef CameraStartLiveviewDart = int Function();

typedef CameraStopLiveviewNative = Int32 Function();
typedef CameraStopLiveviewDart = int Function();

typedef CameraGetFrameNative = Int32 Function(Pointer<Pointer<Uint8>>, Pointer<Uint64>);
typedef CameraGetFrameDart = int Function(Pointer<Pointer<Uint8>>, Pointer<Uint64>);

typedef CameraFreeBufferNative = Void Function(Pointer<Uint8>);
typedef CameraFreeBufferDart = void Function(Pointer<Uint8>);

class CameraFFI {
  late final DynamicLibrary _lib;
  late final CameraInitializeDart _initialize;
  late final CameraTerminateDart _terminate;
  late final CameraStartLiveviewDart _startLiveview;
  late final CameraStopLiveviewDart _stopLiveview;
  late final CameraGetFrameDart _getFrame;
  late final CameraFreeBufferDart _freeBuffer;

  static CameraFFI? _instance;

  CameraFFI._internal() {
    // Load the native library
    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('camera_ffi.dll');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Bind functions
    _initialize = _lib
        .lookup<NativeFunction<CameraInitializeNative>>('camera_initialize')
        .asFunction();

    _terminate = _lib
        .lookup<NativeFunction<CameraTerminateNative>>('camera_terminate')
        .asFunction();

    _startLiveview = _lib
        .lookup<NativeFunction<CameraStartLiveviewNative>>('camera_start_liveview')
        .asFunction();

    _stopLiveview = _lib
        .lookup<NativeFunction<CameraStopLiveviewNative>>('camera_stop_liveview')
        .asFunction();

    _getFrame = _lib
        .lookup<NativeFunction<CameraGetFrameNative>>('camera_get_frame')
        .asFunction();

    _freeBuffer = _lib
        .lookup<NativeFunction<CameraFreeBufferNative>>('camera_free_buffer')
        .asFunction();
  }

  static CameraFFI get instance {
    _instance ??= CameraFFI._internal();
    return _instance!;
  }

  /// Initialize the camera system
  /// Returns 0 on success, negative on error
  int initialize() {
    try {
      return _initialize();
    } catch (e) {
      print('[ERROR] Camera initialize failed: $e');
      return -999;
    }
  }

  /// Terminate the camera system
  /// Returns 0 on success, negative on error
  int terminate() {
    try {
      return _terminate();
    } catch (e) {
      print('[ERROR] Camera terminate failed: $e');
      return -999;
    }
  }

  /// Start live view
  /// Returns 0 on success, negative on error
  int startLiveview() {
    try {
      return _startLiveview();
    } catch (e) {
      print('[ERROR] Camera start liveview failed: $e');
      return -999;
    }
  }

  /// Stop live view
  /// Returns 0 on success, negative on error
  int stopLiveview() {
    try {
      return _stopLiveview();
    } catch (e) {
      print('[ERROR] Camera stop liveview failed: $e');
      return -999;
    }
  }

  /// Get a frame from live view
  /// Returns null on error, Uint8List on success (JPEG data)
  Uint8List? getFrame() {
    try {
      final bufferPtr = calloc<Pointer<Uint8>>();
      final sizePtr = calloc<Uint64>();

      final result = _getFrame(bufferPtr, sizePtr);

      if (result != 0) {
        calloc.free(bufferPtr);
        calloc.free(sizePtr);
        return null;
      }

      final buffer = bufferPtr.value;
      final size = sizePtr.value;

      if (buffer == nullptr || size == 0) {
        calloc.free(bufferPtr);
        calloc.free(sizePtr);
        return null;
      }

      // Copy data to Dart
      final frameData = Uint8List(size);
      for (int i = 0; i < size; i++) {
        frameData[i] = buffer[i];
      }

      // Free native buffer
      _freeBuffer(buffer);
      calloc.free(bufferPtr);
      calloc.free(sizePtr);

      return frameData;

    } catch (e) {
      print('[ERROR] Camera get frame failed: $e');
      return null;
    }
  }
}