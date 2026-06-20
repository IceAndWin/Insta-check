class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://graph.instagram.com/v18.0';
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int maxRetries = 3;

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
