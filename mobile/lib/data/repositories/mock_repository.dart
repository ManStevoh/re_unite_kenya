import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../models/catalog.dart';
import '../../models/claim.dart';
import '../../models/enums.dart';
import '../../models/item_report.dart';
import '../../models/messaging.dart';
import '../../models/user.dart';
import '../mock/mock_data.dart';
import 'app_repository.dart';

class MockRepository implements AppRepository {
  MockRepository() {
    reports = seedReports();
    matchList = seedMatches();
    claimList = seedClaims();
    inbox = seedConversations();
    threads = seedMessages();
    notes = seedNotifications();
    feed = seedActivity();
    handovers = [
      Handover(
        id: 'h1',
        claimId: 'c3',
        type: HandoverType.hubPickup,
        status: HandoverStatus.scheduled,
        place: 'City Mall Lost & Found, Level 2',
        when: DateTime.now().add(const Duration(hours: 18)),
        code: '4821',
      ),
    ];
    currentUser = demoOwner;
    signedIn = false;
  }

  late List<ItemReport> reports;
  late List<MatchCandidate> matchList;
  late List<Claim> claimList;
  late List<Conversation> inbox;
  late Map<String, List<Message>> threads;
  late List<AppNotification> notes;
  late List<ActivityItem> feed;
  late List<Handover> handovers;
  late User currentUser;
  bool signedIn = false;
  NotificationPrefs prefs = const NotificationPrefs();
  final deviceSessions = <DeviceSession>[
    DeviceSession(
      id: 'd1',
      name: 'Pixel 8',
      os: 'Android 15',
      lastSeen: DateTime.now(),
      current: true,
    ),
    DeviceSession(
      id: 'd2',
      name: 'iPhone 13',
      os: 'iOS 17',
      lastSeen: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  Future<T> _ok<T>(T value, [int ms = 280]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return value;
  }

  void _requireAuth() {
    if (!signedIn) throw ApiException('Please sign in', statusCode: 401);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (password != 'password') {
      throw ApiException('Those credentials do not match.', statusCode: 422);
    }
    if (email.toLowerCase() == demoStaff.email ||
        email.toLowerCase() == AppConstants.demoHubEmail) {
      currentUser = demoStaff;
    } else if (email.toLowerCase() == demoUnverified.email) {
      currentUser = demoUnverified;
    } else if (email.toLowerCase() == demoOwner.email ||
        email.contains('@')) {
      currentUser = email.toLowerCase() == demoOwner.email
          ? demoOwner
          : demoOwner.copyWith(displayName: email.split('@').first);
      if (email.toLowerCase() != demoOwner.email) {
        currentUser = User(
          id: 'u_${email.hashCode}',
          displayName: email.split('@').first,
          email: email,
          emailVerified: true,
          city: 'Nairobi',
          memberSince: DateTime.now(),
        );
      }
    } else {
      throw ApiException('Those credentials do not match.', statusCode: 422);
    }
    signedIn = true;
    return AuthResult(user: currentUser, token: 'mock-token', refreshToken: 'mock-refresh');
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String displayName,
    required String email,
    required String password,
    String? city,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    currentUser = User(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      name: name,
      email: email,
      city: city,
      emailVerified: false,
      state: AccountState.pendingVerification,
      memberSince: DateTime.now(),
    );
    signedIn = true;
    return AuthResult(user: currentUser, token: 'mock-token', refreshToken: 'mock-refresh');
  }

  @override
  Future<void> logout() async {
    signedIn = false;
    await _ok(null);
  }

  @override
  Future<User> me() => _ok(currentUser);

  @override
  Future<User> updateMe({
    String? displayName,
    String? city,
    String? avatarUrl,
    String? phone,
  }) async {
    currentUser = currentUser.copyWith(
      displayName: displayName,
      city: city,
      avatarUrl: avatarUrl,
      phone: phone,
    );
    return _ok(currentUser);
  }

  @override
  Future<void> forgotPassword(String email) => _ok(null, 350);

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) =>
      _ok(null, 350);

  @override
  Future<void> verifyEmail(String code) async {
    if (code.length < 4) throw ApiException('Enter the 6-digit code.');
    currentUser = currentUser.copyWith(
      emailVerified: true,
      verificationLevel: VerificationLevel.email,
      state: AccountState.active,
    );
    await _ok(null);
  }

  @override
  Future<void> sendOtp(String phone) => _ok(null);

  @override
  Future<void> confirmOtp(String phone, String code) async {
    if (code != '123456' && code.length < 4) {
      throw ApiException('That code is not valid. Demo code: 123456');
    }
    currentUser = currentUser.copyWith(
      phoneVerified: true,
      phone: phone,
      verificationLevel: VerificationLevel.phone,
    );
    await _ok(null);
  }

  @override
  Future<void> changePassword(String current, String next) async {
    if (current != 'password') throw ApiException('Current password is incorrect.');
    await _ok(null);
  }

  @override
  Future<List<Category>> categories() => _ok(mockCategories);

  @override
  Future<List<Hub>> hubs() => _ok(mockHubs);

  @override
  Future<Hub> hub(String id) async {
    return _ok(mockHubs.firstWhere((h) => h.id == id));
  }

  @override
  Future<List<ItemReport>> search(SearchQuery query) async {
    var list = reports.where((r) => r.status != ReportStatus.draft).toList();
    if (query.type != null) {
      list = list.where((r) => r.type == query.type).toList();
    }
    if (query.categoryId != null && query.categoryId!.isNotEmpty) {
      list = list.where((r) => r.categoryId == query.categoryId).toList();
    }
    if (query.hubId != null) {
      list = list.where((r) => r.hubId == query.hubId).toList();
    }
    if (query.q != null && query.q!.trim().isNotEmpty) {
      final q = query.q!.toLowerCase();
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.categoryName.toLowerCase().contains(q) ||
              (r.area ?? '').toLowerCase().contains(q) ||
              (r.color ?? '').toLowerCase().contains(q))
          .toList();
    }
    return _ok(list);
  }

