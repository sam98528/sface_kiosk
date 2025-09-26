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

class PrintPreviewDialog extends StatefulWidget {
  final String imageUrl;

  const PrintPreviewDialog({super.key, required this.imageUrl});

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  Uint8List? processedImageBytes;
  bool isProcessing = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> kioskPrintFillNoMargin(
    Uint8List imageBytes, {
    double inchWidth = 6,
    double inchHeight = 4,
  }) async {
    // 1) 대상 프린터 선택 (기본 프린터 또는 이름 힌트로 검색)
    final printers = await Printing.listPrinters();
    Printer? target;

    // 힌트가 없으면 기본 프린터 → 없으면 첫 번째
    target = printers.firstWhere(
      (p) => p.isDefault,
      orElse: () => printers.first,
    );

    // 2) PDF 페이지 포맷: 정확히 6x4 inch, 여백 0
    final PdfPageFormat pageFormat = PdfPageFormat(
      inchWidth * PdfPageFormat.inch,
      inchHeight * PdfPageFormat.inch,
      marginAll: 0,

    );

    // 3) 문서 생성
    final doc = pw.Document();

    // 4) 이미지 로드
    final memImage = pw.MemoryImage(imageBytes);

    // 5) 페이지에 "FILL(cover)"로 이미지를 채움
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Stack(
          children: [
            // FILL: 종이를 가득 채움 (잘림 감수)
            pw.Positioned.fill(child: pw.Image(memImage, fit: pw.BoxFit.cover)),
            // 만약 잘림 없이 전체가 꼭 보여야 하면 BoxFit.contain을 쓰고,
            // 대신 위/아래 또는 좌/우에 여백이 생길 수 있음.
          ],
        ),
      ),
    );
    await Printing.directPrintPdf(
      printer: target, // 특정 프린터로 전송
      format: pageFormat, // 인치 기반 용지 크기(여백 0)
      onLayout: (_) async => doc.save(),
      name: 'kiosk-6x4-fill', // 인쇄 작업 이름(선택)
    );
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
      });

      // 이미지 다운로드
      final Response<List<int>> res = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(res.data ?? <int>[]);
      final img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        throw Exception('이미지를 디코딩할 수 없습니다');
      }

      // 101x152mm (4x6 inch) @ 300DPI = 1200x1800px로 처리
      const int targetW = 1200; // 4 inch * 300 DPI
      const int targetH = 1800; // 6 inch * 300 DPI
      final double targetRatio = targetW / targetH; // 0.667 (세로가 더 긴 비율)
      final double srcRatio = original.width / original.height;

      img.Image cropped;
      if (srcRatio > targetRatio) {
        // 원본이 더 가로로 넓음 → 세로를 기준으로 가로를 크롭
        final int newW = (original.height * targetRatio).round();
        final int x = ((original.width - newW) / 2).round();
        cropped = img.copyCrop(
          original,
          x: x,
          y: 0,
          width: newW,
          height: original.height,
        );
      } else if (srcRatio < targetRatio) {
        // 원본이 더 세로로 긴 → 가로를 기준으로 세로를 크롭
        final int newH = (original.width / targetRatio).round();
        final int y = ((original.height - newH) / 2).round();
        cropped = img.copyCrop(
          original,
          x: 0,
          y: y,
          width: original.width,
          height: newH,
        );
      } else {
        cropped = original;
      }

      // 최종 크기로 리사이즈
      final img.Image resized = img.copyResize(
        cropped,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic,
      );

      // JPEG로 인코딩 (고품질)
      final Uint8List outJpg = Uint8List.fromList(
        img.encodeJpg(resized, quality: 95),
      );

      if (mounted) {
        setState(() {
          processedImageBytes = outJpg;
          isProcessing = false;
        });
      }
    } catch (err) {
      log('Image processing error: $err');
      if (mounted) {
        setState(() {
          errorMessage = '이미지 처리 중 오류가 발생했습니다: $err';
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _printImage() async {
    if (processedImageBytes == null) return;

    try {
      // kioskPrintFillNoMargin 함수를 사용하여 6x4 inch (152x101mm) 크기로 프린트
      await kioskPrintFillNoMargin(
        processedImageBytes!,
        inchWidth: 6, // 6 inch 가로 (152mm)
        inchHeight: 4, // 4 inch 세로 (101mm)
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // 프리뷰 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6x4 inch 크기로 인쇄가 시작되었습니다'),
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
                    '인쇄 미리보기 (101×152mm)',
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
                            Text('이미지를 처리하고 있습니다...'),
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
                              onPressed: _processImage,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : processedImageBytes != null
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
                                  '실제 출력 크기: 101 × 152mm (4 × 6 inch)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          // 프리뷰 이미지 (101:152 비율 유지)
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
                                child: AspectRatio(
                                  aspectRatio: 101 / 152, // 실제 종이 비율
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(
                                      processedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
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
                  if (processedImageBytes != null && !isProcessing) ...[
                    OutlinedButton.icon(
                      onPressed: _processImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 처리'),
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
