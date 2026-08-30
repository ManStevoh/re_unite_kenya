import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final nearby = ref.watch(nearbyProvider);
    final mine = ref.watch(myReportsProvider);
    final hubs = ref.watch(hubsProvider);
    final name = session.user?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          ScoopInkHeader(
            title: session.isAuthenticated ? 'Hi, $name' : 'Browsing as guest',
            subtitle: session.canMutate
                ? 'Your open cases and nearby teasers.'
                : 'Public teasers only. Sign in to report or claim.',
            bottomInset: RisingCreamSheet.overlap + 8,
            actions: [
              HeaderCircleButton(
                tooltip: 'Notifications',
                icon: Icons.notifications_outlined,
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -RisingCreamSheet.overlap,
                      left: 0,
                      right: 0,
                      height: box.maxHeight + RisingCreamSheet.overlap,
                      child: RisingCreamSheet(
                        child: RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: () async {
                    ref.invalidate(nearbyProvider);
                    ref.invalidate(myReportsProvider);
                    ref.invalidate(hubsProvider);
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                          child: HeroStatCard(
                            openCases: mine.maybeWhen(
                              data: (items) => items
                                  .where((r) =>
                                      r.status != ReportStatus.closed &&
                                      r.status != ReportStatus.recovered &&
                                      r.status != ReportStatus.draft)
                                  .length,
                              orElse: () => 0,
                            ),
                            matches: mine.maybeWhen(
                              data: (items) => items.fold<int>(0, (p, r) => p + r.matchCount),
                              orElse: () => 0,
                            ),
                            nearby: nearby.maybeWhen(data: (items) => items.length, orElse: () => 0),
                            onReport: session.canMutate ? () => context.push('/report') : null,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Text(
                            'Never share serials or ID photos in chat until a claim is accepted.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.ink.withOpacity(0.55),
                                ),
                          ),
                        ),
                      ),
            if (session.isAuthenticated)
              SliverToBoxAdapter(
                child: mine.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: SkeletonBox(height: 120, radius: 24),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (items) {
                    final open = items
                        .where((r) =>
                            r.status != ReportStatus.closed &&
                            r.status != ReportStatus.recovered &&
                            r.status != ReportStatus.draft)
                        .toList();
                    if (open.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: EmptyState(
                          title: 'No open cases',
                          message: 'Report something you lost or found. Hidden marks stay private.',
                          actionLabel: 'Report an item',
                          onAction: () => context.push('/report'),
                          icon: Icons.assignment_outlined,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionHeader(
                            title: 'My open cases',
                            action: 'See all',
                            onAction: () => context.push('/reports'),
                          ),
                        ),
                        SizedBox(
                          height: 168,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            scrollDirection: Axis.horizontal,
                            itemCount: open.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) {
                              final r = open[i];
                              return SizedBox(
                                width: 240,
                                child: Card(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => context.push('/reports/${r.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          StatusChip(label: r.statusLabel, tone: 'coral'),
                                          const Spacer(),
                                          Text(
                                            r.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                          Text('${r.matchCount} matches · ${r.claimCount} claims'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: SectionHeader(
                  title: 'Nearby teasers',
                  action: 'Map',
                  onAction: () => context.push('/search/map'),
                ),
              ),
            ),
            nearby.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox(height: 320, child: SkeletonList(count: 2))),
              error: (e, _) => SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Could not load teasers',
                  message: '$e',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(nearbyProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      title: 'No nearby teasers',
                      message: 'When people report nearby, redacted cards will show up here.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => TeaserCard(item: items[i]),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: hubs.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  final hub = list.first;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, kShellBottomGap),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: 'Hub near you',
                          action: 'All hubs',
                          onAction: () => context.push('/hubs'),
                        ),
                        CircleIconRow(
                          icon: Icons.storefront_outlined,
                          title: hub.name,
                          subtitle: '${hub.typeLabel} · ${hub.address}',
                          onTap: () => context.push('/hubs/${hub.id}'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
                    ],
                  ),
                ),
              ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
