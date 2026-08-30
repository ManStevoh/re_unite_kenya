import '../../models/catalog.dart';
import '../../models/claim.dart';
import '../../models/enums.dart';
import '../../models/item_report.dart';
import '../../models/messaging.dart';
import '../../models/user.dart';

class AuthResult {
  const AuthResult({required this.user, this.token, this.refreshToken});

  final User user;
  final String? token;
  final String? refreshToken;
}

class SearchQuery {
  const SearchQuery({
    this.q,
    this.type,
    this.categoryId,
    this.hubId,
  });

  final String? q;
  final ReportType? type;
  final String? categoryId;
  final String? hubId;
}

abstract class AppRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register({
    required String name,
    required String displayName,
    required String email,
    required String password,
    String? city,
  });
  Future<void> logout();
  Future<User> me();
  Future<User> updateMe({
    String? displayName,
    String? city,
    String? avatarUrl,
    String? phone,
  });
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  });
  Future<void> verifyEmail(String code);
  Future<void> sendOtp(String phone);
  Future<void> confirmOtp(String phone, String code);
  Future<void> changePassword(String current, String next);

  Future<List<Category>> categories();
  Future<List<Hub>> hubs();
  Future<Hub> hub(String id);

  Future<List<ItemReport>> search(SearchQuery query);
  Future<List<ItemReport>> nearbyTeasers();
  Future<List<ItemReport>> myReports();
  Future<List<ItemReport>> drafts();
  Future<ItemReport> report(String id, {bool ownerView = false});
  Future<ItemReport> createReport(ReportDraft draft);
  Future<ItemReport> updateReport(String id, ReportDraft draft);
  Future<void> submitReport(String id);
  Future<void> closeReport(String id, String reason);

  Future<List<MatchCandidate>> matches({String? reportId});
  Future<Claim> startClaim(String reportId);
  Future<Claim> submitAnswers(String claimId, Map<String, String> answers);
  Future<Claim> uploadEvidence(String claimId, List<String> urls);
  Future<Claim> getClaim(String id);
  Future<List<Claim>> claims();
  Future<Claim> reviewClaim(String id, {required bool accept});
  Future<Claim> requestMoreInfo(String id, String message);
  Future<void> withdrawClaim(String id);

  Future<Handover> setupHandover({
    required String claimId,
    required HandoverType type,
    required String place,
    required DateTime when,
  });
  Future<Handover> getHandover(String id);
  Future<Handover> confirmHandover(String id, {required bool asOwner});

  Future<List<Conversation>> conversations();
  Future<List<Message>> messages(String conversationId);
  Future<Message> sendMessage(String conversationId, String body);

  Future<List<AppNotification>> notifications();
  Future<void> markNotificationRead(String id);
  Future<List<ActivityItem>> activity();

  Future<void> flag({
    required String targetType,
    required String targetId,
    required String reason,
    String? detail,
  });
  Future<void> blockUser(String userId);

  Future<List<CmsArticle>> helpArticles();
  Future<CmsArticle> cms(String slug);
  Future<void> contactSupport(String subject, String body);

  Future<QrTag?> lookupTag(String code);
  Future<void> sendTip(String claimId, String note);

  Future<void> requestDataExport();
  Future<void> deactivate();
  Future<void> deleteAccount();

  Future<List<DeviceSession>> devices();
  Future<void> revokeDevice(String id);
  Future<NotificationPrefs> notificationPrefs();
  Future<void> updateNotificationPrefs(NotificationPrefs prefs);

  Future<ItemReport> createHubIntake(ReportDraft draft, String storageCode);
}
