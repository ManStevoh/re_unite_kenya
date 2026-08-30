import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../models/item_report.dart';
import '../../data/providers.dart';
import '../../models/catalog.dart';
import '../../models/enums.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _applyFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(searchStateProvider);
            final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any type'),
                        selected: state.type == null,
                        onSelected: (_) => ref.read(searchStateProvider.notifier).setType(null),
                      ),
                      ChoiceChip(
                        label: const Text('Lost'),
                        selected: state.type == ReportType.lost,
                        onSelected: (_) =>
                            ref.read(searchStateProvider.notifier).setType(ReportType.lost),
                      ),
                      ChoiceChip(
                        label: const Text('Found'),
                        selected: state.type == ReportType.found,
                        onSelected: (_) =>
                            ref.read(searchStateProvider.notifier).setType(ReportType.found),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All categories'),
                        selected: state.categoryId == null,
                        onSelected: (_) =>
                            ref.read(searchStateProvider.notifier).setCategory(null),
                      ),
                      ...cats.map(
                        (c) => FilterChip(
                          label: Text(c.name),
                          selected: state.categoryId == c.id,
                          onSelected: (_) =>
                              ref.read(searchStateProvider.notifier).setCategory(c.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'See results',
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/search/results');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    return CurvedInkScaffold(
      title: 'Search',
      showBack: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, kShellBottomGap),
        children: [
          TextField(
            controller: _q,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              ref.read(searchStateProvider.notifier).setQuery(v);
              context.push('/search/results');
            },
            decoration: InputDecoration(
              hintText: 'Wallet, keys, blue phone…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Filters',
                onPressed: _applyFilters,
                icon: const Icon(Icons.tune),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Browse categories',
            action: 'All',
            onAction: () => context.push('/categories'),
          ),
          const SizedBox(height: 8),
          cats.when(
            loading: () => const SkeletonBox(height: 180, radius: 24),
            error: (e, _) => Text('$e'),
            data: (list) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: list
                  .take(6)
                  .map(
                    (c) => _CategoryTile(
                      category: c,
                      onTap: () {
                        ref.read(searchStateProvider.notifier).setCategory(c.id);
                        context.push('/search/results');
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          CircleIconRow(
            icon: Icons.map_outlined,
            title: 'Explore the map',
            subtitle: 'Area clusters only — no exact pins for others.',
            onTap: () => context.push('/search/map'),
          ),
          const SizedBox(height: 12),
          CircleIconRow(
            icon: Icons.storefront_outlined,
            title: 'Find a drop-off desk',
            subtitle: 'Mall, campus, and station hubs',
            onTap: () => context.push('/hubs'),
          ),
        ],
      ),
    );
  }
}

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final q = ref.watch(searchStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(q.q.isEmpty ? 'Results' : q.q),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: results.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(
          title: 'Search failed',
          message: '$e',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(searchResultsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No teasers match',
              message: 'Try another category or a shorter query. Unique marks stay hidden on purpose.',
              actionLabel: 'Clear filters',
              onAction: () {
                ref.read(searchStateProvider.notifier).setQuery('');
                ref.read(searchStateProvider.notifier).setType(null);
                ref.read(searchStateProvider.notifier).setCategory(null);
                ref.invalidate(searchResultsProvider);
              },
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => TeaserCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class MapExploreScreen extends ConsumerStatefulWidget {
  const MapExploreScreen({super.key});

  @override
  ConsumerState<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends ConsumerState<MapExploreScreen> {
  String? _area;

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbyProvider);
    return RisingSheetScaffold(
      title: 'Map explore',
      subtitle: 'Area clusters only. Exact pins stay hidden.',
      child: nearby.when(
        loading: () => const SkeletonList(count: 2),
        error: (e, _) => EmptyState(title: 'Map unavailable', message: '$e'),
        data: (items) {
          final clustered = _clusters(items);
          final visible = _area == null
              ? items
              : items.where((r) => (r.area ?? r.placeName ?? 'Nearby') == _area).toList();
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _AreaClusterMap(
                    clusters: clustered,
                    selectedArea: _area,
                    onSelect: (area) => setState(() => _area = _area == area ? null : area),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _area == null ? '${items.length} teasers nearby' : '$_area · ${visible.length}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_area != null)
                      TextButton(onPressed: () => setState(() => _area = null), child: const Text('Clear')),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: visible.isEmpty
                    ? const EmptyState(
                        title: 'No items in this area',
                        message: 'Tap another cluster, or clear the filter.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = visible[i];
                          return CircleIconRow(
                            icon: r.type == ReportType.lost ? Icons.search : Icons.volunteer_activism_outlined,
                            tone: r.type == ReportType.lost ? AppColors.coral : AppColors.success,
                            title: r.title,
                            subtitle: '${r.area ?? r.categoryName} · ${r.typeLabel}',
                            onTap: () => context.push('/teaser/${r.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_AreaCluster> _clusters(List<ItemReport> items) {
    final map = <String, List<ItemReport>>{};
    for (final r in items) {
      final key = r.area ?? r.placeName ?? 'Nearby';
      map.putIfAbsent(key, () => []).add(r);
    }
    return map.entries.map((e) {
      final first = e.value.first;
      return _AreaCluster(
        area: e.key,
        count: e.value.length,
        lat: first.lat ?? _hashCoord(e.key, true),
        lng: first.lng ?? _hashCoord(e.key, false),
      );
    }).toList();
  }

  double _hashCoord(String key, bool lat) {
    final n = key.codeUnits.fold<int>(0, (p, c) => p + c);
    return lat ? -1.30 + (n % 40) / 800 : 36.80 + (n % 50) / 800;
  }
}

class _AreaCluster {
  const _AreaCluster({
    required this.area,
    required this.count,
    required this.lat,
    required this.lng,
  });

  final String area;
  final int count;
  final double lat;
  final double lng;
}

class _AreaClusterMap extends StatelessWidget {
  const _AreaClusterMap({
    super.key,
    required this.clusters,
    required this.onSelect,
    this.selectedArea,
  });

  final List<_AreaCluster> clusters;
  final String? selectedArea;
  final ValueChanged<String> onSelect;

  String _short(String area) => area.replaceFirst(RegExp(r'^Near\s+'), '');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x220F4C5C), blurRadius: 16, offset: Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          if (clusters.isEmpty) {
            return ColoredBox(
              color: const Color(0xFFE8E2D6),
              child: Center(
                child: Text(
                  'No published teasers to plot yet.',
                  style: TextStyle(color: AppColors.ink.withOpacity(0.7)),
                ),
              ),
            );
          }
          final lats = clusters.map((c) => c.lat).toList();
          final lngs = clusters.map((c) => c.lng).toList();
          final minLat = lats.reduce((a, b) => a < b ? a : b) - 0.004;
          final maxLat = lats.reduce((a, b) => a > b ? a : b) + 0.004;
          final minLng = lngs.reduce((a, b) => a < b ? a : b) - 0.004;
          final maxLng = lngs.reduce((a, b) => a > b ? a : b) + 0.004;
          Offset point(_AreaCluster c) {
            final dx = (c.lng - minLng) / (maxLng - minLng);
            final dy = (c.lat - minLat) / (maxLat - minLat);
            final x = (24 + dx * (box.maxWidth - 48)).clamp(8.0, box.maxWidth - 8);
            final y = (28 + (1 - dy) * (box.maxHeight - 56)).clamp(8.0, box.maxHeight - 8);
            return Offset(x, y);
          }

          return Stack(
            children: [
              CustomPaint(size: Size(box.maxWidth, box.maxHeight), painter: _CityMapPainter()),
              const Positioned(
                left: 14,
                top: 12,
                child: _MapBadge(label: 'Nairobi · area clusters'),
              ),
              const Positioned(
                right: 14,
                top: 12,
                child: _MapBadge(label: 'N'),
              ),
              ...clusters.map((c) {
                final p = point(c);
                final selected = selectedArea == c.area;
                return Positioned(
                  left: (p.dx - 52).clamp(8, box.maxWidth - 120),
                  top: (p.dy - 22).clamp(36, box.maxHeight - 44),
                  child: GestureDetector(
                    onTap: () => onSelect(c.area),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.coral : AppColors.ink,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Text(
                        '${_short(c.area)} · ${c.count}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFD7E4C7),
    );
    final blocks = Paint()..color = const Color(0xFFE8E2D6);
    for (var y = 16.0; y < size.height; y += 52) {
      for (var x = 10.0; x < size.width; x += 64) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 46, 34), const Radius.circular(6)),
          blocks,
        );
      }
    }
    final park = Paint()..color = const Color(0xFF9FBF8A);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.08, size.height * 0.55, 90, 54), park);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.62, size.height * 0.18, 80, 48), park);
    final water = Paint()
      ..color = const Color(0xFF8FB8C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final river = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.58, size.width * 0.7, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.86, size.width, size.height * 0.7);
    canvas.drawPath(river, water);
    final road = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 2;
    for (var x = 24.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (var y = 20.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CategoryBrowseScreen extends ConsumerWidget {
  const CategoryBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: cats.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load', message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No categories',
              message: 'The catalog will appear once the API is connected.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return _CategoryTile(
                category: c,
                onTap: () {
                  ref.read(searchStateProvider.notifier).setCategory(c.id);
                  context.push('/search/results');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class HubListScreen extends ConsumerWidget {
  const HubListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(hubsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Drop-off desks')),
      body: hubs.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load hubs', message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No public hubs yet',
              message: 'Malls, campuses, and stations will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final h = list[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${h.typeLabel}\n${h.address}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/hubs/${h.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class HubProfileScreen extends ConsumerWidget {
  const HubProfileScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).hub(id),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyState(title: 'Hub unavailable', message: '${snap.error}'),
            );
          }
          return const Scaffold(body: SkeletonList(count: 2));
        }
        final h = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(h.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PhotoCard(imageUrl: h.photoUrl),
              const SizedBox(height: 16),
              StatusChip(label: h.typeLabel, tone: 'success'),
              const SizedBox(height: 8),
              Text(h.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(h.address),
              const SizedBox(height: 16),
              Text('What they store', style: Theme.of(context).textTheme.titleMedium),
              Text(h.whatTheyStore),
              const SizedBox(height: 16),
              Text('Hours', style: Theme.of(context).textTheme.titleMedium),
              ...h.hours.map((x) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(x.weekday),
                    trailing: Text('${x.open} – ${x.close}'),
                  )),
              const SizedBox(height: 8),
              const TrustBanner(
                text: 'Directions open in your maps app. Exact storage bays stay internal.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(category.iconName), color: AppColors.ink, size: 28),
              const Spacer(),
              Text(category.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String name) {
    return switch (name) {
      'badge' => Icons.badge_outlined,
      'account_balance_wallet' => Icons.account_balance_wallet_outlined,
      'smartphone' => Icons.smartphone,
      'vpn_key' => Icons.vpn_key_outlined,
      'diamond' => Icons.diamond_outlined,
      'credit_card' => Icons.credit_card,
      'checkroom' => Icons.checkroom,
      'visibility' => Icons.visibility_outlined,
      'pets' => Icons.pets,
      _ => Icons.category_outlined,
    };
  }
}
