import 'enums.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.code,
    required this.iconName,
    this.sensitivity = Sensitivity.publicLevel,
    this.photoGuidance = 'Show the item, hide numbers and faces.',
    this.attributeKeys = const ['color', 'brand'],
  });

  final String id;
  final String name;
  final String code;
  final String iconName;
  final Sensitivity sensitivity;
  final String photoGuidance;
  final List<String> attributeKeys;
}

class HubHours {
  const HubHours({required this.weekday, required this.open, required this.close});

  final String weekday;
  final String open;
  final String close;
}

class Hub {
  const Hub({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.whatTheyStore = 'Wallets, phones, keys, bags, and documents.',
    this.hours = const [],
    this.storedCount = 0,
    this.intakeToday = 0,
    this.pickupsToday = 0,
    this.photoUrl,
  });

  final String id;
  final String name;
  final HubType type;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String whatTheyStore;
  final List<HubHours> hours;
  final int storedCount;
  final int intakeToday;
  final int pickupsToday;
  final String? photoUrl;

  String get typeLabel {
    switch (type) {
      case HubType.mall:
        return 'Mall desk';
      case HubType.campus:
        return 'Campus security';
      case HubType.station:
        return 'Station desk';
      case HubType.airport:
        return 'Airport';
      case HubType.office:
        return 'Office';
      case HubType.municipal:
        return 'Municipal';
    }
  }
}

class CmsArticle {
  const CmsArticle({
    required this.slug,
    required this.title,
    required this.body,
    this.section = 'help',
    this.excerpt,
  });

  final String slug;
  final String title;
  final String body;
  final String section;
  final String? excerpt;
}
