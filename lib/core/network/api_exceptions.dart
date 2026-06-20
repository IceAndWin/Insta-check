class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Unauthorized access']);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Resource not found']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Internal server error']);
}
