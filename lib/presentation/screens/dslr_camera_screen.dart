import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/services/camera_service.dart';

class DSLRCameraScreen extends StatefulWidget {
  const DSLRCameraScreen({super.key});

  @override
  State<DSLRCameraScreen> createState() => _DSLRCameraScreenState();
}

class _DSLRCameraScreenState extends State<DSLRCameraScreen> {
  final CameraService _cameraService = CameraService.instance;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isLive = false;
  String _statusMessage = '카메라 연결을 시작하려면 아래 버튼을 누르세요';
  String _cameraName = 'Canon DSLR Camera';

  @override
  void initState() {
    super.initState();
    // setState 제거 - StreamBuilder가 자동으로 처리
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DSLR 카메라 연결'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLive
          ? StreamBuilder<Uint8List>(
              stream: _cameraService.frameStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                return Stack(
                  children: [
                    // Full Screen Live View
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain, // 전체 화면에 맞춤
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                // Overlay Controls - Top
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE VIEW - ${_cameraName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Floating Action Buttons - Bottom
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: "stop_live",
                        onPressed: _stopLiveView,
                        backgroundColor: Colors.red.withOpacity(0.9),
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text('라이브뷰 정지', style: TextStyle(color: Colors.white)),
                      ),
                      FloatingActionButton.extended(
                        heroTag: "disconnect",
                        onPressed: _disconnectCamera,
                        backgroundColor: Colors.grey.withOpacity(0.9),
                        icon: const Icon(Icons.link_off, color: Colors.white),
                        label: const Text('연결 해제', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                  ],
                );
              },
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera Icon (when not live)
                  Container(
                    width: 400,
                    height: 300,
                    decoration: BoxDecoration(
                      color: (_isConnected)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isConnected ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: _isConnected ? Colors.green : Colors.grey,
                    ),
                  ),

            const SizedBox(height: 40),

            // Camera Name
            Text(
              _isConnected ? '$_cameraName 연결됨' : _cameraName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isLive
                    ? Colors.blue
                    : _isConnected
                    ? Colors.green
                    : Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Status Text
            Text(
              _statusMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            // Connection / Live status
            if (_isConnecting)
              const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text('카메라 연결 중...'),
                ],
              )
            else if (_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (_isLive ? Colors.blue : Colors.green).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: (_isLive ? Colors.blue : Colors.green).withOpacity(
                      0.3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLive ? Icons.play_circle : Icons.check_circle,
                      color: _isLive ? Colors.blue : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLive ? '라이브뷰 실행 중' : '연결 성공',
                      style: TextStyle(
                        color: _isLive ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Action Buttons
            if (!_isConnected && !_isConnecting)
              ElevatedButton.icon(
                onPressed: _connectCamera, // 네이티브 호출로 변경
                icon: const Icon(Icons.link),
                label: const Text('카메라 연결', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else if (_isConnected)
              Column(
                children: [
                  // 라이브 뷰 시작/정지 토글
                  ElevatedButton.icon(
                    onPressed: _isLive ? _stopLiveView : _startLiveView,
                    icon: Icon(_isLive ? Icons.stop : Icons.videocam),
                    label: Text(
                      _isLive ? '라이브 뷰 정지' : '라이브 뷰 시작',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLive ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _disconnectCamera,
                    icon: const Icon(Icons.link_off),
                    label: const Text('연결 해제'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

            const Spacer(),

            // Development Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLive
                          ? 'Canon DSLR 라이브뷰가 실시간으로 스트리밍 중입니다. EDSDK FFI를 통한 네이티브 연동이 완료되었습니다.'
                          : 'Canon EDSDK FFI 통합이 완료되었습니다. 카메라를 연결하여 실시간 라이브뷰를 시작할 수 있습니다.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectCamera() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = '카메라 연결을 시도하고 있습니다...';
    });

    try {
      final success = await _cameraService.initialize();
      if (success) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
          _statusMessage = '카메라가 성공적으로 연결되었습니다!';
          _cameraName = 'Canon DSLR (연결됨)';
        });
      } else {
        throw Exception('카메라 초기화 실패');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage = '카메라 연결 실패: $e';
      });
      _showErrorSnack('카메라 연결 실패: $e');
    }
  }

  Future<void> _startLiveView() async {
    try {
      final success = await _cameraService.startLiveview(frameRateHz: 12);
      if (success) {
        setState(() {
          _isLive = true;
          _statusMessage = '라이브뷰가 시작되었습니다';
        });
      } else {
        throw Exception('라이브뷰 시작 실패');
      }
    } catch (e) {
      setState(() {
        _isLive = false;
        _statusMessage = '라이브뷰 시작 실패: $e';
      });
      _showErrorSnack('라이브뷰 시작 실패: $e');
    }
  }

  Future<void> _stopLiveView() async {
    try {
      final success = await _cameraService.stopLiveview();
      setState(() {
        _isLive = false;
        _statusMessage = success ? '라이브뷰가 정지되었습니다' : '라이브뷰 정지 실패';
      });
    } catch (e) {
      setState(() {
        _isLive = false;
        _statusMessage = '라이브뷰 정지 실패: $e';
      });
      _showErrorSnack('라이브뷰 정지 실패: $e');
    }
  }

  Future<void> _disconnectCamera() async {
    try {
      await _cameraService.terminate();

      if (!mounted) return;
      setState(() {
        _isLive = false;
        _isConnected = false;
        _statusMessage = '카메라 연결이 해제되었습니다';
        _cameraName = 'Canon DSLR Camera';
      });

      // 2초 뒤 안내 문구 리셋
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _statusMessage = '카메라 연결을 시작하려면 아래 버튼을 누르세요';
        });
      });
    } catch (e) {
      _showErrorSnack('카메라 연결 해제 실패: $e');
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