  @override
  Future<List<ItemReport>> nearbyTeasers() async {
    final list = reports
        .where((r) =>
            r.status == ReportStatus.published ||
            r.status == ReportStatus.matched ||
            r.status == ReportStatus.claimInProgress)
        .toList();
    return _ok(list);
  }

  @override
  Future<List<ItemReport>> myReports() async {
    _requireAuth();
    return _ok(reports.where((r) => r.ownerId == currentUser.id).toList());
  }

  @override
  Future<List<ItemReport>> drafts() async {
    _requireAuth();
    return _ok(reports
        .where((r) => r.ownerId == currentUser.id && r.status == ReportStatus.draft)
        .toList());
  }

  @override
  Future<ItemReport> report(String id, {bool ownerView = false}) async {
    final item = reports.firstWhere((r) => r.id == id);
    final mine = signedIn && item.ownerId == currentUser.id;
    if (mine || ownerView) {
      return _ok(item.copyWith(isOwnerView: true));
    }
    return _ok(
      ItemReport(
        id: item.id,
        type: item.type,
        title: item.title,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        status: item.status,
        description: item.description,
        placeName: item.area,
        area: item.area,
        occurredAt: item.occurredAt,
        thumbnail: item.thumbnail,
        photos: item.photos,
        color: item.color,
        hubName: item.hubName,
        visibility: item.visibility,
        isOwnerView: false,
      ),
    );
  }

  @override
  Future<ItemReport> createReport(ReportDraft draft) async {
    _requireAuth();
    if (!currentUser.canCreateReports) {
      throw ApiException('Verify your email before creating a report.', statusCode: 403);
    }
    final cat = mockCategories.firstWhere(
      (c) => c.id == draft.categoryId,
      orElse: () => mockCategories.last,
    );
    final created = ItemReport(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      type: draft.type,
      title: draft.title.isEmpty ? 'Untitled ${draft.type.name}' : draft.title,
      categoryId: cat.id,
      categoryName: cat.name,
      status: ReportStatus.draft,
      description: draft.description,
      hiddenNotes: draft.hiddenNotes,
      serial: draft.serial,
      attributes: {
        if (draft.color.isNotEmpty) 'color': draft.color,
        if (draft.brand.isNotEmpty) 'brand': draft.brand,
      },
      placeName: draft.placeName,
      area: draft.placeName.isEmpty ? null : 'Near ${draft.placeName.split(',').first}',
      occurredAt: draft.occurredAt,
      custody: draft.custody,
      hubId: draft.hubId,
      hubName: mockHubs.where((h) => h.id == draft.hubId).firstOrNull?.name,
      visibility: draft.visibility,
      photos: draft.photos,
      thumbnail: draft.photos.isNotEmpty ? draft.photos.first : img('new-item'),
      ownerId: currentUser.id,
      color: draft.color,
      storageCode: draft.storageCode,
      condition: draft.condition,
      isOwnerView: true,
    );
    reports.insert(0, created);
    return _ok(created);
  }

