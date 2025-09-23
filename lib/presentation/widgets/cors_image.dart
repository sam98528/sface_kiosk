import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CorsImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const CorsImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 웹에서는 CORS 프록시 사용, 다른 플랫폼에서는 직접 로딩
    final String finalUrl = kIsWeb
        ? 'https://cors-anywhere.herokuapp.com/$imageUrl'
        : imageUrl;

    return Image.network(
      finalUrl,
      fit: fit,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      headers: kIsWeb ? {
        'X-Requested-With': 'XMLHttpRequest',
      } : null,
    );
  }
}