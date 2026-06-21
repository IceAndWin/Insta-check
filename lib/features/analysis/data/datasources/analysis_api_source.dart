import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analysis_remote_source.dart';
import '../../domain/entities/instagram_profile.dart';
import '../../domain/entities/follow_analysis.dart';

class ApiException implements Exception {
  final String message;
  final String code;
  final int? retryAfter;

  const ApiException({
    required this.message,
    this.code = 'UNKNOWN',
    this.retryAfter,
  });

  @override
  String toString() => message;
}

class AnalysisApiSource implements AnalysisRemoteSource {
  final String baseUrl;
  final http.Client _client;

  AnalysisApiSource({this.baseUrl = 'https://instacheck-backend-mfm5.onrender.com'})
      : _client = http.Client();

  @override
  Future<InstagramProfile> fetchProfile(String username) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/profile/$username'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw _parseError(response.body, response.statusCode);
    }
    return InstagramProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<FollowAnalysis> fetchFollowAnalysis(String username, {int amount = 300}) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/follow-analysis/$username?amount=$amount'))
        .timeout(const Duration(seconds: 180));
    if (response.statusCode != 200) {
      throw _parseError(response.body, response.statusCode);
    }
    return FollowAnalysis.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  ApiException _parseError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return ApiException(
        message: json['detail'] as String? ?? 'Unknown error',
        code: json['code'] as String? ?? 'UNKNOWN',
        retryAfter: json['retryAfter'] as int?,
      );
    } catch (_) {
      if (statusCode >= 500) {
        return const ApiException(
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );
      }
      return const ApiException(
        message: 'Failed to connect to server',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
