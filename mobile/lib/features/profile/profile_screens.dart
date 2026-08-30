import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/strings.dart';
import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.isAuthenticated) {
      return CurvedInkScaffold(
        title: 'Profile',
        showBack: false,
        child: EmptyState(
          title: 'You are browsing as a guest',
          message: 'Create an account to report, claim, and build trust badges.',
          actionLabel: 'Log in',
          onAction: () => context.push('/login'),
        ),
      );
    }
    final u = session.user!;
    return CurvedInkScaffold(
      title: 'Profile',
      showBack: false,
      actions: [
        HeaderCircleButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_outlined,
          onPressed: () => context.push('/notifications'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, kShellBottomGap),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.ink,
              child: Text(
                u.displayName.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            u.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (u.city != null && u.city!.isNotEmpty) u.city,
              if (u.memberSince != null) 'Member since ${DateFormat.yMMM().format(u.memberSince!)}',
            ].whereType<String>().join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink.withOpacity(0.55)),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (u.emailVerified) const StatusChip(label: 'Email verified', tone: 'success'),
              if (u.phoneVerified) const StatusChip(label: 'Phone verified', tone: 'success'),
              if (u.isHubStaff) const StatusChip(label: 'Hub staff', tone: 'coral'),
              StatusChip(label: u.verificationLevel.name),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(label: 'Reports', value: '${u.stats.reportsFiled}'),
              _Stat(label: 'Returned', value: '${u.stats.itemsReturned}'),
              _Stat(label: 'Claims', value: '${u.stats.claimsCompleted}'),
            ],
          ),
          const SizedBox(height: 20),
          CircleIconRow(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.assignment_outlined,
            title: 'My reports',
            onTap: () => context.push('/reports'),
          ),
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.drafts_outlined,
            title: 'Drafts',
            onTap: () => context.push('/drafts'),
          ),
          if (u.isHubStaff) ...[
            const SizedBox(height: 10),
            CircleIconRow(
              icon: Icons.storefront_outlined,
              title: 'Hub desk',
              onTap: () => context.push('/hub'),
            ),
          ],
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.qr_code_scanner,
            title: 'Scan a tag',
            onTap: () => context.push('/tags'),
          ),
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.help_outline,
            title: 'Help',
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 10),
          CircleIconRow(
            icon: Icons.logout,
            title: 'Log out',
            tone: AppColors.coral,
            onTap: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(sessionProvider).user;
    _name = TextEditingController(text: u?.displayName ?? '');
    _city = TextEditingController(text: u?.city ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppField(controller: _name, label: 'Display name'),
          const SizedBox(height: 12),
          AppField(controller: _city, label: 'City'),
          const SizedBox(height: 20),
          AppButton(
            label: 'Save',
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await ref.read(repositoryProvider).updateMe(
                      displayName: _name.text.trim(),
                      city: _city.text.trim(),
                    );
                await ref.read(sessionProvider.notifier).refreshUser();
                if (mounted) context.pop();
              } catch (e) {
                if (mounted) showError(context, e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: Text(theme.name),
            onTap: () async {
              final next = await showModalBottomSheet<ThemeMode>(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values
                      .map(
                        (m) => ListTile(
                          title: Text(m.name),
                          onTap: () => Navigator.pop(ctx, m),
                        ),
                      )
                      .toList(),
                ),
              );
              if (next != null) {
                await ref.read(themeModeProvider.notifier).setMode(next);
              }
            },
          ),
          ListTile(
            title: Text(S.t('language')),
            subtitle: Text(ref.watch(localeProvider)),
            onTap: () => context.push('/settings/language'),
          ),
          ListTile(
            title: const Text('Security'),
            onTap: () => context.push('/settings/security'),
          ),
          ListTile(
            title: const Text('Notification preferences'),
            onTap: () => context.push('/settings/notifications'),
          ),
          ListTile(
            title: const Text('Privacy'),
            onTap: () => context.push('/settings/privacy'),
          ),
          ListTile(
            title: const Text('Download my data'),
            onTap: () => context.push('/settings/export'),
          ),
          ListTile(
            title: const Text('Deactivate or delete'),
            onTap: () => context.push('/settings/delete'),
          ),
          ListTile(
            title: const Text('Help center'),
            onTap: () => context.push('/help'),
          ),
          ListTile(
            title: const Text('Contact support'),
            onTap: () => context.push('/support'),
          ),
          ListTile(
            title: const Text('Legal'),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            title: const Text('About'),
            onTap: () => context.push('/about'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Preview: offline'),
            onTap: () => context.push('/offline'),
          ),
          ListTile(
            title: const Text('Preview: force update'),
            onTap: () => context.push('/force-update'),
          ),
          ListTile(
            title: const Text('Preview: maintenance'),
            onTap: () => context.push('/maintenance'),
          ),
          ListTile(
            title: const Text('Preview: banned'),
            onTap: () => context.push('/banned'),
          ),
          ListTile(
            title: const Text('Log out'),
            textColor: AppColors.danger,
            onTap: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              kUseMockApi
                  ? 'Using mock API. Set kUseMockApi = false to hit Laravel.'
                  : 'Talking to the Laravel API at ${defaultApiBaseUrl()}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: FutureBuilder(
        future: ref.read(repositoryProvider).devices(),
        builder: (context, snap) {
          final devices = snap.data ?? const <DeviceSession>[];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Change password'),
              const SizedBox(height: 8),
              AppField(controller: _current, label: 'Current', obscure: true),
              const SizedBox(height: 8),
              AppField(controller: _next, label: 'New password', obscure: true),
              const SizedBox(height: 12),
              AppButton(
                label: 'Update password',
                onPressed: () async {
                  try {
                    await ref.read(repositoryProvider).changePassword(_current.text, _next.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Phone OTP / 2FA'),
                subtitle: const Text('Step-up for claims and recovery.'),
                onTap: () => context.push('/phone-otp'),
              ),
              const SizedBox(height: 8),
              Text('Devices', style: Theme.of(context).textTheme.titleMedium),
              if (devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No devices registered.'),
                ),
              ...devices.map(
                (d) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  subtitle: Text('${d.os}${d.current ? ' · this device' : ''}'),
                  trailing: d.current
                      ? null
                      : TextButton(
                          onPressed: () async {
                            await ref.read(repositoryProvider).revokeDevice(d.id);
                            setState(() {});
                          },
                          child: const Text('Revoke'),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends ConsumerState<NotificationPrefsScreen> {
  NotificationPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    ref.read(repositoryProvider).notificationPrefs().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: p == null
          ? const SkeletonList(count: 3)
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Matches'),
                  value: p.matches,
                  onChanged: (v) => _save(p.copyWith(matches: v)),
                ),
                SwitchListTile(
                  title: const Text('Claims'),
                  value: p.claims,
                  onChanged: (v) => _save(p.copyWith(claims: v)),
                ),
                SwitchListTile(
                  title: const Text('Chat'),
                  value: p.chat,
                  onChanged: (v) => _save(p.copyWith(chat: v)),
                ),
                SwitchListTile(
                  title: const Text('Handovers'),
                  value: p.handovers,
                  onChanged: (v) => _save(p.copyWith(handovers: v)),
                ),
                SwitchListTile(
                  title: const Text('Email digest'),
                  value: p.emailDigest,
                  onChanged: (v) => _save(p.copyWith(emailDigest: v)),
                ),
                SwitchListTile(
                  title: const Text('Push (stubbed)'),
                  value: p.pushEnabled,
                  onChanged: (v) => _save(p.copyWith(pushEnabled: v)),
                ),
              ],
            ),
    );
  }

  Future<void> _save(NotificationPrefs next) async {
    setState(() => _prefs = next);
    await ref.read(repositoryProvider).updateNotificationPrefs(next);
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          TrustBanner(text: 'Public cards never include exact pins, serials, or contact details.'),
          SizedBox(height: 16),
          Text(
            'Your display name and city are visible on claims. Legal name, phone, and hidden marks stay restricted. Chats can be reviewed if flagged.',
          ),
          SizedBox(height: 16),
          Text('You can export or delete your data at any time from Settings.'),
        ],
      ),
    );
  }
}

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _busy = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download my data')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'We will prepare an export of your reports, claims, and messages. In demo this completes immediately.',
            ),
            const Spacer(),
            if (_done) const TrustBanner(text: 'Export queued. Check your email in a live environment.'),
            AppButton(
              label: _done ? 'Requested' : 'Request export',
              busy: _busy,
              onPressed: _done
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await ref.read(repositoryProvider).requestDataExport();
                      setState(() {
                        _busy = false;
                        _done = true;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deactivate or delete')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Deactivate hides your profile but keeps open cases for hubs. Delete is a strong confirm and signs you out everywhere.',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Deactivate',
            secondary: true,
            onPressed: () async {
              await ref.read(repositoryProvider).deactivate();
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
          const SizedBox(height: 20),
          AppField(controller: _confirm, label: 'Type DELETE to confirm'),
          const SizedBox(height: 12),
          AppButton(
            label: 'Delete my account',
            onPressed: () async {
              if (_confirm.text.trim() != 'DELETE') {
                showError(context, 'Type DELETE to continue.');
                return;
              }
              await ref.read(repositoryProvider).deleteAccount();
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    const options = {
      'en': 'English',
      'sw': 'Kiswahili',
      'fr': 'Français',
    };
    return Scaffold(
      appBar: AppBar(title: Text(S.t('language'))),
      body: ListView(
        children: options.entries
            .map(
              (e) => RadioListTile<String>(
                value: e.key,
                groupValue: current,
                title: Text(e.value),
                onChanged: (v) async {
                  if (v != null) await ref.read(localeProvider.notifier).setLocale(v);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandMark(boxed: false),
          const SizedBox(height: 16),
          Text('Reunite', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Version $kAppVersion ($kAppBuild)'),
          const SizedBox(height: 12),
          const Text(
            'A privacy-first lost-and-found recovery network. Matching suggests. Humans confirm.',
          ),
        ],
      ),
    );
  }
}
