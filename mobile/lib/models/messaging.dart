import 'enums.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.preview,
    this.reportId,
    this.unread = 0,
    this.updatedAt,
    this.peerName,
    this.peerAvatar,
    this.safetyLocked = false,
  });

  final String id;
  final String title;
  final String preview;
  final String? reportId;
  final int unread;
  final DateTime? updatedAt;
  final String? peerName;
  final String? peerAvatar;
  final bool safetyLocked;
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.mine,
    this.imageUrl,
    this.sentAt,
  });

  final String id;
  final String conversationId;
  final String body;
  final bool mine;
  final String? imageUrl;
  final DateTime? sentAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    this.createdAt,
    this.route,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime? createdAt;
  final String? route;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
      route: route,
    );
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.route,
    this.at,
  });

  final String id;
  final String title;
  final String subtitle;
  final String kind;
  final String? route;
  final DateTime? at;
}

class Flag {
  const Flag({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.detail,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String? detail;
}

class QrTag {
  const QrTag({
    required this.code,
    this.reportId,
    this.ownerLabel,
    this.hubId,
    this.status = 'active',
    this.message,
  });

  final String code;
  final String? reportId;
  final String? ownerLabel;
  final String? hubId;
  final String status;
  final String? message;
}
