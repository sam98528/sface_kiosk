import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'api_result.dart';

final dio = Dio();

class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }
          options.headers['Accept'] = 'application/json';

          // _logger.i('token: $token');
          // _logger.i('headers: ${options.headers}');
          // log('➡️ [${options.method}] ${options.uri}');
          // _logger.i('➡️ [${options.method}] ${options.uri}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          _logger.e('Request URL: ${error.requestOptions.uri}');
          _logger.e('Error Type: ${error.type}');
          if (error.response != null) {
            _logger.e(
              'Response: ${error.response?.statusCode} - ${error.response?.data}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiSuccess(response.data as T);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  ApiError<T> _handleDioError<T>(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        message = error.response?.data?['message'] ?? 'Server error';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error';
        break;
      default:
        message = 'Unknown error';
    }

    return ApiError(message, statusCode: statusCode, originalError: error);
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
