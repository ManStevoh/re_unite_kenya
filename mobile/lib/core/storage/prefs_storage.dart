import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class PrefsStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> onboardingSeen() async =>
      (await _p).getBool(PrefKeys.onboardingSeen) ?? false;

  Future<void> setOnboardingSeen() async =>
      (await _p).setBool(PrefKeys.onboardingSeen, true);

  Future<String> locale() async => (await _p).getString(PrefKeys.locale) ?? 'en';

  Future<void> setLocale(String code) async =>
      (await _p).setString(PrefKeys.locale, code);

  Future<String> themeMode() async =>
      (await _p).getString(PrefKeys.themeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async =>
      (await _p).setString(PrefKeys.themeMode, mode);

  Future<bool> permissionsPrimed() async =>
      (await _p).getBool(PrefKeys.permissionsPrimed) ?? false;

  Future<void> setPermissionsPrimed() async =>
      (await _p).setBool(PrefKeys.permissionsPrimed, true);

  Future<bool> profileSetupDone() async =>
      (await _p).getBool(PrefKeys.profileSetupDone) ?? false;

  Future<void> setProfileSetupDone() async =>
      (await _p).setBool(PrefKeys.profileSetupDone, true);

  Future<String?> reportDraft() async =>
      (await _p).getString(PrefKeys.reportDraft);

  Future<void> saveReportDraft(String json) async =>
      (await _p).setString(PrefKeys.reportDraft, json);

  Future<void> clearReportDraft() async =>
      (await _p).remove(PrefKeys.reportDraft);
}
