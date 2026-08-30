import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';

/// Space reserved so tab-root lists sit above the floating bar.
const double kShellBottomGap = 100;

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  void _openReport(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What happened?', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22E36414),
                  child: Icon(Icons.search, color: AppColors.coral),
                ),
                title: const Text('I lost something', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Unique marks stay hidden until a claim.'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/report');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withOpacity(0.15),
                  child: const Icon(Icons.volunteer_activism_outlined, color: AppColors.success),
                ),
                title: const Text('I found something', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Start with a photo. Hide ID numbers.'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/report');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: dark ? AppColors.cardDark : Colors.white,
                elevation: 10,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(36),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      _Tab(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: S.t('home'),
                        selected: navigationShell.currentIndex == 0,
                        onTap: () => _go(0),
                      ),
                      _Tab(
                        icon: Icons.search,
                        selectedIcon: Icons.search,
                        label: S.t('search'),
                        selected: navigationShell.currentIndex == 1,
                        onTap: () => _go(1),
                      ),
                      _Tab(
                        icon: Icons.bolt_outlined,
                        selectedIcon: Icons.bolt,
                        label: S.t('activity'),
                        selected: navigationShell.currentIndex == 2,
                        onTap: () => _go(2),
                      ),
                      _Tab(
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person,
                        label: session.user?.isHubStaff == true ? S.t('hub') : S.t('profile'),
                        selected: navigationShell.currentIndex == 3,
                        onTap: () => _go(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.coral,
              shape: const CircleBorder(),
              elevation: 8,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openReport(context),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? AppColors.ink.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(selected ? selectedIcon : icon, color: color, size: 22),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
