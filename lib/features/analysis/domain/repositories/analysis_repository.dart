import '../entities/instagram_profile.dart';
import '../entities/follow_analysis.dart';

abstract class AnalysisRepository {
  Future<InstagramProfile> getProfile(String username);
  Future<FollowAnalysis> getFollowAnalysis(String username, {int amount = 300});
  Future<List<InstagramProfile>> getSearchHistory();
  Future<void> saveSearchHistory(InstagramProfile profile);
  Future<void> clearSearchHistory();
  Future<void> removeSearchHistory(String username);
  Future<List<InstagramProfile>> getSavedAccounts();
  Future<void> saveAccount(InstagramProfile profile);
  Future<void> removeSavedAccount(String username);
}
