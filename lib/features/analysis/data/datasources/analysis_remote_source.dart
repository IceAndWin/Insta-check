import '../../domain/entities/instagram_profile.dart';
import '../../domain/entities/follow_analysis.dart';

abstract class AnalysisRemoteSource {
  Future<InstagramProfile> fetchProfile(String username);
  Future<FollowAnalysis> fetchFollowAnalysis(String username, {int amount});
}
