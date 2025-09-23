import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['SERVER_IP'] ?? 'https://sface.app';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Photogoods Endpoints
  static String photogoodsSearchEndpoint(String query) =>
      '/v1/photogoods/search/$query';
}
