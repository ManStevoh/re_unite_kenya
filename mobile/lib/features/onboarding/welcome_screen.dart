import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RisingSheetScaffold(
      title: 'Welcome to Reunite',
      subtitle: S.t('tagline'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            const BrandMark(boxed: false, size: 56),
            const SizedBox(height: 16),
            Text(
              'Get things back, privately.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse teasers as a guest, or create an account to report, claim, and chat in-app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/illustrations/welcome-handover.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Create account',
              onPressed: () => context.push('/register'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Log in',
              secondary: true,
              onPressed: () => context.push('/login'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(sessionProvider.notifier).browseAsGuest();
                if (context.mounted) context.go('/home');
              },
              child: Text(S.t('continue_guest')),
            ),
          ],
        ),
      ),
    );
  }
}
