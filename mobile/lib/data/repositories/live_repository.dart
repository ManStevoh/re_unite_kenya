import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/catalog.dart';
import '../../models/claim.dart';
import '../../models/enums.dart';
import '../../models/item_report.dart';
import '../../models/messaging.dart';
import '../../models/user.dart';
import 'app_repository.dart';

/// Live Laravel Sanctum client. Swap on with `kUseMockApi = false`.
class LiveRepository implements AppRepository {
  LiveRepository(this._client);

  final ApiClient _client;

  Future<T> _wrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw _client.mapError(e);
    }
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ApiException('Unexpected response');
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  @override
  Future<AuthResult> login(String email, String password) {
    return _wrap(() async {
      final res = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': 'reunite-mobile',
      });
      final body = _map(res.data);
      return AuthResult(
        user: User.fromJson(_map(body['user'] ?? body)),
        token: body['token'] as String?,
        refreshToken: body['refresh_token'] as String?,
      );
    });
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String displayName,
    required String email,
    required String password,
    String? city,
  }) {
    return _wrap(() async {
      final res = await _client.dio.post('/auth/register', data: {
        'name': name,
        'display_name': displayName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'city': city,
        'terms': true,
      });
      final body = _map(res.data);
      return AuthResult(
        user: User.fromJson(_map(body['user'] ?? body)),
        token: body['token'] as String?,
        refreshToken: body['refresh_token'] as String?,
      );
    });
  }

  @override
  Future<void> logout() => _wrap(() async {
        await _client.dio.post('/auth/logout');
      });

  @override
  Future<User> me() => _wrap(() async {
        final res = await _client.dio.get('/me');
        final body = _map(res.data);
        return User.fromJson(_map(body['user'] ?? body));
      });

  @override
  Future<User> updateMe({
    String? displayName,
    String? city,
    String? avatarUrl,
    String? phone,
  }) =>
      _wrap(() async {
        final res = await _client.dio.patch('/me', data: {
          if (displayName != null) 'display_name': displayName,
          if (city != null) 'city': city,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (phone != null) 'phone': phone,
        });
        final body = _map(res.data);
        return User.fromJson(_map(body['user'] ?? body));
      });

  @override
  Future<void> forgotPassword(String email) => _wrap(() async {
        await _client.dio.post('/auth/forgot-password', data: {'email': email});
      });

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) =>
      _wrap(() async {
        await _client.dio.post('/auth/reset-password', data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': password,
        });
      });

  @override
  Future<void> verifyEmail(String code) => _wrap(() async {
        await _client.dio.post('/auth/email/verify', data: {'code': code});
      });

  @override
  Future<void> sendOtp(String phone) => _wrap(() async {
        await _client.dio.post('/auth/phone/otp/send', data: {'phone': phone});
      });

  @override
  Future<void> confirmOtp(String phone, String code) => _wrap(() async {
        await _client.dio
            .post('/auth/phone/otp/confirm', data: {'phone': phone, 'code': code});
      });

  @override
  Future<void> changePassword(String current, String next) => _wrap(() async {
        await _client.dio.post('/me/password', data: {
          'current_password': current,
          'password': next,
          'password_confirmation': next,
        });
      });

  @override
  Future<List<Category>> categories() => _wrap(() async {
        final res = await _client.dio.get('/categories');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final attrs = m['attributes'] is List
              ? (m['attributes'] as List)
                  .map((a) => a is Map ? '${a['key'] ?? a['label']}' : '$a')
                  .where((s) => s.isNotEmpty)
                  .toList()
              : const <String>['color', 'brand'];
          return Category(
            id: '${m['id']}',
            name: m['name'] as String? ?? 'Other',
            code: m['code'] as String? ?? m['slug'] as String? ?? 'other',
            iconName: m['icon'] as String? ?? 'category',
            photoGuidance: m['photo_guidance'] as String? ?? 'Show the item, hide numbers and faces.',
            attributeKeys: attrs,
          );
        }).toList();
      });

  @override
  Future<List<Hub>> hubs() => _wrap(() async {
        final res = await _client.dio.get('/hubs');
        return _list(res.data).map((e) => _hub(Map<String, dynamic>.from(e as Map))).toList();
      });

  @override
  Future<Hub> hub(String id) => _wrap(() async {
        final res = await _client.dio.get('/hubs/$id');
        return _hub(_map(res.data));
      });

  ItemReport _teaser(Map<String, dynamic> m) => ItemReport.fromJson(m);

  Hub _hub(Map<String, dynamic> m) {
    final hours = <HubHours>[];
    if (m['hours'] is List) {
      for (final row in m['hours'] as List) {
        if (row is Map) {
          hours.add(HubHours(
            weekday: '${row['weekday'] ?? row['day'] ?? 'Daily'}',
            open: '${row['open'] ?? '08:00'}',
            close: '${row['close'] ?? '18:00'}',
          ));
        }
      }
    }
    return Hub(
      id: '${m['id']}',
      name: m['name'] as String? ?? 'Hub',
      type: _hubType(m['type']),
      address: m['address'] as String? ?? '',
      city: m['city'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      hours: hours,
    );
  }

  @override
  Future<List<ItemReport>> search(SearchQuery query) => _wrap(() async {
        final res = await _client.dio.get('/search', queryParameters: {
          if (query.q != null) 'q': query.q,
          if (query.type != null) 'type': query.type!.name,
          if (query.categoryId != null) 'category_id': query.categoryId,
        });
        return _list(res.data)
            .map((e) => _teaser(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  @override
  Future<List<ItemReport>> nearbyTeasers() => _wrap(() async {
        final res = await _client.dio.get('/reports');
        return _list(res.data)
            .map((e) => _teaser(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  @override
  Future<List<ItemReport>> myReports() => _wrap(() async {
        final res = await _client.dio.get('/me/reports');
        return _list(res.data)
            .map((e) => ItemReport.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  @override
  Future<List<ItemReport>> drafts() => _wrap(() async {
        final res = await _client.dio.get('/me/drafts');
        return _list(res.data)
            .map((e) => ItemReport.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  @override
  Future<ItemReport> report(String id, {bool ownerView = false}) => _wrap(() async {
        final res = await _client.dio.get('/reports/$id');
        return ItemReport.fromJson(_map(res.data));
      });

  @override
  Future<ItemReport> createReport(ReportDraft draft) => _wrap(() async {
        final res = await _client.dio.post('/reports', data: {
          'type': draft.type.name,
          'title': draft.title,
          'category_id': draft.categoryId,
          'description': draft.description,
          'hidden_notes': draft.hiddenNotes,
          'serial': draft.serial,
          'attributes': {'color': draft.color, 'brand': draft.brand},
          'place_name': draft.placeName,
          'occurred_at': draft.occurredAt?.toIso8601String(),
          'custody': draft.custody == Custody.atHub ? 'at_hub' : 'with_finder',
          'hub_id': draft.hubId,
          'visibility': draft.visibility == Visibility.privateMatchOnly
              ? 'private_match_only'
              : 'public_teaser',
        });
        return ItemReport.fromJson(_map(res.data));
      });

  @override
  Future<ItemReport> updateReport(String id, ReportDraft draft) => _wrap(() async {
        final res = await _client.dio.patch('/reports/$id', data: {
          'type': draft.type.name,
          'title': draft.title,
          'category_id': draft.categoryId,
          'description': draft.description,
          'hidden_notes': draft.hiddenNotes,
          'serial': draft.serial,
          'attributes': {'color': draft.color, 'brand': draft.brand},
          'place_name': draft.placeName,
          'occurred_at': draft.occurredAt?.toIso8601String(),
          'custody': draft.custody == Custody.atHub ? 'at_hub' : 'with_finder',
          'hub_id': draft.hubId,
          'visibility': draft.visibility == Visibility.privateMatchOnly
              ? 'private_match_only'
              : 'public_teaser',
        });
        return ItemReport.fromJson(_map(res.data));
      });

  @override
  Future<void> submitReport(String id) => _wrap(() async {
        await _client.dio.post('/reports/$id/submit');
      });

  @override
  Future<void> closeReport(String id, String reason) => _wrap(() async {
        await _client.dio.post('/reports/$id/close', data: {'reason': reason});
      });

  @override
  Future<List<MatchCandidate>> matches({String? reportId}) => _wrap(() async {
        if (reportId == null) return const [];
        final res = await _client.dio.get('/reports/$reportId/matches');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final other = Map<String, dynamic>.from(
            (m['lost'] is Map && reportId == '${m['found']?['id']}' ? m['lost'] : m['found'] ?? m['lost'] ?? m)
                as Map,
          );
          return MatchCandidate(
            id: '${m['id']}',
            myReportId: reportId,
            otherReportId: '${other['id'] ?? m['other_report_id'] ?? m['id']}',
            score: m['score'] as int? ?? 0,
            reasons: (m['reasons'] as List?)?.map((r) => '$r').toList() ?? const [],
            otherTitle: other['title'] as String? ?? m['title'] as String?,
            otherThumbnail: other['thumbnail'] as String?,
            otherArea: other['area'] as String?,
            otherCategory: other['category'] as String?,
          );
        }).toList();
      });

  @override
  Future<Claim> startClaim(String reportId) => _wrap(() async {
        final res = await _client.dio.post('/claims', data: {
          'item_report_id': reportId,
          'report_id': reportId,
        });
        return _claim(_map(res.data), fallbackReportId: reportId);
      });

  @override
  Future<Claim> submitAnswers(String claimId, Map<String, String> answers) =>
      _wrap(() async {
        await _client.dio.post('/claims/$claimId/answers', data: {
          'answers': answers.entries
              .map((e) => {
                    'question_key': e.key,
                    'question': e.key,
                    'answer': e.value,
                  })
              .toList(),
        });
        return getClaim(claimId);
      });

  @override
  Future<Claim> uploadEvidence(String claimId, List<String> urls) => getClaim(claimId);

  @override
  Future<Claim> getClaim(String id) => _wrap(() async {
        return _claim(_map((await _client.dio.get('/claims/$id')).data));
      });

  @override
  Future<List<Claim>> claims() => _wrap(() async {
        final res = await _client.dio.get('/claims');
        return _list(res.data).map((e) => _claim(Map<String, dynamic>.from(e as Map))).toList();
      });

  @override
  Future<Claim> reviewClaim(String id, {required bool accept}) => _wrap(() async {
        final res = await _client.dio.post('/claims/$id/review', data: {'accept': accept});
        return _claim(_map(res.data));
      });

  @override
  Future<Claim> requestMoreInfo(String id, String message) => _wrap(() async {
        final res = await _client.dio
            .post('/claims/$id/more-info', data: {'message': message});
        return _claim(_map(res.data));
      });

  @override
  Future<void> withdrawClaim(String id) => _wrap(() async {
        await _client.dio.post('/claims/$id/withdraw');
      });

  @override
  Future<Handover> setupHandover({
    required String claimId,
    required HandoverType type,
    required String place,
    required DateTime when,
  }) =>
      _wrap(() async {
        final res = await _client.dio.post('/handovers', data: {
          'claim_id': claimId,
          'type': switch (type) {
            HandoverType.hubPickup => 'hub_pickup',
            HandoverType.courier => 'staff_delivery',
            HandoverType.inPerson => 'meetup',
          },
          'place': place,
          'scheduled_at': when.toIso8601String(),
          'when': when.toIso8601String(),
        });
        final m = _map(res.data);
        return Handover(
          id: '${m['id']}',
          claimId: claimId,
          type: type,
          status: HandoverStatus.scheduled,
          place: place,
          when: when,
          code: m['code'] as String?,
        );
      });

  @override
  Future<Handover> getHandover(String id) => _wrap(() async {
        final res = await _client.dio.get('/handovers/$id');
        final m = _map(res.data);
        return Handover(
          id: '${m['id']}',
          claimId: '${m['claim_id'] ?? ''}',
          type: switch ('${m['type']}') {
            'hub_pickup' || 'hubPickup' => HandoverType.hubPickup,
            'staff_delivery' || 'courier' => HandoverType.courier,
            _ => HandoverType.inPerson,
          },
          status: m['status'] == 'completed'
              ? HandoverStatus.completed
              : HandoverStatus.scheduled,
          place: m['place'] as String?,
          when: m['scheduled_at'] != null ? DateTime.tryParse('${m['scheduled_at']}') : null,
        );
      });

  @override
  Future<Handover> confirmHandover(String id, {required bool asOwner}) =>
      _wrap(() async {
        await _client.dio.post('/handovers/$id/confirm', data: {'as_owner': asOwner});
        return Handover(
          id: id,
          claimId: '',
          type: HandoverType.inPerson,
          status: HandoverStatus.completed,
          ownerConfirmed: true,
          finderConfirmed: true,
        );
      });

  @override
  Future<List<Conversation>> conversations() => _wrap(() async {
        final res = await _client.dio.get('/conversations');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Conversation(
            id: '${m['id']}',
            title: m['title'] as String? ?? 'Conversation',
            preview: m['preview'] as String? ?? '',
          );
        }).toList();
      });

  @override
  Future<List<Message>> messages(String conversationId) => _wrap(() async {
        final res = await _client.dio.get('/conversations/$conversationId/messages');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Message(
            id: '${m['id']}',
            conversationId: conversationId,
            body: m['body'] as String? ?? '',
            mine: m['mine'] == true,
          );
        }).toList();
      });

  @override
  Future<Message> sendMessage(String conversationId, String body) => _wrap(() async {
        await _client.dio
            .post('/conversations/$conversationId/messages', data: {'body': body});
        return Message(
          id: 'tmp',
          conversationId: conversationId,
          body: body,
          mine: true,
          sentAt: DateTime.now(),
        );
      });

  @override
  Future<List<AppNotification>> notifications() => _wrap(() async {
        final res = await _client.dio.get('/notifications');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return AppNotification(
            id: '${m['id']}',
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
            type: NotificationType.system,
          );
        }).toList();
      });

  @override
  Future<void> markNotificationRead(String id) => _wrap(() async {
        await _client.dio.post('/notifications/$id/read');
      });

  @override
  Future<List<ActivityItem>> activity() => _wrap(() async {
        final res = await _client.dio.get('/me/activity');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return ActivityItem(
            id: '${m['id']}',
            title: m['title'] as String? ?? 'Update',
            subtitle: m['subtitle'] as String? ?? '',
            kind: m['kind'] as String? ?? 'system',
            route: m['route'] as String?,
            at: m['at'] != null ? DateTime.tryParse('${m['at']}') : null,
          );
        }).toList();
      });

  @override
  Future<void> flag({
    required String targetType,
    required String targetId,
    required String reason,
    String? detail,
  }) =>
      _wrap(() async {
        await _client.dio.post('/flags', data: {
          'target_type': targetType,
          'target_id': targetId,
          'reason': reason,
          'detail': detail,
        });
      });

  @override
  Future<void> blockUser(String userId) => _wrap(() async {
        await _client.dio.post('/me/block', data: {'user_id': userId});
      });

  @override
  Future<List<CmsArticle>> helpArticles() => _wrap(() async {
        final res = await _client.dio.get('/cms');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return CmsArticle(
            slug: m['slug'] as String? ?? '',
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
          );
        }).toList();
      });

  @override
  Future<CmsArticle> cms(String slug) => _wrap(() async {
        final res = await _client.dio.get('/cms/$slug');
        final m = _map(res.data);
        return CmsArticle(
          slug: slug,
          title: m['title'] as String? ?? slug,
          body: m['body'] as String? ?? '',
        );
      });

  @override
  Future<void> contactSupport(String subject, String body) => _wrap(() async {
        await _client.dio.post('/support', data: {'subject': subject, 'body': body});
      });

  @override
  Future<QrTag?> lookupTag(String code) => _wrap(() async {
        final res = await _client.dio.get('/tags/$code');
        final m = _map(res.data);
        return QrTag(code: code, reportId: m['report_id']?.toString());
      });

  @override
  Future<void> sendTip(String claimId, String note) => _wrap(() async {
        await _client.dio.post('/tips', data: {'claim_id': claimId, 'note': note});
      });

  @override
  Future<void> requestDataExport() => _wrap(() async {
        await _client.dio.post('/me/data-export');
      });

  @override
  Future<void> deactivate() => _wrap(() async {
        await _client.dio.post('/me/deactivate');
      });

  @override
  Future<void> deleteAccount() => _wrap(() async {
        await _client.dio.post('/me/delete');
      });

  @override
  Future<List<DeviceSession>> devices() => _wrap(() async {
        final res = await _client.dio.get('/me/devices');
        return _list(res.data).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return DeviceSession(
            id: '${m['id']}',
            name: m['name'] as String? ?? 'Device',
            os: m['os'] as String? ?? '',
          );
        }).toList();
      });

  @override
  Future<void> revokeDevice(String id) => _wrap(() async {
        await _client.dio.delete('/me/devices/$id');
      });

  @override
  Future<NotificationPrefs> notificationPrefs() => _wrap(() async {
        final res = await _client.dio.get('/me/notification-preferences');
        final body = _map(res.data);
        final prefs = body['preferences'] is Map
            ? Map<String, dynamic>.from(body['preferences'] as Map)
            : body;
        bool on(String key) {
          final row = prefs[key];
          if (row is Map) return row['in_app'] != false;
          return true;
        }
        return NotificationPrefs(
          matches: on('new_match'),
          claims: on('claim_received'),
          chat: on('new_chat_message'),
          handovers: on('handover_reminder'),
        );
      });

  @override
  Future<void> updateNotificationPrefs(NotificationPrefs prefs) => _wrap(() async {
        await _client.dio.patch('/me/notification-preferences', data: {
          'preferences': {
            'new_match': {'in_app': prefs.matches, 'push': prefs.matches, 'email': prefs.matches},
            'claim_received': {'in_app': prefs.claims, 'push': prefs.claims, 'email': prefs.claims},
            'new_chat_message': {'in_app': prefs.chat, 'push': prefs.chat, 'email': false},
            'handover_reminder': {'in_app': prefs.handovers, 'push': prefs.handovers, 'email': prefs.handovers},
          },
        });
      });

  @override
  Future<ItemReport> createHubIntake(ReportDraft draft, String storageCode) =>
      _wrap(() async {
        final created = await createReport(draft);
        final res = await _client.dio.patch('/reports/${created.id}', data: {
          'storage_code': storageCode,
          'custody': 'at_hub',
          'hub_id': draft.hubId,
        });
        return ItemReport.fromJson(_map(res.data));
      });

  Claim _claim(Map<String, dynamic> m, {String? fallbackReportId}) {
    return Claim(
      id: '${m['id']}',
      reportId: '${m['report_id'] ?? m['item_report_id'] ?? fallbackReportId ?? ''}',
      claimantId: '${m['claimant_id'] ?? ''}',
      status: switch ('${m['status']}') {
        'draft' => ClaimStatus.draft,
        'needs_info' || 'moreInfo' => ClaimStatus.moreInfo,
        'approved' || 'accepted' => ClaimStatus.accepted,
        'rejected' => ClaimStatus.rejected,
        'withdrawn' => ClaimStatus.withdrawn,
        'completed' || 'recovered' => ClaimStatus.recovered,
        _ => ClaimStatus.submitted,
      },
      reportTitle: m['title'] as String?,
      moreInfoRequest: m['decision_reason'] as String?,
      attempt: m['attempts'] as int? ?? 1,
    );
  }

  HubType _hubType(dynamic raw) {
    switch ('$raw') {
      case 'campus':
        return HubType.campus;
      case 'mall':
        return HubType.mall;
      case 'airport':
        return HubType.airport;
      case 'station':
        return HubType.station;
      case 'municipal':
        return HubType.municipal;
      default:
        return HubType.office;
    }
  }
}
