import 'dart:async';
import 'dart:typed_data';
import '../native/camera_ffi.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._internal();

  CameraService._internal();

  final CameraFFI _cameraFFI = CameraFFI.instance;
  Timer? _frameTimer;
  final StreamController<Uint8List> _frameController = StreamController<Uint8List>.broadcast();
  bool _isInitialized = false;
  bool _isLiveviewActive = false;

  /// Stream of JPEG frames from live view
  Stream<Uint8List> get frameStream => _frameController.stream;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized;

  /// Check if live view is active
  bool get isLiveviewActive => _isLiveviewActive;

  /// Initialize camera system
  Future<bool> initialize() async {
    try {
      final result = _cameraFFI.initialize();
      if (result == 0) {
        _isInitialized = true;
        print('[OK] Camera initialized successfully');
        return true;
      } else {
        print('[ERROR] Camera initialization failed with code: $result');
        return false;
      }
    } catch (e) {
      print('[ERROR] Camera initialization exception: $e');
      return false;
    }
  }

  /// Terminate camera system
  Future<bool> terminate() async {
    try {
      await stopLiveview();

      final result = _cameraFFI.terminate();
      if (result == 0) {
        _isInitialized = false;
        print('[OK] Camera terminated successfully');
        return true;
      } else {
        print('[ERROR] Camera termination failed with code: $result');
        return false;
      }
    } catch (e) {
      print('[ERROR] Camera termination exception: $e');
      return false;
    }
  }

  /// Start live view and frame streaming
  Future<bool> startLiveview({int frameRateHz = 10}) async {
    if (!_isInitialized) {
      print('[ERROR] Camera not initialized');
      return false;
    }

    if (_isLiveviewActive) {
      print('[INFO] Live view already active');
      return true;
    }

    try {
      final result = _cameraFFI.startLiveview();
      if (result != 0) {
        print('[ERROR] Start liveview failed with code: $result');
        return false;
      }

      _isLiveviewActive = true;

      // Start frame capture timer with initial delay
      Future.delayed(const Duration(seconds: 1), () {
        if (_isLiveviewActive) {
          _frameTimer = Timer.periodic(
            Duration(milliseconds: (1000 / frameRateHz).round()),
            _captureFrame,
          );
          print('[OK] Frame capture started after 1 second delay');
        }
      });

      print('[OK] Live view started successfully');
      return true;

    } catch (e) {
      print('[ERROR] Start liveview exception: $e');
      return false;
    }
  }

  /// Stop live view and frame streaming
  Future<bool> stopLiveview() async {
    if (!_isLiveviewActive) {
      return true;
    }

    try {
      // Stop frame timer
      _frameTimer?.cancel();
      _frameTimer = null;

      final result = _cameraFFI.stopLiveview();
      _isLiveviewActive = false;

      if (result == 0) {
        print('[OK] Live view stopped successfully');
        return true;
      } else {
        print('[ERROR] Stop liveview failed with code: $result');
        return false;
      }

    } catch (e) {
      print('[ERROR] Stop liveview exception: $e');
      return false;
    }
  }

  /// Capture a single frame (internal method)
  void _captureFrame(Timer timer) {
    if (!_isLiveviewActive) {
      timer.cancel();
      return;
    }

    try {
      final frameData = _cameraFFI.getFrame();
      if (frameData != null && frameData.isNotEmpty) {
        _frameController.add(frameData);
      }
    } catch (e) {
      print('[ERROR] Frame capture exception: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _frameTimer?.cancel();
    _frameController.close();
    if (_isInitialized) {
      terminate();
    }
  }
}