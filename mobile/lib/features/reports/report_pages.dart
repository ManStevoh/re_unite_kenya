import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../../models/item_report.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Drafts')),
      body: drafts.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load drafts', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No drafts',
              message: 'Unfinished reports stay on this device until you submit.',
              actionLabel: 'Start a report',
              onAction: () => context.push('/report'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text(r.categoryName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports/${r.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myReportsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Recovered'),
              Tab(text: 'Closed'),
            ],
          ),
        ),
        body: mine.when(
          loading: () => const SkeletonList(),
          error: (e, _) => EmptyState(title: 'Could not load', message: '$e'),
          data: (items) {
            List<ItemReport> filter(String kind) {
              return items.where((r) {
                if (kind == 'recovered') return r.status == ReportStatus.recovered;
                if (kind == 'closed') {
                  return r.status == ReportStatus.closed || r.status == ReportStatus.expired;
                }
                return r.status != ReportStatus.recovered &&
                    r.status != ReportStatus.closed &&
                    r.status != ReportStatus.expired;
              }).toList();
            }

            Widget list(List<ItemReport> rows, String empty) {
              if (rows.isEmpty) {
                return EmptyState(title: empty, message: 'When you file reports, they land here.');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final r = rows[i];
                  return Card(
                    child: ListTile(
                      title: Text(r.title),
                      subtitle: Text('${r.statusLabel} · ${r.categoryName}'),
                      trailing: StatusChip(label: r.typeLabel),
                      onTap: () => context.push('/reports/${r.id}'),
                    ),
                  );
                },
              );
            }

            return TabBarView(
              children: [
                list(filter('active'), 'No active reports'),
                list(filter('recovered'), 'No recoveries yet'),
                list(filter('closed'), 'Nothing closed'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class OwnerReportScreen extends ConsumerWidget {
  const OwnerReportScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).report(id, ownerView: true),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyState(title: 'Unavailable', message: '${snap.error}'),
            );
          }
          return const Scaffold(body: SkeletonList(count: 2));
        }
        final r = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your report'),
            actions: [
              IconButton(
                tooltip: 'Share teaser',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Teaser link: /teaser/${r.id}')),
                  );
                },
                icon: const Icon(Icons.ios_share),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (r.thumbnail != null)
                PhotoCard(
                  imageUrl: r.thumbnail,
                  heroTag: 'teaser-${r.id}',
                  onTap: () => openLightbox(context, r.thumbnail!, tag: 'teaser-${r.id}'),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StatusChip(label: r.typeLabel, tone: 'coral'),
                  const SizedBox(width: 8),
                  StatusChip(label: r.statusLabel, tone: 'success'),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
              Text(r.placeName ?? r.area ?? ''),
              if (r.occurredAt != null) Text(DateFormat.yMMMd().format(r.occurredAt!)),
              const SizedBox(height: 16),
              Text(r.description),
              const SizedBox(height: 16),
              const TrustBanner(text: 'Hidden marks stay on this screen only.'),
              const SizedBox(height: 8),
              Text('Hidden marks: ${r.hiddenNotes ?? '—'}'),
              Text('Serial: ${r.serial ?? '—'}'),
              const SizedBox(height: 20),
              AppButton(
                label: 'View matches (${r.matchCount})',
                onPressed: () => context.push('/matches?reportId=${r.id}'),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Close this report',
                secondary: true,
                onPressed: () => context.push('/reports/${r.id}/close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TeaserDetailScreen extends ConsumerWidget {
  const TeaserDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return FutureBuilder(
      future: ref.read(repositoryProvider).report(id),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyState(title: 'Teaser unavailable', message: '${snap.error}'),
            );
          }
          return const Scaffold(body: SkeletonList(count: 2));
        }
        final r = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Teaser'),
            actions: [
              IconButton(
                tooltip: 'Flag',
                onPressed: () => showFlagSheet(
                  context,
                  onSubmit: (reason) => ref.read(repositoryProvider).flag(
                        targetType: 'report',
                        targetId: r.id,
                        reason: reason,
                      ),
                ),
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PhotoCard(
                imageUrl: r.thumbnail,
                heroTag: 'teaser-${r.id}',
                onTap: r.thumbnail == null
                    ? null
                    : () => openLightbox(context, r.thumbnail!, tag: 'teaser-${r.id}'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StatusChip(
                    label: r.typeLabel,
                    tone: r.type == ReportType.lost ? 'coral' : 'success',
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: r.categoryName),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
              Text([r.color, r.area, if (r.occurredAt != null) DateFormat.yMMMd().format(r.occurredAt!)]
                  .whereType<String>()
                  .join(' · ')),
              if (r.hubName != null) Text('Held at ${r.hubName}'),
              const SizedBox(height: 12),
              Text(r.description),
              const SizedBox(height: 16),
              const TrustBanner(
                text: 'Serials, exact pins, and unique marks are hidden on purpose.',
              ),
              const SizedBox(height: 20),
              if (session.canMutate) ...[
                AppButton(
                  label: r.type == ReportType.found ? 'Start a claim' : 'I found something similar',
                  onPressed: () {
                    if (r.type == ReportType.found) {
                      context.push('/claims/start/${r.id}');
                    } else {
                      ref.read(reportDraftProvider.notifier).reset(ReportType.found);
                      context.push('/report/found/photo');
                    }
                  },
                ),
              ] else
                AppButton(
                  label: 'Sign in to claim',
                  onPressed: () => context.push('/login'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class CloseReportScreen extends ConsumerStatefulWidget {
  const CloseReportScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<CloseReportScreen> createState() => _CloseReportScreenState();
}

class _CloseReportScreenState extends ConsumerState<CloseReportScreen> {
  String _reason = 'Recovered elsewhere';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final reasons = [
      'Recovered elsewhere',
      'No longer needed',
      'Duplicate',
      'Expired / given up',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Close report')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...reasons.map(
              (r) => RadioListTile<String>(
                value: r,
                groupValue: _reason,
                title: Text(r),
                onChanged: (v) => setState(() => _reason = v!),
              ),
            ),
            const Spacer(),
            AppButton(
              label: 'Close report',
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  await ref.read(repositoryProvider).closeReport(widget.id, _reason);
                  ref.invalidate(myReportsProvider);
                  if (mounted) context.go('/reports');
                } catch (e) {
                  if (mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