  @override
  Future<ItemReport> updateReport(String id, ReportDraft draft) async {
    final i = reports.indexWhere((r) => r.id == id);
    if (i < 0) throw ApiException('Report not found', statusCode: 404);
    reports[i] = reports[i].copyWith(
      title: draft.title,
      description: draft.description,
      hiddenNotes: draft.hiddenNotes,
      serial: draft.serial,
      placeName: draft.placeName,
      photos: draft.photos,
      custody: draft.custody,
      hubId: draft.hubId,
      visibility: draft.visibility,
      color: draft.color,
      storageCode: draft.storageCode,
    );
    return _ok(reports[i]);
  }

  @override
  Future<void> submitReport(String id) async {
    final i = reports.indexWhere((r) => r.id == id);
    if (i < 0) throw ApiException('Report not found');
    reports[i] = reports[i].copyWith(status: ReportStatus.published);
    await _ok(null);
  }

  @override
  Future<void> closeReport(String id, String reason) async {
    final i = reports.indexWhere((r) => r.id == id);
    if (i < 0) throw ApiException('Report not found');
    reports[i] = reports[i].copyWith(status: ReportStatus.closed);
    await _ok(null);
  }

  @override
  Future<List<MatchCandidate>> matches({String? reportId}) async {
    final list = reportId == null
        ? matchList
        : matchList.where((m) => m.myReportId == reportId).toList();
    return _ok(list);
  }

  @override
  Future<Claim> startClaim(String reportId) async {
    _requireAuth();
    if (!currentUser.emailVerified) {
      throw ApiException('Verify your email before starting a claim.');
    }
    final claim = Claim(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      reportId: reportId,
      claimantId: currentUser.id,
      status: ClaimStatus.draft,
      reportTitle: reports.firstWhere((r) => r.id == reportId).title,
      timeline: [ClaimEvent(label: 'Claim started', at: DateTime.now())],
      createdAt: DateTime.now(),
    );
    claimList.insert(0, claim);
    return _ok(claim);
  }

  @override
  Future<Claim> submitAnswers(String claimId, Map<String, String> answers) async {
    final i = claimList.indexWhere((c) => c.id == claimId);
    claimList[i] = claimList[i].copyWith(
      answers: answers,
      status: ClaimStatus.submitted,
      timeline: [
        ...claimList[i].timeline,
        ClaimEvent(label: 'Answers submitted', at: DateTime.now()),
      ],
    );
    return _ok(claimList[i]);
  }

  @override
  Future<Claim> uploadEvidence(String claimId, List<String> urls) async {
    final i = claimList.indexWhere((c) => c.id == claimId);
    claimList[i] = claimList[i].copyWith(evidence: urls);
    return _ok(claimList[i]);
  }

  @override
  Future<Claim> getClaim(String id) =>
      _ok(claimList.firstWhere((c) => c.id == id));

  @override
  Future<List<Claim>> claims() => _ok(claimList);

  @override
  Future<Claim> reviewClaim(String id, {required bool accept}) async {
    final i = claimList.indexWhere((c) => c.id == id);
    claimList[i] = claimList[i].copyWith(
      status: accept ? ClaimStatus.accepted : ClaimStatus.rejected,
      timeline: [
        ...claimList[i].timeline,
        ClaimEvent(
          label: accept ? 'Accepted' : 'Rejected',
          at: DateTime.now(),
        ),
      ],
    );
    return _ok(claimList[i]);
  }

  @override
  Future<Claim> requestMoreInfo(String id, String message) async {
    final i = claimList.indexWhere((c) => c.id == id);
    claimList[i] = claimList[i].copyWith(
      status: ClaimStatus.moreInfo,
      moreInfoRequest: message,
      timeline: [
        ...claimList[i].timeline,
        ClaimEvent(label: 'More info requested', at: DateTime.now(), detail: message),
      ],
    );
    return _ok(claimList[i]);
  }

  @override
  Future<void> withdrawClaim(String id) async {
    final i = claimList.indexWhere((c) => c.id == id);
    claimList[i] = claimList[i].copyWith(status: ClaimStatus.withdrawn);
    await _ok(null);
  }

