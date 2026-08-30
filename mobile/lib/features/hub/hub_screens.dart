import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';

class HubHomeScreen extends ConsumerWidget {
  const HubHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.user?.isHubStaff != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hub desk')),
        body: const EmptyState(
          title: 'Staff only',
          message: 'Log in with staff@reunite.test / password to open hub mode.',
        ),
      );
    }
    final hubs = ref.watch(hubsProvider);
    final mine = ref.watch(nearbyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hub desk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hub/intake'),
        icon: const Icon(Icons.add),
        label: const Text('New intake'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          hubs.when(
            loading: () => const SkeletonBox(height: 120, radius: 24),
            error: (e, _) => Text('$e'),
            data: (list) {
              final hub = list.where((h) => h.id == session.user!.hubId).firstOrNull ??
                  (list.isEmpty ? null : list.first);
              if (hub == null) {
                return const EmptyState(title: 'No hub assigned', message: 'Ask an admin to assign your desk.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hub.name, style: Theme.of(context).textTheme.headlineSmall),
                  Text(hub.address),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Metric(label: 'Intake today', value: '${hub.intakeToday}'),
                      _Metric(label: 'Pickups', value: '${hub.pickupsToday}'),
                      _Metric(label: 'Stored', value: '${hub.storedCount}'),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            tileColor: Theme.of(context).cardColor,
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Storage inventory'),
            onTap: () => context.push('/hub/inventory'),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            tileColor: Theme.of(context).cardColor,
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan tag / storage label'),
            onTap: () => context.push('/hub/scan'),
          ),
          const SizedBox(height: 16),
          Text('Today’s stored teasers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          mine.when(
            loading: () => const SkeletonBox(height: 80, radius: 16),
            error: (e, _) => Text('$e'),
            data: (items) {
              final stored = items.where((r) => r.hubId == session.user!.hubId || r.storageCode != null).toList();
              if (stored.isEmpty) {
                return const Text('No items tagged to this desk in the mock set.');
              }
              return Column(
                children: stored
                    .take(5)
                    .map(
                      (r) => ListTile(
                        title: Text(r.title),
                        subtitle: Text(r.storageCode ?? 'No code'),
                        onTap: () => context.push('/hub/pickup/${r.id}'),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class HubIntakeScreen extends ConsumerStatefulWidget {
  const HubIntakeScreen({super.key});

  @override
  ConsumerState<HubIntakeScreen> createState() => _HubIntakeScreenState();
}

class _HubIntakeScreenState extends ConsumerState<HubIntakeScreen> {
  final _title = TextEditingController();
  final _color = TextEditingController();
  final _code = TextEditingController(text: 'MALL-${DateTime.now().millisecond}');
  String? _categoryId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _color.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('New intake')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TrustBanner(text: 'Fast found-item form. Storage code stays internal.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: cats
                .map(
                  (c) => ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          AppField(controller: _title, label: 'Title'),
          const SizedBox(height: 12),
          AppField(controller: _color, label: 'Color'),
          const SizedBox(height: 12),
          AppField(controller: _code, label: 'Storage code'),
          const SizedBox(height: 20),
          AppButton(
            label: 'File intake',
            busy: _busy,
            onPressed: () async {
              if (_title.text.trim().length < 3 || _categoryId == null) {
                showError(context, 'Title and category are required.');
                return;
              }
              setState(() => _busy = true);
              try {
                final draft = ref.read(reportDraftProvider);
                draft
                  ..type = ReportType.found
                  ..title = _title.text.trim()
                  ..color = _color.text.trim()
                  ..categoryId = _categoryId
                  ..categoryName = cats.firstWhere((c) => c.id == _categoryId).name
                  ..placeName = 'Hub desk'
                  ..custody = Custody.atHub;
                final created =
                    await ref.read(repositoryProvider).createHubIntake(draft, _code.text.trim());
                if (mounted) context.go('/reports/${created.id}');
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

class HubInventoryScreen extends ConsumerStatefulWidget {
  const HubInventoryScreen({super.key});

  @override
  ConsumerState<HubInventoryScreen> createState() => _HubInventoryScreenState();
}

class _HubInventoryScreenState extends ConsumerState<HubInventoryScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Storage inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by code or category',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: nearby.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyState(title: 'Unavailable', message: '$e'),
              data: (items) {
                final rows = items.where((r) {
                  if (r.storageCode == null) return false;
                  if (_q.isEmpty) return true;
                  return r.storageCode!.toLowerCase().contains(_q) ||
                      r.categoryName.toLowerCase().contains(_q) ||
                      r.title.toLowerCase().contains(_q);
                }).toList();
                if (rows.isEmpty) {
                  return const EmptyState(
                    title: 'No stored items match',
                    message: 'Try a storage code like MALL-092.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.title),
                        subtitle: Text('${r.storageCode} · ${r.categoryName}'),
                        onTap: () => context.push('/hub/pickup/${r.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HubPickupScreen extends ConsumerWidget {
  const HubPickupScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).report(id, ownerView: true),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? EmptyState(title: 'Not found', message: '${snap.error}')
                : const SkeletonList(count: 2),
          );
        }
        final r = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Pickup')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
              Text('Storage ${r.storageCode ?? '—'}'),
              const SizedBox(height: 12),
              const TrustBanner(
                text: 'Verify government ID in person. Ask one extra ownership question.',
              ),
              const SizedBox(height: 16),
              Text('Hidden marks: ${r.hiddenNotes ?? '—'}'),
              const SizedBox(height: 20),
              AppButton(
                label: 'Go to handover confirm',
                onPressed: () => context.push('/handover/confirm/h1'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HubScanScreen extends StatelessWidget {
  const HubScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TagScanScreen(hubMode: true);
  }
}

class TagScanScreen extends ConsumerStatefulWidget {
  const TagScanScreen({super.key, this.hubMode = false});
  final bool hubMode;

  @override
  ConsumerState<TagScanScreen> createState() => _TagScanScreenState();
}

class _TagScanScreenState extends ConsumerState<TagScanScreen> {
  final _code = TextEditingController();
  String? _result;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hubMode ? 'Hub scan' : 'QR / tag')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('Camera scan placeholder — enter a code below.\nTry MALL-092 or REU-1001'),
              ),
            ),
            const SizedBox(height: 16),
            AppField(controller: _code, label: 'Tag or storage code'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Look up',
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  final tag = await ref.read(repositoryProvider).lookupTag(_code.text.trim());
                  setState(() {
                    _result = tag == null
                        ? 'No tag found.'
                        : '${tag.message ?? 'Linked item'}\n${tag.ownerLabel ?? ''} ${tag.reportId ?? ''}';
                  });
                  if (tag?.reportId != null && mounted) {
                    context.push('/teaser/${tag!.reportId}');
                  }
                } catch (e) {
                  if (mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!),
            ],
          ],
        ),
      ),
    );
  }
}
