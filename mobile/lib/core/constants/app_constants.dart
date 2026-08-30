import 'package:flutter/foundation.dart';

/// Use the Laravel API. Set `true` only for offline UI demos.
const bool kUseMockApi = false;

/// Physical phone: your PC LAN IP, e.g. `192.168.1.20`. Empty uses emulator/desktop defaults.
/// Or run `adb reverse tcp:8000 tcp:8000` and keep this empty on Android.
const String kLanApiHost = '';

const String kAppName = 'Reunite';
const String kAppVersion = '1.0.0';
const String kAppBuild = '1';

String defaultApiBaseUrl() {
  if (kLanApiHost.isNotEmpty) {
    return 'http://$kLanApiHost:8000/api/v1';
  }
  if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Physical phone + `adb reverse tcp:8000 tcp:8000`. Emulator: set kLanApiHost to 10.0.2.2.
    return 'http://127.0.0.1:8000/api/v1';
  }
  return 'http://127.0.0.1:8000/api/v1';
}

class AppConstants {
  static const String demoOwnerEmail = 'owner@reunite.test';
  static const String demoStaffEmail = 'staff@reunite.test';
  static const String demoHubEmail = 'hub@reunite.test';
  static const String demoPassword = 'password';
  static const int maxPhotos = 6;
  static const int claimAttemptLimit = 3;
}

class PrefKeys {
  static const String onboardingSeen = 'onboarding_seen';
  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';
  static const String guest = 'guest_mode';
  static const String reportDraft = 'report_draft';
  static const String permissionsPrimed = 'permissions_primed';
  static const String profileSetupDone = 'profile_setup_done';
}
