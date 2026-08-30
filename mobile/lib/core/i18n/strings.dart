class S {
  S._();

  static String locale = 'en';

  static const _en = <String, String>{
    'app_name': 'Reunite',
    'tagline': 'Lost things find their way home.',
    'home': 'Home',
    'search': 'Search',
    'report': 'Report',
    'activity': 'Activity',
    'profile': 'Profile',
    'hub': 'Hub desk',
    'continue_guest': 'Browse as guest',
    'trust_hidden': 'These details stay hidden until a claim is verified.',
    'empty_default': 'Nothing here yet.',
    'offline': 'You appear to be offline. Drafts are saved on this device.',
    'language': 'Language',
  };

  static const _sw = <String, String>{
    'app_name': 'Reunite',
    'tagline': 'Vitu vilivyopotea vinarejea nyumbani.',
    'home': 'Nyumbani',
    'search': 'Tafuta',
    'report': 'Ripoti',
    'activity': 'Shughuli',
    'profile': 'Wasifu',
    'hub': 'Dawati',
    'continue_guest': 'Vinjari kama mgeni',
    'language': 'Lugha',
  };

  static const _fr = <String, String>{
    'app_name': 'Reunite',
    'tagline': 'Les objets perdus retrouvent leur chemin.',
    'home': 'Accueil',
    'search': 'Recherche',
    'report': 'Signaler',
    'activity': 'Activité',
    'profile': 'Profil',
    'hub': 'Bureau',
    'continue_guest': 'Parcourir en invité',
    'language': 'Langue',
  };

  static String t(String key) {
    final map = switch (locale) {
      'sw' => _sw,
      'fr' => _fr,
      _ => _en,
    };
    return map[key] ?? _en[key] ?? key;
  }
}
