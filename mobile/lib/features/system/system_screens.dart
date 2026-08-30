import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline')),
      body: EmptyState(
        title: 'You appear to be offline',
        message: 'Drafts stay on this device. We will retry when you reconnect.',
        icon: Icons.wifi_off,
        actionLabel: 'Back',
        onAction: () => context.pop(),
      ),
    );
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandMark(),
              SizedBox(height: 24),
              Text('Please update Reunite', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text(
                'This version can no longer talk to the recovery API. Update from your store to keep reporting and claiming.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.handyman_outlined, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'We will be right back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Matching and claims are paused for maintenance. Your drafts are safe.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.gpp_bad_outlined, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Account restricted', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'This account cannot create reports or claims. Contact support if you think this is a mistake.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Contact support', onPressed: () => context.go('/support')),
            ],
          ),
        ),
      ),
    );
  }
}
