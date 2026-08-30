import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class ActivityHubScreen extends ConsumerWidget {
  const ActivityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.isAuthenticated) {
      return CurvedInkScaffold(
        title: 'Activity',
        showBack: false,
        child: EmptyState(
          title: 'Sign in to see activity',
          message: 'Matches, claims, and pickups appear here after you create an account.',
          actionLabel: 'Log in',
          onAction: () => context.push('/login'),
        ),
      );
    }
    final feed = ref.watch(activityProvider);
    return CurvedInkScaffold(
      title: 'Activity',
      subtitle: 'Matches, claims, and pickups.',
      showBack: false,
      actions: [
        HeaderCircleButton(
          tooltip: 'Inbox',
          icon: Icons.chat_bubble_outline,
          onPressed: () => context.push('/inbox'),
        ),
        HeaderCircleButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_outlined,
          onPressed: () => context.push('/notifications'),
        ),
      ],
      child: feed.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Quiet for now',
              message: 'Matches, claims, and pickups will land in this feed.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, kShellBottomGap),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = items[i];
              return CircleIconRow(
                icon: a.kind == 'match'
                    ? Icons.auto_awesome
                    : a.kind == 'claim'
                        ? Icons.gavel_outlined
                        : Icons.handshake_outlined,
                tone: a.kind == 'claim' ? AppColors.coral : AppColors.ink,
                title: a.title,
                subtitle:
                    '${a.subtitle}${a.at == null ? '' : ' · ${DateFormat.MMMd().add_jm().format(a.at!)}'}',
                onTap: a.route == null ? null : () => context.push(a.route!),
              );
            },
          );
        },
      ),
    );
  }
}

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: inbox.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Inbox unavailable', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No conversations',
              message: 'Chat opens only after a claim is in progress.',
              icon: Icons.forum_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = items[i];
              return CircleIconRow(
                icon: Icons.forum_outlined,
                title: c.title,
                subtitle: c.preview,
                unread: c.unread > 0,
                trailing: c.unread > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.coral,
                        child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    : null,
                onTap: () => context.push('/inbox/${c.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(repositoryProvider).messages(widget.id);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            tooltip: 'Block',
            onPressed: () async {
              final ok = await confirmBlock(context, 'this person');
              if (ok && mounted) {
                await ref.read(repositoryProvider).blockUser('peer');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked. Moderators can still see the thread.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.block),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.successSoft,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Stay in-app. Do not share phone numbers until you both confirm a handover.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return snap.hasError
                      ? EmptyState(title: 'Messages unavailable', message: '${snap.error}')
                      : const SkeletonList(count: 3);
                }
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return const EmptyState(
                    title: 'No messages yet',
                    message: 'Keep it about the item. Staff may review flagged threads.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.mine as bool;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.ink : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m.body as String,
                          style: TextStyle(color: mine ? Colors.white : null),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: () async {
                      final text = _input.text.trim();
                      if (text.isEmpty) return;
                      await ref.read(repositoryProvider).sendMessage(widget.id, text);
                      _input.clear();
                      setState(() {
                        _future = ref.read(repositoryProvider).messages(widget.id);
                      });
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notes.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No notifications',
              message: 'Push is stubbed in v1. In-app alerts still appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = items[i];
              return CircleIconRow(
                icon: Icons.notifications_outlined,
                title: n.title,
                subtitle: n.body,
                unread: !n.read,
                onTap: () async {
                  await ref.read(repositoryProvider).markNotificationRead(n.id);
                  ref.invalidate(notificationsProvider);
                  if (n.route != null && context.mounted) context.push(n.route!);
                },
              );
            },
          );
        },
      ),
    );
  }
}
