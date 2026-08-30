import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';

class ReportChooserScreen extends ConsumerWidget {
  const ReportChooserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: EmptyState(
          title: 'Sign in to report',
          message: 'Guests can browse teasers. Create an account to file a lost or found report.',
          actionLabel: 'Log in',
          onAction: () => context.go('/login'),
        ),
      );
    }
    if (!session.user!.emailVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: EmptyState(
          title: 'Verify your email first',
          message: 'Unverified accounts can browse only. This keeps fake reports down.',
          actionLabel: 'Verify',
          onAction: () => context.push('/verify-email'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('What happened?')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BigChoice(
            title: 'I lost something',
            body: 'Describe it. Unique marks stay hidden until a claim.',
            icon: Icons.search,
            color: AppColors.coral,
            onTap: () {
              ref.read(reportDraftProvider.notifier).reset(ReportType.lost);
              context.push('/report/lost/category');
            },
          ),
          const SizedBox(height: 16),
          _BigChoice(
            title: 'I found something',
            body: 'Start with a photo. Do not photograph ID numbers.',
            icon: Icons.volunteer_activism_outlined,
            color: AppColors.success,
            onTap: () {
              ref.read(reportDraftProvider.notifier).reset(ReportType.found);
              context.push('/report/found/photo');
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/drafts'),
            child: const Text('Resume a draft'),
          ),
        ],
      ),
    );
  }
}

