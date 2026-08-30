import '../core/constants/app_constants.dart';
import 'enums.dart';

String? rewriteMediaUrl(String? url) {
  if (url == null || url.isEmpty) {
    return url;
  }
  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) {
    return url;
  }
  final api = Uri.parse(defaultApiBaseUrl());
  if (parsed.host == 'localhost' || parsed.host == '127.0.0.1' || parsed.host == '10.0.2.2') {
    return parsed.replace(host: api.host, port: api.hasPort ? api.port : null).toString();
  }
  return url;
}

class ItemReport {
  const ItemReport({
    required this.id,
    required this.type,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    this.description = '',
    this.hiddenNotes,
    this.serial,
    this.attributes = const {},
    this.lat,
    this.lng,
    this.placeName,
    this.area,
    this.occurredAt,
    this.custody,
    this.hubId,
    this.hubName,
    this.visibility = Visibility.publicTeaser,
    this.thumbnail,
    this.photos = const [],
    this.ownerId,
    this.color,
    this.storageCode,
    this.condition,
    this.isOwnerView = false,
    this.matchCount = 0,
    this.claimCount = 0,
    this.updatedAt,
  });

  final String id;
  final ReportType type;
  final String title;
  final String categoryId;
  final String categoryName;
  final ReportStatus status;
  final String description;
  final String? hiddenNotes;
  final String? serial;
  final Map<String, String> attributes;
  final double? lat;
  final double? lng;
  final String? placeName;
  final String? area;
  final DateTime? occurredAt;
  final Custody? custody;
  final String? hubId;
  final String? hubName;
  final Visibility visibility;
  final String? thumbnail;
  final List<String> photos;
  final String? ownerId;
  final String? color;
  final String? storageCode;
  final String? condition;
  final bool isOwnerView;
  final int matchCount;
  final int claimCount;
  final DateTime? updatedAt;

  String get typeLabel => type == ReportType.lost ? 'Lost' : 'Found';

  String get statusLabel {
    switch (status) {
      case ReportStatus.draft:
        return 'Draft';
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under review';
      case ReportStatus.published:
        return 'Open';
      case ReportStatus.matched:
        return 'Matched';
      case ReportStatus.claimInProgress:
        return 'Claim in progress';
      case ReportStatus.recovered:
        return 'Recovered';
      case ReportStatus.closed:
        return 'Closed';
      case ReportStatus.expired:
        return 'Expired';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  ItemReport copyWith({
    ReportStatus? status,
    String? title,
    String? description,
    String? hiddenNotes,
    String? serial,
    Map<String, String>? attributes,
    String? placeName,
    DateTime? occurredAt,
    Custody? custody,
    String? hubId,
    String? hubName,
    Visibility? visibility,
    List<String>? photos,
    String? thumbnail,
    String? storageCode,
    String? color,
    bool? isOwnerView,
    int? matchCount,
    int? claimCount,
  }) {
    return ItemReport(
      id: id,
      type: type,
      title: title ?? this.title,
      categoryId: categoryId,
      categoryName: categoryName,
      status: status ?? this.status,
      description: description ?? this.description,
      hiddenNotes: hiddenNotes ?? this.hiddenNotes,
      serial: serial ?? this.serial,
      attributes: attributes ?? this.attributes,
      lat: lat,
      lng: lng,
      placeName: placeName ?? this.placeName,
      area: area,
      occurredAt: occurredAt ?? this.occurredAt,
      custody: custody ?? this.custody,
      hubId: hubId ?? this.hubId,
      hubName: hubName ?? this.hubName,
      visibility: visibility ?? this.visibility,
      thumbnail: thumbnail ?? this.thumbnail,
      photos: photos ?? this.photos,
      ownerId: ownerId,
      color: color ?? this.color,
      storageCode: storageCode ?? this.storageCode,
      condition: condition,
      isOwnerView: isOwnerView ?? this.isOwnerView,
      matchCount: matchCount ?? this.matchCount,
      claimCount: claimCount ?? this.claimCount,
      updatedAt: DateTime.now(),
    );
  }

  factory ItemReport.fromJson(Map<String, dynamic> json) {
    final attrs = <String, String>{};
    final rawAttrs = json['attributes'];
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) {
        if (v != null) attrs['$k'] = '$v';
      });
    }
    final photos = <String>[];
    if (json['photos'] is List) {
      photos.addAll((json['photos'] as List).map((e) => rewriteMediaUrl('$e') ?? '$e'));
    }
    if (json['thumbnail'] is String && photos.isEmpty) {
      photos.add(rewriteMediaUrl(json['thumbnail'] as String) ?? json['thumbnail'] as String);
    }
    return ItemReport(
      id: '${json['id']}',
      type: json['type'] == 'found' ? ReportType.found : ReportType.lost,
      title: json['title'] as String? ?? 'Item',
      categoryId: '${json['category_id'] ?? ''}',
      categoryName: json['category'] is String
          ? json['category'] as String
          : '${json['category'] is Map ? json['category']['name'] : 'Item'}',
      status: _status(json['status']),
      description: json['description'] as String? ?? '',
      hiddenNotes: json['hidden_notes'] as String?,
      serial: json['serial'] as String?,
      attributes: attrs,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      placeName: json['place_name'] as String?,
      area: json['area'] as String?,
      occurredAt: json['occurred_on'] != null
          ? DateTime.tryParse('${json['occurred_on']}')
          : json['occurred_at'] != null
              ? DateTime.tryParse('${json['occurred_at']}')
              : null,
      custody: _custody(json['custody']),
      hubId: json['hub_id']?.toString(),
      hubName: json['hub_name'] as String?,
      visibility: json['visibility'] == 'private_match_only'
          ? Visibility.privateMatchOnly
          : Visibility.publicTeaser,
      thumbnail: rewriteMediaUrl(json['thumbnail'] as String?),
      photos: photos,
      ownerId: json['owner'] is Map ? '${json['owner']['id']}' : json['user_id']?.toString(),
      color: json['color'] as String? ?? attrs['color'],
      storageCode: json['storage_code'] as String?,
      condition: json['condition'] as String?,
      isOwnerView: json['hidden_notes'] != null || json['serial'] != null,
      matchCount: json['match_count'] as int? ?? 0,
      claimCount: json['claim_count'] as int? ?? 0,
    );
  }

  static ReportStatus _status(dynamic raw) {
    switch ('$raw') {
      case 'draft':
        return ReportStatus.draft;
      case 'submitted':
        return ReportStatus.submitted;
      case 'under_review':
      case 'underReview':
        return ReportStatus.underReview;
      case 'matched':
        return ReportStatus.matched;
      case 'claim_in_progress':
      case 'claimInProgress':
        return ReportStatus.claimInProgress;
      case 'recovered':
        return ReportStatus.recovered;
      case 'closed':
        return ReportStatus.closed;
      case 'expired':
        return ReportStatus.expired;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.published;
    }
  }

  static Custody? _custody(dynamic raw) {
    switch ('$raw') {
      case 'at_hub':
      case 'atHub':
        return Custody.atHub;
      case 'with_staff':
      case 'withStaff':
        return Custody.withStaff;
      case 'with_finder':
      case 'withFinder':
        return Custody.withFinder;
      default:
        return null;
    }
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': status.name,
      'description': description,
      'hiddenNotes': hiddenNotes,
      'serial': serial,
      'attributes': attributes,
      'placeName': placeName,
      'area': area,
      'occurredAt': occurredAt?.toIso8601String(),
      'custody': custody?.name,
      'hubId': hubId,
      'visibility': visibility.name,
      'photos': photos,
      'color': color,
      'storageCode': storageCode,
    };
  }
}