  @override
  Future<Handover> setupHandover({
    required String claimId,
    required HandoverType type,
    required String place,
    required DateTime when,
  }) async {
    final h = Handover(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      type: type,
      status: HandoverStatus.scheduled,
      place: place,
      when: when,
      code: '${1000 + DateTime.now().millisecond % 9000}',
    );
    handovers.insert(0, h);
    final i = claimList.indexWhere((c) => c.id == claimId);
    if (i >= 0) {
      claimList[i] = claimList[i].copyWith(status: ClaimStatus.handoverScheduled);
    }
    return _ok(h);
  }

  @override
  Future<Handover> getHandover(String id) =>
      _ok(handovers.firstWhere((h) => h.id == id));

  @override
  Future<Handover> confirmHandover(String id, {required bool asOwner}) async {
    final i = handovers.indexWhere((h) => h.id == id);
    var h = handovers[i];
    h = h.copyWith(
      ownerConfirmed: asOwner ? true : h.ownerConfirmed,
      finderConfirmed: asOwner ? h.finderConfirmed : true,
    );
    if (h.ownerConfirmed && h.finderConfirmed) {
      h = h.copyWith(status: HandoverStatus.completed);
      final ci = claimList.indexWhere((c) => c.id == h.claimId);
      if (ci >= 0) {
        claimList[ci] = claimList[ci].copyWith(status: ClaimStatus.recovered);
      }
    }
    handovers[i] = h;
    return _ok(h);
  }

  @override
  Future<List<Conversation>> conversations() => _ok(inbox);

  @override
  Future<List<Message>> messages(String conversationId) =>
      _ok(threads[conversationId] ?? const []);

  @override
  Future<Message> sendMessage(String conversationId, String body) async {
    final msg = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      body: body,
      mine: true,
      sentAt: DateTime.now(),
    );
    threads.putIfAbsent(conversationId, () => []);
    threads[conversationId] = [...threads[conversationId]!, msg];
    return _ok(msg, 180);
  }

  @override
  Future<List<AppNotification>> notifications() => _ok(notes);

  @override
  Future<void> markNotificationRead(String id) async {
    notes = notes
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    await _ok(null, 80);
  }

  @override
  Future<List<ActivityItem>> activity() => _ok(feed);

  @override
  Future<void> flag({
    required String targetType,
    required String targetId,
    required String reason,
    String? detail,
  }) =>
      _ok(null);

  @override
  Future<void> blockUser(String userId) => _ok(null);

  @override
  Future<List<CmsArticle>> helpArticles() =>
      _ok(mockArticles.where((a) => a.section == 'help').toList());

  @override
  Future<CmsArticle> cms(String slug) async {
    return _ok(mockArticles.firstWhere((a) => a.slug == slug));
  }

  @override
  Future<void> contactSupport(String subject, String body) => _ok(null, 400);

  @override
  Future<QrTag?> lookupTag(String code) async {
    if (code.toUpperCase() == 'MALL-092') {
      return _ok(const QrTag(
        code: 'MALL-092',
        reportId: 'r4',
        hubId: 'hub_mall',
        ownerLabel: 'Gold chain necklace',
        message: 'This tag is linked to a found item at City Mall.',
      ));
    }
    if (code.toUpperCase().startsWith('REU-')) {
      return _ok(QrTag(
        code: code,
        status: 'unlinked',
        message: 'Personal tag found. Register it in Phase 2 to notify the owner.',
      ));
    }
    return _ok(null);
  }

  @override
  Future<void> sendTip(String claimId, String note) => _ok(null);

  @override
  Future<void> requestDataExport() => _ok(null, 500);

  @override
  Future<void> deactivate() async {
    currentUser = currentUser.copyWith(state: AccountState.deactivated);
    signedIn = false;
    await _ok(null);
  }

  @override
  Future<void> deleteAccount() async {
    signedIn = false;
    await _ok(null);
  }

  @override
  @override
  Future<List<DeviceSession>> devices() => _ok(deviceSessions);

  @override
  Future<void> revokeDevice(String id) async {
    deviceSessions.removeWhere((d) => d.id == id);
    await _ok(null);
  }

  @override
  Future<NotificationPrefs> notificationPrefs() => _ok(prefs);

  @override
  Future<void> updateNotificationPrefs(NotificationPrefs next) async {
    prefs = next;
    await _ok(null);
  }

  @override
  Future<ItemReport> createHubIntake(ReportDraft draft, String storageCode) async {
    draft.storageCode = storageCode;
    draft.type = ReportType.found;
    draft.custody = Custody.atHub;
    draft.hubId = currentUser.hubId ?? 'hub_mall';
    return createReport(draft).then((r) async {
      await submitReport(r.id);
      return report(r.id, ownerView: true);
    });
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
