sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiError<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiError(
    this.message, {
    this.statusCode,
    this.originalError,
  });
}

class ApiLoading<T> extends ApiResult<T> {
  const ApiLoading();
}