class ReportDraft {
  ReportDraft({
    this.type = ReportType.lost,
    this.categoryId,
    this.categoryName,
    this.title = '',
    this.description = '',
    this.hiddenNotes = '',
    this.serial = '',
    this.color = '',
    this.brand = '',
    this.placeName = '',
    this.occurredAt,
    this.photos = const [],
    this.custody = Custody.withFinder,
    this.hubId,
    this.visibility = Visibility.publicTeaser,
    this.condition = '',
    this.storageCode = '',
  });

  ReportType type;
  String? categoryId;
  String? categoryName;
  String title;
  String description;
  String hiddenNotes;
  String serial;
  String color;
  String brand;
  String placeName;
  DateTime? occurredAt;
  List<String> photos;
  Custody custody;
  String? hubId;
  Visibility visibility;
  String condition;
  String storageCode;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'title': title,
        'description': description,
        'hiddenNotes': hiddenNotes,
        'serial': serial,
        'color': color,
        'brand': brand,
        'placeName': placeName,
        'occurredAt': occurredAt?.toIso8601String(),
        'photos': photos,
        'custody': custody.name,
        'hubId': hubId,
        'visibility': visibility.name,
        'condition': condition,
        'storageCode': storageCode,
      };

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    return ReportDraft(
      type: json['type'] == 'found' ? ReportType.found : ReportType.lost,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      hiddenNotes: json['hiddenNotes'] as String? ?? '',
      serial: json['serial'] as String? ?? '',
      color: json['color'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      placeName: json['placeName'] as String? ?? '',
      occurredAt: json['occurredAt'] != null
          ? DateTime.tryParse('${json['occurredAt']}')
          : null,
      photos: (json['photos'] as List?)?.map((e) => '$e').toList() ?? const [],
      custody: json['custody'] == 'atHub' ? Custody.atHub : Custody.withFinder,
      hubId: json['hubId'] as String?,
      visibility: json['visibility'] == 'privateMatchOnly'
          ? Visibility.privateMatchOnly
          : Visibility.publicTeaser,
      condition: json['condition'] as String? ?? '',
      storageCode: json['storageCode'] as String? ?? '',
    );
  }
}
