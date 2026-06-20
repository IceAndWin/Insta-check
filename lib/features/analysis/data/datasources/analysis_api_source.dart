import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analysis_remote_source.dart';
import '../../domain/entities/instagram_profile.dart';
import '../../domain/entities/follow_analysis.dart';

class AnalysisApiSource implements AnalysisRemoteSource {
  final String baseUrl;
  final http.Client _client;

  AnalysisApiSource({this.baseUrl = 'http://10.0.2.2:8000'})
      : _client = http.Client();

  @override
  Future<InstagramProfile> fetchProfile(String username) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/profile/$username'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body));
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
      throw Exception(_extractError(response.body));
    }
    return FollowAnalysis.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body);
      return json['detail'] as String? ?? 'Unknown error';
    } catch (_) {
      return 'Failed to connect to server';
    }
  }

  void dispose() {
    _client.close();
  }
}
