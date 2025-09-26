import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/photogoods/search_photogoods.dart';
import 'print_preview_dialog_simple.dart';

class PhotoDetailDialog extends StatefulWidget {
  final SearchPhotogoods item;
  final String imageUrl;

  const PhotoDetailDialog({
    super.key,
    required this.item,
    required this.imageUrl,
  });

  @override
  State<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<PhotoDetailDialog> {
  int? widthPx;
  int? heightPx;
  int? sizeBytes;

  @override
  void initState() {
    super.initState();
    _loadImageMeta();
    _loadContentLength();
  }

  void _loadImageMeta() {
    final ImageStream stream = NetworkImage(
      widget.imageUrl,
    ).resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      widthPx = info.image.width;
      heightPx = info.image.height;
      if (mounted) setState(() {});
      stream.removeListener(listener!);
    });
    stream.addListener(listener);
  }

  Future<void> _loadContentLength() async {
    try {
      final Response res = await Dio().head(
        widget.imageUrl,
        options: Options(followRedirects: true, validateStatus: (code) => true),
      );
      final String? len = res.headers.value('content-length');
      if (len != null) {
        sizeBytes = int.tryParse(len);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    const int k = 1024;
    if (bytes < k) return '$bytes B';
    final double mb = bytes / (k * k);
    return '${mb.toStringAsFixed(2)} MB';
  }

  String _estimatedPrintSize(int w, int h, {double ppi = 300}) {
    final double widthIn = w / ppi;
    final double heightIn = h / ppi;
    return '${widthIn.toStringAsFixed(2)}" × ${heightIn.toStringAsFixed(2)}" @ ${ppi.toInt()} DPI';
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double maxW = screen.width * 0.9;
    final double maxH = screen.height * 0.8;
    final ThemeData theme = Theme.of(context);

    return Container(
      color: Colors.grey.shade200,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: AspectRatio(
                          aspectRatio:
                              (widthPx != null &&
                                  heightPx != null &&
                                  heightPx! != 0)
                              ? widthPx! / heightPx!
                              : 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Feed ID: ${widget.item.feedsIdx}'),
                                  Text('Member ID: ${widget.item.memIdx}'),
                                  Text('Type: ${widget.item.feedsType}'),
                                  Text('Views: ${widget.item.feedsViewCount}'),
                                  if (widget.item.feedsImgAttach.isNotEmpty)
                                    Text(
                                      'Images: ${widget.item.feedsImgAttach.length}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Image Info',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widthPx != null && heightPx != null)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text('$widthPx×$heightPx px')),
                                Chip(
                                  label: Text(
                                    'AR ${(widthPx! / heightPx!).toStringAsFixed(3)}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _estimatedPrintSize(widthPx!, heightPx!),
                                  ),
                                ),
                                if (sizeBytes != null)
                                  Chip(label: Text(_formatBytes(sizeBytes!))),
                              ],
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(minHeight: 4),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'URL',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    widget.imageUrl,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy URL',
                                  icon: const Icon(Icons.copy),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: widget.imageUrl),
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('URL copied'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                label: const Text('Close'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => _showPrintPreview(),
                                icon: const Icon(Icons.preview),
                                label: const Text('Print Preview'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openPdfExternally(widget.imageUrl),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Open PDF'),
                              ),
                            ],
                          ),
                        ],
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

  void _showPrintPreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) => PrintPreviewDialogSimple(
        imageUrl: widget.imageUrl,
      ),
    );
  }

  Future<void> _executePrintOriginal(String imageUrl) async {
    try {
      final Response<List<int>> res = await Dio().get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(res.data ?? <int>[]);
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      const double ppi = 600.0;
      final double widthPt = decoded.width / ppi * 72.0;
      final double heightPt = decoded.height / ppi * 72.0;
      const double bleedPercent = 0.02;
      final double pageW = widthPt * (1 + bleedPercent * 2);
      final double pageH = heightPt * (1 + bleedPercent * 2);
      final pw.Document pdf = pw.Document();
      final pw.MemoryImage pwImage = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageW, pageH),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) =>
              pw.Positioned.fill(child: pw.Image(pwImage, fit: pw.BoxFit.fill)),
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat f) async => pdf.save());
    } catch (err) {
      log('Print error: $err');
      if (!kIsWeb && Platform.isWindows) {
        try {
          final Response<List<int>> res2 = await Dio().get<List<int>>(
            imageUrl,
            options: Options(
              responseType: ResponseType.bytes,
              headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
            ),
          );
          final Uint8List bytes2 = Uint8List.fromList(res2.data ?? <int>[]);
          await _printOnWindows(bytes2);
          return;
        } catch (_) {}
      }
    }
  }

  Future<void> _printOnWindows(Uint8List bytes) async {
    try {
      final Directory tempDir = Directory.systemTemp;
      final String filePath =
          '${tempDir.path}\\sface_print_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      await Process.run('mspaint', ['/pt', filePath]);
    } catch (err) {
      log('Windows print fallback error: $err');
    }
  }

  Future<void> _printSixByFour(String imageUrl) async {
    try {
      final Response<List<int>> res = await Dio().get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(res.data ?? <int>[]);
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) return;
      // 6x4 in @ 600DPI
      const int targetW = 3600; // 6 * 600
      const int targetH = 2400; // 4 * 600
      final double targetRatio = targetW / targetH; // 1.5
      final double srcRatio = original.width / original.height;
      img.Image cropped;
      if (srcRatio > targetRatio) {
        // too wide → crop width
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
        // too tall → crop height
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
      final img.Image resized = img.copyResize(
        cropped,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic,
      );
      final Uint8List outJpg = Uint8List.fromList(
        img.encodeJpg(resized, quality: 100),
      );
      // Windows: 직접 프린터로 전송 (UI 없이)
      if (Platform.isWindows) {
        final Directory tempDir = Directory.systemTemp;
        final String filePath =
            '${tempDir.path}\\sface_print_6x4_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File file = File(filePath);
        await file.writeAsBytes(outJpg, flush: true);
        // mspaint /pt 로 기본 프린터 무UI 출력
        await Process.run('mspaint', ['/pt', filePath]);
        return;
      }
      // 비윈도우는 PDF로 열기 대체
      await _openPdfExternally(imageUrl);
    } catch (err) {
      log('Print 6x4 error: $err');
    }
  }

  Future<void> _openPdfExternally(String imageUrl) async {
    try {
      final Response<List<int>> res = await Dio().get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(res.data ?? <int>[]);
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      const double ppi = 600.0;
      final double widthPt = decoded.width / ppi * 72.0;
      final double heightPt = decoded.height / ppi * 72.0;
      const double bleedPercent = 0.3;
      final double pageW = widthPt * (1 + bleedPercent * 2);
      final double pageH = heightPt * (1 + bleedPercent * 2);
      final pw.Document pdf = pw.Document();
      final pw.MemoryImage pwImage = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageW, pageH),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) =>
              pw.Positioned.fill(child: pw.Image(pwImage, fit: pw.BoxFit.fill)),
        ),
      );
      final Directory tempDir = Directory.systemTemp;
      final String pdfPath =
          '${tempDir.path}\\sface_preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save(), flush: true);
      if (Platform.isWindows) {
        await Process.run('explorer', [pdfPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [pdfPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [pdfPath]);
      }
    } catch (err) {
      log('Open PDF error: $err');
    }
  }
}