class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LostCategoryScreen extends ConsumerWidget {
  const LostCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return WizardScaffold(
      title: 'Category',
      step: 1,
      total: 6,
      onNext: () {
        final d = ref.read(reportDraftProvider);
        if (d.categoryId == null) {
          showError(context, 'Pick a category to continue.');
          return;
        }
        context.push('/report/lost/details');
      },
      child: cats.when(
        loading: () => const SkeletonList(count: 3),
        error: (e, _) => Text('$e'),
        data: (list) {
          final selected = ref.watch(reportDraftProvider).categoryId;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list
                .map(
                  (c) => ChoiceChip(
                    label: Text(c.name),
                    selected: selected == c.id,
                    onSelected: (_) => ref.read(reportDraftProvider.notifier).patch((d) {
                      d.categoryId = c.id;
                      d.categoryName = c.name;
                    }),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class LostDetailsScreen extends ConsumerStatefulWidget {
  const LostDetailsScreen({super.key});

  @override
  ConsumerState<LostDetailsScreen> createState() => _LostDetailsScreenState();
}

class _LostDetailsScreenState extends ConsumerState<LostDetailsScreen> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _color;
  late final TextEditingController _brand;

  @override
  void initState() {
    super.initState();
    final d = ref.read(reportDraftProvider);
    _title = TextEditingController(text: d.title);
    _desc = TextEditingController(text: d.description);
    _color = TextEditingController(text: d.color);
    _brand = TextEditingController(text: d.brand);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _color.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Details',
      step: 2,
      total: 6,
      onNext: () {
        if (_title.text.trim().length < 3) {
          showError(context, 'Give the item a short public title.');
          return;
        }
        ref.read(reportDraftProvider.notifier).patch((d) {
          d.title = _title.text.trim();
          d.description = _desc.text.trim();
          d.color = _color.text.trim();
          d.brand = _brand.text.trim();
        });
        context.push('/report/lost/marks');
      },
      child: Column(
        children: [
          AppField(controller: _title, label: 'Public title', hint: 'Black leather wallet'),
          const SizedBox(height: 12),
          AppField(controller: _desc, label: 'Public blurb', maxLines: 4),
          const SizedBox(height: 12),
          AppField(controller: _color, label: 'Color'),
          const SizedBox(height: 12),
          AppField(controller: _brand, label: 'Brand / model'),
        ],
      ),
    );
  }
}

class LostMarksScreen extends ConsumerStatefulWidget {
  const LostMarksScreen({super.key});

  @override
  ConsumerState<LostMarksScreen> createState() => _LostMarksScreenState();
}

class _LostMarksScreenState extends ConsumerState<LostMarksScreen> {
  late final TextEditingController _marks;
  late final TextEditingController _serial;

  @override
  void initState() {
    super.initState();
    final d = ref.read(reportDraftProvider);
    _marks = TextEditingController(text: d.hiddenNotes);
    _serial = TextEditingController(text: d.serial);
  }

  @override
  void dispose() {
    _marks.dispose();
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Hidden marks',
      step: 3,
      total: 6,
      onNext: () {
        ref.read(reportDraftProvider.notifier).patch((d) {
          d.hiddenNotes = _marks.text.trim();
          d.serial = _serial.text.trim();
        });
        context.push('/report/lost/location');
      },
      child: Column(
        children: [
          const TrustBanner(
            text: 'Only used to verify you. These never appear on the public teaser.',
          ),
          const SizedBox(height: 16),
          AppField(
            controller: _marks,
            label: 'Distinguishing marks',
            hint: 'Initials, engraving, a sticker…',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          AppField(controller: _serial, label: 'Serial or ID number (hidden)'),
        ],
      ),
    );
  }
}

class LostLocationScreen extends ConsumerStatefulWidget {
  const LostLocationScreen({super.key});

  @override
  ConsumerState<LostLocationScreen> createState() => _LostLocationScreenState();
}

class _LostLocationScreenState extends ConsumerState<LostLocationScreen> {
  late final TextEditingController _place;

  @override
  void initState() {
    super.initState();
    _place = TextEditingController(text: ref.read(reportDraftProvider).placeName);
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final when = ref.watch(reportDraftProvider).occurredAt;
    return WizardScaffold(
      title: 'Location & time',
      step: 4,
      total: 6,
      onNext: () {
        if (_place.text.trim().isEmpty) {
          showError(context, 'Add a last-seen place. Public cards will coarsen it.');
          return;
        }
        ref.read(reportDraftProvider.notifier).patch((d) => d.placeName = _place.text.trim());
        context.push('/report/lost/photos');
      },
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.ink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: Text('Map pin placeholder — exact pin stays private.')),
          ),
          const SizedBox(height: 16),
          AppField(controller: _place, label: 'Last seen', hint: 'City Mall, Level 2 food court'),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Theme.of(context).cardColor,
            title: Text(when == null ? 'When did you last have it?' : DateFormat.yMMMd().add_jm().format(when)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                initialDate: when ?? DateTime.now(),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(when ?? DateTime.now()),
              );
              final dt = DateTime(
                date.year,
                date.month,
                date.day,
                time?.hour ?? 12,
                time?.minute ?? 0,
              );
              ref.read(reportDraftProvider.notifier).patch((d) => d.occurredAt = dt);
            },
          ),
        ],
      ),
    );
  }
}

class LostPhotosScreen extends ConsumerWidget {
  const LostPhotosScreen({super.key});

