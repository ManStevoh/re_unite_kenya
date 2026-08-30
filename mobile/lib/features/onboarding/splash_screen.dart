import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await ref.read(sessionProvider.notifier).bootstrap();
    await ref.read(themeModeProvider.notifier).load();
    if (!mounted) return;
    final s = ref.read(sessionProvider);
    if (!s.onboardingSeen) {
      context.go('/onboarding');
    } else if (s.isAuthenticated) {
      if (!s.profileSetupDone) {
        context.go('/profile-setup');
      } else if (!s.permissionsPrimed) {
        context.go('/permissions');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 88)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.86, 0.86)),
            const SizedBox(height: 20),
            Text(
              'Reunite',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text(
              'Lost things find their way home.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cream.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
