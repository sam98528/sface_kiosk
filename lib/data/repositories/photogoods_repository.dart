import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../../core/constants/api_constants.dart';
import '../../core/providers/providers.dart';
import '../models/photogoods/search_photogoods.dart';

class PhotogoodsRepository {
  final ApiClient _apiClient;

  PhotogoodsRepository(this._apiClient);

  Future<ApiResult<SearchPhotogoodsData>> searchPhotogoods({
    required String query,
    required String page,
    required String limit,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.photogoodsSearchEndpoint(query),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    switch (result) {
      case ApiSuccess<Map<String, dynamic>>(data: final data):
        try {
          // API 응답이 직접 { "data": [...] } 형태이므로 바로 파싱
          final photogoodsData = SearchPhotogoodsData.fromJson(data);
          return ApiSuccess(photogoodsData);
        } catch (e) {
          return ApiError('Failed to parse photogoods data: $e');
        }
      case ApiError<Map<String, dynamic>>(message: final message, statusCode: final statusCode):
        return ApiError(message, statusCode: statusCode);
      case ApiLoading<Map<String, dynamic>>():
        return const ApiLoading();
    }
  }
}

final photogoodsRepositoryProvider = Provider<PhotogoodsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PhotogoodsRepository(apiClient);
});