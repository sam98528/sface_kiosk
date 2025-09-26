// 파일: lib/dslr_camera_screen.dart
// 목적: EDSDK 네이티브 플러그인(MethodChannel: 'sface_kiosk/camera')과 직접 연동
//      - 카메라 연결/해제
//      - 라이브뷰 시작/정지 (현재 단계: 프레임 UI 미표시, QR 감지 콜백(onQrDetected)만 처리)
//      - 모든 네이티브 호출은 try/catch로 안전 처리
//
// 버튼 동작 요약:
//  [카메라 연결] -> edsdkInit -> connectCamera
//  [라이브 뷰 시작] -> startLiveView (QR 감지시 onQrDetected로 콜백)
//  [연결 해제] -> (live 중이면 stopLiveView) -> disconnectCamera -> edsdkTerm

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DSLRCameraScreen extends StatefulWidget {
  const DSLRCameraScreen({super.key});

  @override
  State<DSLRCameraScreen> createState() => _DSLRCameraScreenState();
}

class _DSLRCameraScreenState extends State<DSLRCameraScreen> {
  // 네이티브 플러그인과 통신하는 채널 이름(플러그인 코드와 동일해야 함)
  static const MethodChannel _ch = MethodChannel('sface_kiosk/edsdk');

  bool _isConnecting = false; // 연결 시도 중 로딩 표시
  bool _isConnected = false; // 카메라 세션 연결 상태
  bool _isLive = false; // 라이브뷰 실행 상태
  String _statusMessage = '카메라 연결을 시작하려면 아래 버튼을 누르세요';
  String _cameraName = 'Canon EOS 50D / 30D'; // 표시용(실제 모델 조회는 추후 확장)

  @override
  void initState() {
    super.initState();

    // 네이티브 → Dart 역방향 호출 처리
    // 현재는 QR 감지 기능이 비활성화됨 (추후 구현 예정)
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'onQrDetected') {
        final text = (call.arguments ?? '') as String;
        if (!mounted) return;
        // QR 감지 시 스낵바 + 간단 다이얼로그 (또는 화면 전환)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR 감지: $text')));
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('QR 인식 완료'),
            content: Text('인식된 QR 값:\n$text'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    });
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera Icon
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: (_isLive || _isConnected)
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 80,
                color: _isLive
                    ? Colors
                          .blue // 라이브뷰 ON이면 파란색
                    : _isConnected
                    ? Colors
                          .green // 연결만 된 상태
                    : Colors.grey, // 미연결
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLive
                          ? '라이브뷰는 동작 중입니다. QR 인식 시 onQrDetected 콜백으로 이벤트가 도착합니다.'
                          : 'EDSDK 기본 연결 기능이 구현되었습니다. 라이브뷰 및 QR 인식은 추후 구현 예정입니다.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
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

  // ===========================
  // 네이티브 호출부
  // ===========================

  /// 카메라 연결 플로우:
  /// 1) EDSDK 초기화 (edsdkInit)
  /// 2) 카메라 개수 확인 (getCameraCount)
  Future<void> _connectCamera() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = '카메라 연결을 시도하고 있습니다...';
    });

    try {
      // EDSDK 초기화
      final okInit = await _ch.invokeMethod<bool>('edsdkInit') ?? false;
      if (!okInit) {
        throw PlatformException(
          code: 'INIT_FAIL',
          message: 'EDSDK 초기화 실패(EDSDK.dll 로드 실패 가능)',
        );
      }

      // 카메라 개수 확인
      final cameraCount = await _ch.invokeMethod<int>('getCameraCount') ?? 0;
      if (cameraCount == 0) {
        throw PlatformException(
          code: 'NO_CAMERA',
          message: '연결된 카메라가 없습니다(케이블/전원/드라이버 확인)',
        );
      }

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _statusMessage = '카메라가 성공적으로 연결되었습니다! ($cameraCount개 감지)';
        _cameraName = 'Canon EOS (세션 연결됨)';
      });
    } on PlatformException catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage = '오류: ${e.message ?? e.code}';
      });
      _showErrorSnack('카메라 연결 실패: ${e.message ?? e.code}');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage = '예기치 못한 오류: $e';
      });
      _showErrorSnack('카메라 연결 실패: $e');
    }
  }

  /// 라이브 뷰 시작 (startLiveView)
  /// - 현재는 임시로 비활성화 (추후 구현 예정)
  Future<void> _startLiveView() async {
    _showErrorSnack('라이브뷰 기능은 추후 구현 예정입니다.');
    setState(() {
      _isLive = false;
      _statusMessage = '라이브뷰 기능은 추후 구현 예정입니다';
    });
  }

  /// 라이브 뷰 정지 (stopLiveView)
  /// - 현재는 임시로 비활성화 (추후 구현 예정)
  Future<void> _stopLiveView() async {
    setState(() {
      _isLive = false;
      _statusMessage = '라이브뷰가 정지되었습니다';
    });
  }

  /// 연결 해제:
  /// - edsdkTerm (SDK 종료)
  Future<void> _disconnectCamera() async {
    try {
      await _ch.invokeMethod('edsdkTerm');
    } catch (_) {
      // 조용히 무시
    }

    if (!mounted) return;
    setState(() {
      _isLive = false;
      _isConnected = false;
      _statusMessage = '카메라 연결이 해제되었습니다';
      _cameraName = 'Canon EOS 50D / 30D';
    });

    // 2초 뒤 안내 문구 리셋
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _statusMessage = '카메라 연결을 시작하려면 아래 버튼을 누르세요';
      });
    });
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
