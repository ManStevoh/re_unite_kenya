import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = ref.watch(helpProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Help center')),
      body: help.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Help unavailable', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No articles yet',
              message: 'CMS content will appear here from /cms.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = items[i];
              return Card(
                child: ListTile(
                  title: Text(a.title),
                  subtitle: Text(a.excerpt ?? ''),
                  onTap: () => context.push('/help/${a.slug}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).cms(slug),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? EmptyState(title: 'Article missing', message: '${snap.error}')
                : const SkeletonList(count: 2),
          );
        }
        final a = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(a.title)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(a.body, style: const TextStyle(height: 1.45)),
            ],
          ),
        );
      },
    );
  }
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact support')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _sent
            ? const EmptyState(
                title: 'Ticket sent',
                message: 'A support agent will reply in the admin queue.',
                icon: Icons.mark_email_read_outlined,
              )
            : Column(
                children: [
                  AppField(controller: _subject, label: 'Subject'),
                  const SizedBox(height: 12),
                  AppField(controller: _body, label: 'How can we help?', maxLines: 6),
                  const Spacer(),
                  AppButton(
                    label: 'Send',
                    busy: _busy,
                    onPressed: () async {
                      if (_subject.text.trim().isEmpty || _body.text.trim().length < 8) {
                        showError(context, 'Add a subject and a short description.');
                        return;
                      }
                      setState(() => _busy = true);
                      await ref
                          .read(repositoryProvider)
                          .contactSupport(_subject.text.trim(), _body.text.trim());
                      setState(() {
                        _busy = false;
                        _sent = true;
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArticleScreen(slug: slug);
  }
}
