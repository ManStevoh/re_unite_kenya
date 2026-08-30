import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class PermissionPrimerScreen extends ConsumerWidget {
  const PermissionPrimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('A few permissions')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'We ask before we access anything. You can deny a permission and still browse teasers.',
            ),
            const SizedBox(height: 24),
            const _Row(
              icon: Icons.photo_camera_outlined,
              title: 'Camera',
              body: 'Capture item photos. We never upload until you submit a report.',
            ),
            const _Row(
              icon: Icons.location_on_outlined,
              title: 'Location',
              body: 'Suggest a last-seen area. Public cards show a coarse neighborhood, not your exact pin.',
            ),
            const _Row(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              body: 'Match, claim, and chat alerts. Push is stubbed in v1 — prefs still save.',
            ),
            const Spacer(),
            const TrustBanner(text: 'You can change these later in system settings.'),
            const SizedBox(height: 16),
            AppButton(
              label: 'Continue',
              onPressed: () async {
                await ref.read(sessionProvider.notifier).markPermissionsPrimed();
                if (context.mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.ink.withOpacity(0.08),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
