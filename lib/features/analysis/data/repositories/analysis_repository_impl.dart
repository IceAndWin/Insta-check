import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/instagram_profile.dart';
import '../../domain/entities/follow_analysis.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../datasources/analysis_remote_source.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  final AnalysisRemoteSource _remoteSource;

  AnalysisRepositoryImpl(this._remoteSource);

  @override
  Future<InstagramProfile> getProfile(String username) {
    return _remoteSource.fetchProfile(username);
  }

  @override
  Future<FollowAnalysis> getFollowAnalysis(String username, {int amount = 300}) {
    return _remoteSource.fetchFollowAnalysis(username, amount: amount);
  }

  @override
  Future<List<InstagramProfile>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('search_history') ?? [];
    return data.map((e) => InstagramProfile.fromJson(jsonDecode(e))).toList();
  }

  @override
  Future<void> saveSearchHistory(InstagramProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('search_history') ?? [];
    final filtered = data.where((e) {
      final p = InstagramProfile.fromJson(jsonDecode(e));
      return p.username != profile.username;
    }).toList();
    filtered.insert(0, jsonEncode(profile.toJson()));
    if (filtered.length > 20) filtered.removeRange(20, filtered.length);
    await prefs.setStringList('search_history', filtered);
  }

  @override
  Future<void> removeSearchHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('search_history') ?? [];
    final filtered = data.where((e) {
      final p = InstagramProfile.fromJson(jsonDecode(e));
      return p.username != username;
    }).toList();
    await prefs.setStringList('search_history', filtered);
  }

  @override
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  @override
  Future<List<InstagramProfile>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_accounts') ?? [];
    return data.map((e) => InstagramProfile.fromJson(jsonDecode(e))).toList();
  }

  @override
  Future<void> saveAccount(InstagramProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_accounts') ?? [];
    final filtered = data.where((e) {
      final p = InstagramProfile.fromJson(jsonDecode(e));
      return p.username != profile.username;
    }).toList();
    filtered.add(jsonEncode(profile.toJson()));
    await prefs.setStringList('saved_accounts', filtered);
  }

  @override
  Future<void> removeSavedAccount(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_accounts') ?? [];
    final filtered = data.where((e) {
      final p = InstagramProfile.fromJson(jsonDecode(e));
      return p.username != username;
    }).toList();
    await prefs.setStringList('saved_accounts', filtered);
  }
}