  Future<void> _pick(WidgetRef ref, ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    ref.read(reportDraftProvider.notifier).patch((d) {
      d.photos = [...d.photos, file.path];
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(reportDraftProvider).photos;
    return WizardScaffold(
      title: 'Photos',
      step: 5,
      total: 6,
      nextLabel: 'Review',
      onNext: () => context.push('/report/lost/review'),
      child: Column(
        children: [
          const TrustBanner(
            icon: Icons.photo_filter,
            text: 'Show the item. Hide faces, barcodes, and document numbers.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...photos.map(
                (p) => Chip(
                  label: Text(p.split('/').last, overflow: TextOverflow.ellipsis),
                  onDeleted: () => ref.read(reportDraftProvider.notifier).patch((d) {
                    d.photos = d.photos.where((x) => x != p).toList();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Take photo',
            icon: Icons.photo_camera_outlined,
            onPressed: () => _pick(ref, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Choose from gallery',
            secondary: true,
            icon: Icons.photo_library_outlined,
            onPressed: () => _pick(ref, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.read(reportDraftProvider.notifier).patch((d) {
              d.photos = [...d.photos, img('draft-photo-${d.photos.length}')];
            }),
            child: const Text('Add demo photo (no camera)'),
          ),
        ],
      ),
    );
  }
}

class LostReviewScreen extends ConsumerStatefulWidget {
  const LostReviewScreen({super.key});

  @override
  ConsumerState<LostReviewScreen> createState() => _LostReviewScreenState();
}

class _LostReviewScreenState extends ConsumerState<LostReviewScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(reportDraftProvider);
    return WizardScaffold(
      title: 'Review',
      step: 6,
      total: 6,
      nextLabel: 'Submit report',
      busy: _busy,
      onNext: () async {
        setState(() => _busy = true);
        try {
          final created = await ref.read(repositoryProvider).createReport(d);
          await ref.read(repositoryProvider).submitReport(created.id);
          ref.invalidate(myReportsProvider);
          ref.invalidate(nearbyProvider);
          if (mounted) context.go('/reports/${created.id}');
        } catch (e) {
          if (mounted) showError(context, e);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Public teaser', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(d.title.isEmpty ? 'Untitled' : d.title),
              subtitle: Text(
                '${d.categoryName ?? 'Item'} · ${d.color} · Near ${d.placeName.split(',').first}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Private (only you + verified claim)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Marks: ${d.hiddenNotes.isEmpty ? '—' : d.hiddenNotes}'),
          Text('Serial: ${d.serial.isEmpty ? '—' : d.serial}'),
          const SizedBox(height: 16),
          SwitchListTile(
            value: d.visibility == Visibility.publicTeaser,
            title: const Text('Show a public teaser'),
            subtitle: const Text('Off = match-only, no public card.'),
            onChanged: (v) => ref.read(reportDraftProvider.notifier).patch((x) {
              x.visibility = v ? Visibility.publicTeaser : Visibility.privateMatchOnly;
            }),
          ),
        ],
      ),
    );
  }
}

class FoundPhotoScreen extends ConsumerWidget {
  const FoundPhotoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(reportDraftProvider).photos;
    return WizardScaffold(
      title: 'Photo first',
      step: 1,
      total: 4,
      onNext: () {
        if (photos.isEmpty) {
          showError(context, 'Add at least one photo — lock screens and covered numbers only.');
          return;
        }
        context.push('/report/found/details');
      },
      child: Column(
        children: [
          const TrustBanner(text: 'Do not post ID numbers, card digits, or unlocked screens.'),
          const SizedBox(height: 16),
          Text('${photos.length} photo(s) attached'),
          const SizedBox(height: 12),
          AppButton(
            label: 'Open camera',
            icon: Icons.photo_camera_outlined,
            onPressed: () async {
              final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
              if (file != null) {
                ref.read(reportDraftProvider.notifier).patch((d) => d.photos = [...d.photos, file.path]);
              }
            },
          ),
          TextButton(
            onPressed: () => ref.read(reportDraftProvider.notifier).patch((d) {
              d.photos = [...d.photos, img('found-${d.photos.length}')];
            }),
            child: const Text('Use a demo photo'),
          ),
        ],
      ),
    );
  }
}

class FoundDetailsScreen extends ConsumerStatefulWidget {
  const FoundDetailsScreen({super.key});

  @override
  ConsumerState<FoundDetailsScreen> createState() => _FoundDetailsScreenState();
}

class _FoundDetailsScreenState extends ConsumerState<FoundDetailsScreen> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _color;
  late final TextEditingController _place;

  @override
  void initState() {
    super.initState();
    final d = ref.read(reportDraftProvider);
    _title = TextEditingController(text: d.title);
    _desc = TextEditingController(text: d.description);
    _color = TextEditingController(text: d.color);
    _place = TextEditingController(text: d.placeName);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _color.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final selected = ref.watch(reportDraftProvider).categoryId;
    return WizardScaffold(
      title: 'Found details',
      step: 2,
      total: 4,
      onNext: () {
        if (_title.text.trim().length < 3 || selected == null) {
          showError(context, 'Add a title and category.');
          return;
        }
        ref.read(reportDraftProvider.notifier).patch((d) {
          d.title = _title.text.trim();
          d.description = _desc.text.trim();
          d.color = _color.text.trim();
          d.placeName = _place.text.trim();
        });
        context.push('/report/found/custody');
      },
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: cats
                .map(
                  (c) => ChoiceChip(
                    label: Text(c.name),
                    selected: selected == c.id,
                    onSelected: (_) => ref.read(reportDraftProvider.notifier).patch((d) {
                      d.categoryId = c.id;
                      d.categoryName = c.name;
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          AppField(controller: _title, label: 'Title'),
          const SizedBox(height: 12),
          AppField(controller: _desc, label: 'Public blurb', maxLines: 3),
          const SizedBox(height: 12),
          AppField(controller: _color, label: 'Color'),
          const SizedBox(height: 12),
          AppField(controller: _place, label: 'Where you found it'),
        ],
      ),
    );
  }
}

class FoundCustodyScreen extends ConsumerWidget {
  const FoundCustodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(reportDraftProvider);
    final hubs = ref.watch(hubsProvider).valueOrNull ?? [];
    return WizardScaffold(
      title: 'Custody',
      step: 3,
      total: 4,
      onNext: () => context.push('/report/found/review'),
      child: Column(
        children: [
          RadioListTile<Custody>(
            value: Custody.withFinder,
            groupValue: d.custody,
            title: const Text('I will keep it safe'),
            onChanged: (v) =>
                ref.read(reportDraftProvider.notifier).patch((x) => x.custody = v!),
          ),
          RadioListTile<Custody>(
            value: Custody.atHub,
            groupValue: d.custody,
            title: const Text('Drop it at a hub'),
            onChanged: (v) =>
                ref.read(reportDraftProvider.notifier).patch((x) => x.custody = v!),
          ),
          if (d.custody == Custody.atHub)
            ...hubs.map(
              (h) => RadioListTile<String>(
                value: h.id,
                groupValue: d.hubId,
                title: Text(h.name),
                subtitle: Text(h.address),
                onChanged: (v) =>
                    ref.read(reportDraftProvider.notifier).patch((x) => x.hubId = v),
              ),
            ),
        ],
      ),
    );
  }
}

class FoundReviewScreen extends ConsumerStatefulWidget {
  const FoundReviewScreen({super.key});

  @override
  ConsumerState<FoundReviewScreen> createState() => _FoundReviewScreenState();
}

class _FoundReviewScreenState extends ConsumerState<FoundReviewScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(reportDraftProvider);
    return WizardScaffold(
      title: 'Review found item',
      step: 4,
      total: 4,
      nextLabel: 'Submit',
      busy: _busy,
      onNext: () async {
        setState(() => _busy = true);
        try {
          final created = await ref.read(repositoryProvider).createReport(d);
          await ref.read(repositoryProvider).submitReport(created.id);
          ref.invalidate(myReportsProvider);
          if (mounted) context.go('/reports/${created.id}');
        } catch (e) {
          if (mounted) showError(context, e);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TrustBanner(text: 'Reminder: don’t post ID numbers on the public card.'),
          const SizedBox(height: 16),
          Text(d.title, style: Theme.of(context).textTheme.titleLarge),
          Text('${d.categoryName} · ${d.color}'),
          Text(d.placeName),
          Text(d.custody == Custody.atHub ? 'Drop-off at a hub' : 'Staying with you'),
        ],
      ),
    );
  }
}
