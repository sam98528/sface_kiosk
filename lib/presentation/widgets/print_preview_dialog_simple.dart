import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintPreviewDialogSimple extends StatefulWidget {
  final String imageUrl;

  const PrintPreviewDialogSimple({super.key, required this.imageUrl});

  @override
  State<PrintPreviewDialogSimple> createState() =>
      _PrintPreviewDialogSimpleState();
}

class _PrintPreviewDialogSimpleState extends State<PrintPreviewDialogSimple> {
  Uint8List? originalImageBytes;
  bool isProcessing = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadImage();
  }

  // 원본 이미지를 다운로드만 하고 처리하지 않음
  Future<void> _downloadImage() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
      });

      // 이미지 다운로드만 함
      final Response<List<int>> res = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(res.data ?? <int>[]);

      // 이미지가 유효한지만 확인
      final img.Image? testImage = img.decodeImage(bytes);
      if (testImage == null) {
        throw Exception('이미지를 디코딩할 수 없습니다');
      }

      // 원본 바이트를 그대로 저장
      if (mounted) {
        setState(() {
          originalImageBytes = bytes;
          isProcessing = false;
        });
      }
    } catch (err) {
      log('Image download error: $err');
      if (mounted) {
        setState(() {
          errorMessage = '이미지 다운로드 중 오류가 발생했습니다: $err';
          isProcessing = false;
        });
      }
    }
  }

  // 기본 프린터 이름을 가져오는 함수
  Future<String?> _getDefaultPrinterName() async {
    try {
      // 방법 1: PowerShell Get-CimInstance 사용 (최신 방법)
      try {
        final ProcessResult psResult = await Process.run('powershell', [
          '-Command',
          'Get-CimInstance -ClassName Win32_Printer | Where-Object {.Default -eq true} | Select-Object -ExpandProperty Name',
        ]);

        if (psResult.exitCode == 0) {
          final String printerName = psResult.stdout.toString().trim();
          if (printerName.isNotEmpty) {
            log(
              'Found default printer via PowerShell Get-CimInstance: $printerName',
            );
            return printerName;
          }
        }
      } catch (e) {
        log('PowerShell Get-CimInstance failed: $e');
      }

      // 방법 2: PowerShell Get-WmiObject 사용 (구버전 호환)
      try {
        final ProcessResult psResult = await Process.run('powershell', [
          '-Command',
          'Get-WmiObject -Class Win32_Printer | Where-Object Default -eq true | Select-Object -ExpandProperty Name',
        ]);

        if (psResult.exitCode == 0) {
          final String printerName = psResult.stdout.toString().trim();
          if (printerName.isNotEmpty) {
            log(
              'Found default printer via PowerShell Get-WmiObject: $printerName',
            );
            return printerName;
          }
        }
      } catch (e) {
        log('PowerShell Get-WmiObject failed: $e');
      }

      // 방법 3: 레지스트리에서 기본 프린터 확인
      try {
        final ProcessResult regResult = await Process.run('reg', [
          'query',
          'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Windows',
          '/v',
          'Device',
        ]);

        if (regResult.exitCode == 0) {
          final String output = regResult.stdout.toString();
          final RegExp devicePattern = RegExp(r'Device\s+REG_SZ\s+(.+)');
          final Match? match = devicePattern.firstMatch(output);
          if (match != null) {
            final String deviceInfo = match.group(1) ?? '';
            // Device 값은 "프린터명,winspool,Ne00:" 형태
            final List<String> parts = deviceInfo.split(',');
            if (parts.isNotEmpty) {
              final String printerName = parts[0].trim();
              log('Found default printer via Registry: $printerName');
              return printerName;
            }
          }
        }
      } catch (e) {
        log('Registry query failed: $e');
      }

      // 방법 4: rundll32.exe로 프린터 목록 가져오기 (최후 수단)
      try {
        final ProcessResult printResult = await Process.run('powershell', [
          '-Command',
          'Get-Printer | Where-Object Type -eq "Local" | Select-Object -First 1 -ExpandProperty Name',
        ]);

        if (printResult.exitCode == 0) {
          final String printerName = printResult.stdout.toString().trim();
          if (printerName.isNotEmpty) {
            log('Found first available printer: $printerName');
            return printerName;
          }
        }
      } catch (e) {
        log('Get-Printer failed: $e');
      }

      log('All methods failed to find default printer');
      return null;
    } catch (e) {
      log('Failed to get default printer: $e');
      return null;
    }
  }

  // IrfanView 설치 경로를 찾는 함수
  Future<String?> _findIrfanViewPath() async {
    final List<String> possiblePaths = [
      'C:\\Program Files\\IrfanView\\i_view64.exe',
      'C:\\Program Files (x86)\\IrfanView\\i_view32.exe',
      'C:\\IrfanView\\i_view64.exe',
      'C:\\IrfanView\\i_view32.exe',
      'C:\\Programs\\IrfanView\\i_view64.exe',
      'C:\\Programs\\IrfanView\\i_view32.exe',
    ];

    for (String path in possiblePaths) {
      final File file = File(path);
      if (await file.exists()) {
        log('Found IrfanView at: $path');
        return path;
      }
    }

    // 레지스트리에서 IrfanView 설치 경로 찾기
    try {
      final ProcessResult regResult = await Process.run('reg', [
        'query',
        'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\IrfanView',
        '/v',
        'InstallLocation',
      ]);

      if (regResult.exitCode == 0) {
        final String output = regResult.stdout.toString();
        final RegExp pathPattern = RegExp(r'InstallLocation\s+REG_SZ\s+(.+)');
        final Match? match = pathPattern.firstMatch(output);
        if (match != null) {
          final String installPath = match.group(1)?.trim() ?? '';
          final List<String> exeNames = ['i_view64.exe', 'i_view32.exe'];

          for (String exeName in exeNames) {
            final String fullPath = '$installPath\\$exeName';
            if (await File(fullPath).exists()) {
              log('Found IrfanView via registry at: $fullPath');
              return fullPath;
            }
          }
        }
      }
    } catch (e) {
      log('Registry query for IrfanView failed: $e');
    }

    return null;
  }

  // IrfanView를 사용한 이미지 프린트
  Future<void> printImageWithIrfanView(Uint8List imageBytes) async {
    try {
      // 1) IrfanView 경로 찾기
      final String? irfanViewPath = await _findIrfanViewPath();

      if (irfanViewPath == null) {
        throw Exception('IrfanView가 설치되어 있지 않습니다');
      }

      // 2) 임시 이미지 파일 생성
      final Directory tempDir = Directory.systemTemp;
      final String filePath =
          '${tempDir.path}\\sface_print_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);

      // 3) 기본 프린터 이름 가져오기
      final String? printerName = await _getDefaultPrinterName();

      ProcessResult result;
      if (printerName != null) {
        // 4) 특정 프린터로 IrfanView 프린트
        result = await Process.run(irfanViewPath, [
          filePath,
          '/print="$printerName"',
        ]);
        log(
          'IrfanView print to specific printer result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}',
        );
      } else {
        // 4) 기본 프린터로 IrfanView 프린트
        result = await Process.run(irfanViewPath, [filePath, '/print']);
        log(
          'IrfanView print to default printer result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}',
        );
      }

      // 잠시 대기 후 임시 파일 삭제
      await Future.delayed(const Duration(seconds: 3));
      try {
        await file.delete();
      } catch (e) {
        log('Failed to delete temp file: $e');
      }
    } catch (e) {
      log('IrfanView print error: $e');
      rethrow;
    }
  }

  // rundll32.exe를 사용한 직접 이미지 프린트
  Future<void> printImageWithRundll32(Uint8List imageBytes) async {
    try {
      // 1) 임시 이미지 파일 생성
      final Directory tempDir = Directory.systemTemp;
      final String filePath =
          '${tempDir.path}\\sface_print_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);

      // 2) 기본 프린터 이름 가져오기
      final String? printerName = await _getDefaultPrinterName();

      if (printerName == null) {
        // 프린터를 찾지 못한 경우 프린터 이름 없이 시도 (기본 프린터 사용)
        log('No printer name found, trying without printer name parameter');
        final ProcessResult result = await Process.run('rundll32.exe', [
          'C:\\WINDOWS\\System32\\shimgvw.dll,ImageView_PrintTo',
          filePath,
          '', // 빈 문자열로 기본 프린터 사용
        ]);

        log(
          'Rundll32 print result (no printer name): exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}',
        );

        // 그래도 실패하면 다른 방법 시도
        if (result.exitCode != 0) {
          log(
            'Trying alternative: opening file with default image viewer for printing',
          );
          // Windows의 기본 이미지 뷰어로 열기 (사용자가 직접 프린트할 수 있음)
          await Process.run('cmd', ['/c', 'start', '/wait', filePath]);
        }
      } else {
        // 3) rundll32.exe로 이미지 프린트
        final ProcessResult result = await Process.run('rundll32.exe', [
          'C:\\WINDOWS\\System32\\shimgvw.dll,ImageView_PrintTo',
          filePath,
          printerName,
        ]);

        log(
          'Rundll32 print result: exitCode=${result.exitCode}, stdout=${result.stdout}, stderr=${result.stderr}',
        );
      }

      // 잠시 대기 후 임시 파일 삭제
      await Future.delayed(const Duration(seconds: 3));
      try {
        await file.delete();
      } catch (e) {
        log('Failed to delete temp file: $e');
      }
    } catch (e) {
      log('Rundll32 print error: $e');
      rethrow;
    }
  }

  Future<void> _printImage() async {
    if (originalImageBytes == null) return;

    try {
      String printMethod = '';

      // 1) IrfanView 방식을 먼저 시도
      try {
        await printImageWithIrfanView(originalImageBytes!);
        printMethod = 'IrfanView';
      } catch (irfanError) {
        log('IrfanView print failed, trying rundll32: $irfanError');

        // 2) IrfanView 실패시 rundll32.exe 방식 시도
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // 프리뷰 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$printMethod로 인쇄가 시작되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (err) {
      log('Print error: $err');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('인쇄 중 오류가 발생했습니다: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double maxW = screen.width * 0.7;
    final double maxH = screen.height * 0.8;
    final ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.print_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '인쇄 미리보기 (6×4 inch)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // 프리뷰 영역
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('이미지를 다운로드하고 있습니다...'),
                          ],
                        ),
                      )
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _downloadImage,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : originalImageBytes != null
                    ? Column(
                        children: [
                          // 실제 크기 비율 안내
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '출력 크기: 6 × 4 inch (152 × 101mm)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          // 프리뷰 이미지 (원본 비율 유지)
                          Expanded(
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(
                                    originalImageBytes!,
                                    fit: BoxFit.contain, // 전체 이미지가 보이도록
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(child: Text('이미지를 불러올 수 없습니다')),
              ),
            ),

            // 액션 버튼들
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  if (originalImageBytes != null && !isProcessing) ...[
                    OutlinedButton.icon(
                      onPressed: _downloadImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 로드'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final String? printerName =
                            await _getDefaultPrinterName();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              printerName != null
                                  ? '기본 프린터: $printerName'
                                  : '기본 프린터를 찾을 수 없습니다',
                            ),
                            backgroundColor: printerName != null
                                ? Colors.blue
                                : Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('프린터 확인'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final String? irfanViewPath =
                            await _findIrfanViewPath();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              irfanViewPath != null
                                  ? 'IrfanView 발견: ${irfanViewPath.split('\\').last}'
                                  : 'IrfanView를 찾을 수 없습니다',
                            ),
                            backgroundColor: irfanViewPath != null
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('IrfanView'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _printImage,
                      icon: const Icon(Icons.print),
                      label: const Text('인쇄하기'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
