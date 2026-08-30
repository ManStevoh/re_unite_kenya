import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/i18n/strings.dart';
import '../core/network/api_client.dart';
import '../core/storage/prefs_storage.dart';
import '../core/storage/token_storage.dart';
import '../models/catalog.dart';
import '../models/claim.dart';
import '../models/enums.dart';
import '../models/item_report.dart';
import '../models/messaging.dart';
import '../models/user.dart';
import 'repositories/app_repository.dart';
import 'repositories/live_repository.dart';
import 'repositories/mock_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final prefsStorageProvider = Provider<PrefsStorage>((ref) => PrefsStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

final repositoryProvider = Provider<AppRepository>((ref) {
  if (kUseMockApi) {
    return MockRepository();
  }
  return LiveRepository(ref.watch(apiClientProvider));
});

class SessionState {
  const SessionState({
    this.user,
    this.isGuest = false,
    this.ready = false,
    this.onboardingSeen = false,
    this.permissionsPrimed = false,
    this.profileSetupDone = false,
  });

  final User? user;
  final bool isGuest;
  final bool ready;
  final bool onboardingSeen;
  final bool permissionsPrimed;
  final bool profileSetupDone;

  bool get isAuthenticated => user != null && !isGuest;
  bool get canMutate =>
      isAuthenticated && user!.emailVerified && user!.state == AccountState.active;

  SessionState copyWith({
    User? user,
    bool? isGuest,
    bool? ready,
    bool? onboardingSeen,
    bool? permissionsPrimed,
    bool? profileSetupDone,
    bool clearUser = false,
  }) {
    return SessionState(
      user: clearUser ? null : (user ?? this.user),
      isGuest: isGuest ?? this.isGuest,
      ready: ready ?? this.ready,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      permissionsPrimed: permissionsPrimed ?? this.permissionsPrimed,
      profileSetupDone: profileSetupDone ?? this.profileSetupDone,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._ref) : super(const SessionState());

  final Ref _ref;

  AppRepository get _repo => _ref.read(repositoryProvider);
  TokenStorage get _tokens => _ref.read(tokenStorageProvider);
  PrefsStorage get _prefs => _ref.read(prefsStorageProvider);

  Future<void> bootstrap() async {
    S.locale = await _prefs.locale();
    final seen = await _prefs.onboardingSeen();
    final primed = await _prefs.permissionsPrimed();
    final setup = await _prefs.profileSetupDone();
    final token = await _tokens.getToken();
    User? user;
    if (token != null && token.isNotEmpty) {
      try {
        if (kUseMockApi) {
          final mock = _repo as MockRepository;
          mock.signedIn = true;
          if (token.contains('staff')) {
            mock.currentUser = mock.currentUser.roles.contains('hub_staff')
                ? mock.currentUser
                : mock.currentUser;
          }
          user = await _repo.me();
        } else {
          user = await _repo.me();
        }
      } catch (_) {
        await _tokens.clear();
      }
    }
    state = SessionState(
      user: user,
      isGuest: user == null,
      ready: true,
      onboardingSeen: seen,
      permissionsPrimed: primed,
      profileSetupDone: setup || user != null,
    );
  }

  Future<void> completeOnboarding() async {
    await _prefs.setOnboardingSeen();
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> browseAsGuest() async {
    await _tokens.clear();
    state = state.copyWith(clearUser: true, isGuest: true);
  }

  Future<void> login(String email, String password) async {
    final result = await _repo.login(email, password);
    await _tokens.saveTokens(
      result.token ?? (email.contains('staff') ? 'mock-token-staff' : 'mock-token'),
      result.refreshToken,
    );
    await _prefs.setProfileSetupDone();
    state = state.copyWith(
      user: result.user,
      isGuest: false,
      profileSetupDone: true,
    );
  }

  Future<void> register({
    required String name,
    required String displayName,
    required String email,
    required String password,
    String? city,
  }) async {
    final result = await _repo.register(
      name: name,
      displayName: displayName,
      email: email,
      password: password,
      city: city,
    );
    await _tokens.saveTokens(result.token ?? 'mock-token', result.refreshToken);
    state = state.copyWith(user: result.user, isGuest: false, profileSetupDone: false);
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}
    await _tokens.clear();
    state = state.copyWith(clearUser: true, isGuest: true);
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    state = state.copyWith(user: await _repo.me());
  }

  Future<void> markPermissionsPrimed() async {
    await _prefs.setPermissionsPrimed();
    state = state.copyWith(permissionsPrimed: true);
  }

  Future<void> markProfileSetupDone() async {
    await _prefs.setProfileSetupDone();
    state = state.copyWith(profileSetupDone: true);
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});

class LocaleController extends StateNotifier<String> {
  LocaleController(this._prefs) : super('en');
  final PrefsStorage _prefs;

