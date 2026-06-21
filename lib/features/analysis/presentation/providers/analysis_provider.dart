import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/analysis_api_source.dart';
import '../../data/datasources/analysis_remote_source.dart';
import '../../data/repositories/analysis_repository_impl.dart';
import '../../domain/entities/instagram_profile.dart';
import '../../domain/entities/follow_analysis.dart';
import '../../domain/repositories/analysis_repository.dart';

final _analysisRemoteSourceProvider = Provider<AnalysisRemoteSource>((ref) {
  return AnalysisApiSource();
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  final source = ref.watch(_analysisRemoteSourceProvider);
  return AnalysisRepositoryImpl(source);
});

final profileProvider = FutureProvider.family<InstagramProfile, String>((ref, username) {
  return ref.watch(analysisRepositoryProvider).getProfile(username);
});

final followAnalysisProvider = FutureProvider.family<FollowAnalysis, String>((ref, username) {
  return ref.watch(analysisRepositoryProvider).getFollowAnalysis(username);
});

final searchHistoryProvider = FutureProvider<List<InstagramProfile>>((ref) {
  return ref.watch(analysisRepositoryProvider).getSearchHistory();
});

final savedAccountsProvider = FutureProvider<List<InstagramProfile>>((ref) {
  return ref.watch(analysisRepositoryProvider).getSavedAccounts();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

class AnalysisNotifier extends StateNotifier<AsyncValue<InstagramProfile?>> {
  final AnalysisRepository _repository;
  final Ref _ref;

  AnalysisNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> analyzeProfile(String username) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repository.getProfile(username));
    state = result;
    if (result.hasValue) {
      await _repository.saveSearchHistory(result.requireValue);
      _ref.invalidate(searchHistoryProvider);
    }
  }

  void clearResult() {
    state = const AsyncValue.data(null);
  }
}

final analysisNotifierProvider = StateNotifierProvider<AnalysisNotifier, AsyncValue<InstagramProfile?>>((ref) {
  final repository = ref.watch(analysisRepositoryProvider);
  return AnalysisNotifier(repository, ref);
});
