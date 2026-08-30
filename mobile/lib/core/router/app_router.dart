import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../features/activity/activity_screens.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/claims/claim_screens.dart';
import '../../features/cms/cms_screens.dart';
import '../../features/home/home_screen.dart';
import '../../features/hub/hub_screens.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/permission_primer_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/reports/report_flow.dart';
import '../../features/reports/report_pages.dart';
import '../../features/search/search_screens.dart';
import '../../features/system/system_screens.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

class _SessionRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh();
  ref.listen(sessionProvider, (_, __) => refresh.ping());

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      if (!session.ready && loc != '/splash') return '/splash';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset',
        builder: (_, state) => ResetPasswordScreen(email: state.uri.queryParameters['email']),
      ),
      GoRoute(path: '/verify-email', builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(path: '/verify', builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(path: '/phone-otp', builder: (_, __) => const PhoneOtpScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionPrimerScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (_, __) => const ActivityHubScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/search/results', builder: (_, __) => const SearchResultsScreen()),
      GoRoute(path: '/search/map', builder: (_, __) => const MapExploreScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoryBrowseScreen()),
      GoRoute(path: '/hubs', builder: (_, __) => const HubListScreen()),
      GoRoute(
        path: '/hubs/:id',
        builder: (_, state) => HubProfileScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/report', builder: (_, __) => const ReportChooserScreen()),
      GoRoute(path: '/report/lost/category', builder: (_, __) => const LostCategoryScreen()),
      GoRoute(path: '/report/lost/details', builder: (_, __) => const LostDetailsScreen()),
      GoRoute(path: '/report/lost/marks', builder: (_, __) => const LostMarksScreen()),
      GoRoute(path: '/report/lost/location', builder: (_, __) => const LostLocationScreen()),
      GoRoute(path: '/report/lost/photos', builder: (_, __) => const LostPhotosScreen()),
      GoRoute(path: '/report/lost/review', builder: (_, __) => const LostReviewScreen()),
      GoRoute(path: '/report/found/photo', builder: (_, __) => const FoundPhotoScreen()),
      GoRoute(path: '/report/found/details', builder: (_, __) => const FoundDetailsScreen()),
      GoRoute(path: '/report/found/custody', builder: (_, __) => const FoundCustodyScreen()),
      GoRoute(path: '/report/found/review', builder: (_, __) => const FoundReviewScreen()),
      GoRoute(path: '/drafts', builder: (_, __) => const DraftsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const MyReportsScreen()),
      GoRoute(
        path: '/reports/:id',
        builder: (_, state) => OwnerReportScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reports/:id/close',
        builder: (_, state) => CloseReportScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teaser/:id',
        builder: (_, state) => TeaserDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/matches',
        builder: (_, state) => MatchesListScreen(reportId: state.uri.queryParameters['reportId']),
      ),
      GoRoute(
        path: '/matches/:id',
        builder: (_, state) => MatchCompareScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/claims/start/:reportId',
        builder: (_, state) => StartClaimScreen(reportId: state.pathParameters['reportId']!),
      ),
      GoRoute(
        path: '/claims/questions/:claimId',
        builder: (_, state) => ChallengeQuestionsScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(
        path: '/claims/evidence/:claimId',
        builder: (_, state) => ClaimEvidenceScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(
        path: '/claims/submitted/:claimId',
        builder: (_, state) => ClaimSubmittedScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(
        path: '/claims/:id',
        builder: (_, state) => ClaimDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/claims/:id/review',
        builder: (_, state) => ReviewClaimScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/claims/:id/more-info',
        builder: (_, state) => MoreInfoScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/handover/setup/:claimId',
        builder: (_, state) => HandoverSetupScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(
        path: '/handover/confirm/:id',
        builder: (_, state) => HandoverConfirmScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/recovery/:claimId',
        builder: (_, state) => RecoverySuccessScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(
        path: '/tip/:claimId',
        builder: (_, state) => TipScreen(claimId: state.pathParameters['claimId']!),
      ),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(
        path: '/inbox/:id',
        builder: (_, state) => ConversationScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/security', builder: (_, __) => const SecurityScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, __) => const NotificationPrefsScreen()),
      GoRoute(path: '/settings/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/settings/export', builder: (_, __) => const DataExportScreen()),
      GoRoute(path: '/settings/delete', builder: (_, __) => const DeleteAccountScreen()),
      GoRoute(path: '/settings/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpCenterScreen()),
      GoRoute(
        path: '/help/:slug',
        builder: (_, state) => ArticleScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(
        path: '/legal/:slug',
        builder: (_, state) => LegalScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/hub', builder: (_, __) => const HubHomeScreen()),
      GoRoute(path: '/hub/intake', builder: (_, __) => const HubIntakeScreen()),
      GoRoute(path: '/hub/inventory', builder: (_, __) => const HubInventoryScreen()),
      GoRoute(
        path: '/hub/pickup/:id',
        builder: (_, state) => HubPickupScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/hub/scan', builder: (_, __) => const HubScanScreen()),
      GoRoute(path: '/tags', builder: (_, __) => const TagScanScreen()),
      GoRoute(
        path: '/tags/:code',
        builder: (_, state) => TagScanScreen(key: ValueKey(state.pathParameters['code'])),
      ),
      GoRoute(path: '/offline', builder: (_, __) => const OfflineScreen()),
      GoRoute(path: '/force-update', builder: (_, __) => const ForceUpdateScreen()),
      GoRoute(path: '/maintenance', builder: (_, __) => const MaintenanceScreen()),
      GoRoute(path: '/banned', builder: (_, __) => const BannedScreen()),
    ],
  );
});
