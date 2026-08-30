import 'enums.dart';

class UserStats {
  const UserStats({
    this.reportsFiled = 0,
    this.itemsReturned = 0,
    this.claimsCompleted = 0,
  });

  final int reportsFiled;
  final int itemsReturned;
  final int claimsCompleted;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      reportsFiled: json['reports_filed'] as int? ?? 0,
      itemsReturned: json['items_returned'] as int? ?? 0,
      claimsCompleted: json['claims_completed'] as int? ?? 0,
    );
  }
}

class User {
  const User({
    required this.id,
    required this.displayName,
    required this.email,
    this.name,
    this.avatarUrl,
    this.city,
    this.phone,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.verificationLevel = VerificationLevel.none,
    this.memberSince,
    this.stats = const UserStats(),
    this.roles = const ['user'],
    this.state = AccountState.active,
    this.hubId,
  });

  final String id;
  final String displayName;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? city;
  final String? phone;
  final bool emailVerified;
  final bool phoneVerified;
  final VerificationLevel verificationLevel;
  final DateTime? memberSince;
  final UserStats stats;
  final List<String> roles;
  final AccountState state;
  final String? hubId;

  bool get isHubStaff =>
      roles.contains('hub_staff') || roles.contains('hub_manager');

  bool get canCreateReports =>
      emailVerified &&
      state == AccountState.active &&
      !roles.contains('guest');

  User copyWith({
    String? displayName,
    String? name,
    String? avatarUrl,
    String? city,
    String? phone,
    bool? emailVerified,
    bool? phoneVerified,
    VerificationLevel? verificationLevel,
    List<String>? roles,
    AccountState? state,
  }) {
    return User(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      memberSince: memberSince,
      stats: stats,
      roles: roles ?? this.roles,
      state: state ?? this.state,
      hubId: hubId,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id']}',
      displayName: json['display_name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      emailVerified: json['email_verified'] == true,
      phoneVerified: json['phone_verified'] == true,
      verificationLevel: _level(json['verification_level']),
      memberSince: json['member_since'] != null
          ? DateTime.tryParse('${json['member_since']}')
          : null,
      stats: json['stats'] is Map<String, dynamic>
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats(),
      roles: (json['roles'] as List?)?.map((e) => '$e').toList() ?? const ['user'],
      hubId: json['hub_id']?.toString(),
    );
  }

  static VerificationLevel _level(dynamic raw) {
    if (raw is int) {
      return switch (raw) {
        >= 4 => VerificationLevel.idChecked,
        >= 3 => VerificationLevel.phone,
        >= 2 => VerificationLevel.email,
        _ => VerificationLevel.none,
      };
    }
    switch ('$raw') {
      case '2':
      case 'email':
        return VerificationLevel.email;
      case '3':
      case 'phone':
        return VerificationLevel.phone;
      case '4':
      case 'id_checked':
      case 'idChecked':
        return VerificationLevel.idChecked;
      default:
        return VerificationLevel.none;
    }
  }
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.os,
    this.lastSeen,
    this.current = false,
  });

  final String id;
  final String name;
  final String os;
  final DateTime? lastSeen;
  final bool current;
}

class NotificationPrefs {
  const NotificationPrefs({
    this.matches = true,
    this.claims = true,
    this.chat = true,
    this.handovers = true,
    this.tips = false,
    this.emailDigest = true,
    this.pushEnabled = true,
  });

  final bool matches;
  final bool claims;
  final bool chat;
  final bool handovers;
  final bool tips;
  final bool emailDigest;
  final bool pushEnabled;

  NotificationPrefs copyWith({
    bool? matches,
    bool? claims,
    bool? chat,
    bool? handovers,
    bool? tips,
    bool? emailDigest,
    bool? pushEnabled,
  }) {
    return NotificationPrefs(
      matches: matches ?? this.matches,
      claims: claims ?? this.claims,
      chat: chat ?? this.chat,
      handovers: handovers ?? this.handovers,
      tips: tips ?? this.tips,
      emailDigest: emailDigest ?? this.emailDigest,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}