  Future<void> setLocale(String code) async {
    S.locale = code;
    state = code;
    await _prefs.setLocale(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, String>((ref) {
  return LocaleController(ref.watch(prefsStorageProvider));
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(ThemeMode.system);
  final PrefsStorage _prefs;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode.name);
  }

  Future<void> load() async {
    final raw = await _prefs.themeMode();
    state = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(prefsStorageProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(repositoryProvider).categories();
});

final hubsProvider = FutureProvider<List<Hub>>((ref) {
  return ref.watch(repositoryProvider).hubs();
});

final nearbyProvider = FutureProvider<List<ItemReport>>((ref) {
  return ref.watch(repositoryProvider).nearbyTeasers();
});

final myReportsProvider = FutureProvider<List<ItemReport>>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return [];
  return ref.watch(repositoryProvider).myReports();
});

final draftsProvider = FutureProvider<List<ItemReport>>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return [];
  return ref.watch(repositoryProvider).drafts();
});

final matchesProvider = FutureProvider.family<List<MatchCandidate>, String?>((ref, id) {
  return ref.watch(repositoryProvider).matches(reportId: id);
});

final claimsProvider = FutureProvider<List<Claim>>((ref) {
  return ref.watch(repositoryProvider).claims();
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.watch(repositoryProvider).conversations();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(repositoryProvider).notifications();
});

final activityProvider = FutureProvider<List<ActivityItem>>((ref) {
  return ref.watch(repositoryProvider).activity();
});

final helpProvider = FutureProvider<List<CmsArticle>>((ref) {
  return ref.watch(repositoryProvider).helpArticles();
});

class ReportDraftNotifier extends StateNotifier<ReportDraft> {
  ReportDraftNotifier() : super(ReportDraft());

  void reset(ReportType type) => state = ReportDraft(type: type);

  void patch(void Function(ReportDraft d) fn) {
    fn(state);
    state = ReportDraft.fromJson(state.toJson());
  }
}

final reportDraftProvider =
    StateNotifierProvider<ReportDraftNotifier, ReportDraft>((ref) {
  return ReportDraftNotifier();
});

class SearchState {
  const SearchState({
    this.q = '',
    this.type,
    this.categoryId,
  });

  final String q;
  final ReportType? type;
  final String? categoryId;

  SearchQuery get query => SearchQuery(q: q, type: type, categoryId: categoryId);

  SearchState copyWith({
    String? q,
    ReportType? type,
    String? categoryId,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return SearchState(
      q: q ?? this.q,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String q) => state = state.copyWith(q: q);
  void setType(ReportType? type) =>
      state = type == null ? state.copyWith(clearType: true) : state.copyWith(type: type);
  void setCategory(String? id) => state = id == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(categoryId: id);
}

final searchStateProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

final searchResultsProvider = FutureProvider<List<ItemReport>>((ref) {
  final q = ref.watch(searchStateProvider);
  return ref.watch(repositoryProvider).search(q.query);
});
