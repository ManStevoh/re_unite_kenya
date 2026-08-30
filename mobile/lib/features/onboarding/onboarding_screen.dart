import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(
      icon: Icons.search_rounded,
      title: 'Report what you lost',
      body:
          'Describe the item, hide the unique marks, and we look for likely matches — never a public dump of your details.',
    ),
    _Page(
      icon: Icons.volunteer_activism_outlined,
      title: 'Or bring something home',
      body:
          'Finders and trusted hubs log found items. Public teasers show color and area, not serials or ID photos.',
    ),
    _Page(
      icon: Icons.verified_user_outlined,
      title: 'Verify, then return',
      body:
          'Claims use challenge questions. Contact stays in-app until both sides agree. Hubs can confirm in person.',
    ),
    _Page(
      icon: Icons.handshake_outlined,
      title: 'A safe handoff',
      body:
          'Meet at a desk, confirm a short code, and mark it recovered. Reunite is a recovery network — not classifieds.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).completeOnboarding();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.ink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Icon(p.icon, size: 56, color: AppColors.ink),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.45,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppColors.coral,
                  dotColor: Color(0x330F4C5C),
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _index == _pages.length - 1 ? 'Get started' : 'Next',
                onPressed: () {
                  if (_index == _pages.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page {
  const _Page({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}
