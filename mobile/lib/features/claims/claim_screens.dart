import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key, this.reportId});
  final String? reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider(reportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matches.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyState(title: 'Could not load matches', message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No matches yet',
              message: 'We score category, color, time, and area. Matching never auto-closes a case.',
              icon: Icons.auto_awesome_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final m = items[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(m.otherTitle ?? 'Candidate'),
                  subtitle: Text('${m.score}% · ${m.reasons.join(' · ')}'),
                  trailing: StatusChip(label: '${m.score}', tone: 'coral'),
                  onTap: () => context.push('/matches/${m.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MatchCompareScreen extends ConsumerWidget {
  const MatchCompareScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).matches(),
      builder: (context, snap) {
        final match = snap.data?.where((m) => m.id == id).firstOrNull;
        if (match == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? EmptyState(title: 'Unavailable', message: '${snap.error}')
                : const SkeletonList(count: 1),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Compare')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const TrustBanner(text: 'Side-by-side teasers only. Hidden marks never leak here.'),
              const SizedBox(height: 16),
              Text('Your report', style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: ListTile(
                  title: Text('Report ${match.myReportId}'),
                  subtitle: const Text('Your hidden fields stay on your owner screen.'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Suggested match', style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: ListTile(
                  title: Text(match.otherTitle ?? 'Item'),
                  subtitle: Text('${match.otherArea} · ${match.otherCategory}'),
                ),
              ),
              const SizedBox(height: 8),
              ...match.reasons.map((r) => ListTile(leading: const Icon(Icons.check), title: Text(r))),
              const SizedBox(height: 12),
              AppButton(
                label: 'Start a claim',
                onPressed: () => context.push('/claims/start/${match.otherReportId}'),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Open teaser',
                secondary: true,
                onPressed: () => context.push('/teaser/${match.otherReportId}'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StartClaimScreen extends ConsumerStatefulWidget {
  const StartClaimScreen({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<StartClaimScreen> createState() => _StartClaimScreenState();
}

class _StartClaimScreenState extends ConsumerState<StartClaimScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start claim')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prove it — don’t guess',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'You have ${AppConstants.claimAttemptLimit} attempts. Answers are checked by the finder or hub. Making things up can restrict your account.',
            ),
            const SizedBox(height: 16),
            const TrustBanner(text: 'Never pay a finder to “hold” an item. Handover is coordinated in-app.'),
            const Spacer(),
            AppButton(
              label: 'I understand — continue',
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  final claim = await ref.read(repositoryProvider).startClaim(widget.reportId);
                  if (mounted) context.push('/claims/questions/${claim.id}');
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

class ChallengeQuestionsScreen extends ConsumerStatefulWidget {
  const ChallengeQuestionsScreen({super.key, required this.claimId});
  final String claimId;

  @override
  ConsumerState<ChallengeQuestionsScreen> createState() => _ChallengeQuestionsScreenState();
}

class _ChallengeQuestionsScreenState extends ConsumerState<ChallengeQuestionsScreen> {
  int _index = 0;
  final _answers = <String, String>{};
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = demoQuestions[_index];
    return WizardScaffold(
      title: 'Question ${_index + 1}',
      step: _index + 1,
      total: demoQuestions.length,
      nextLabel: _index == demoQuestions.length - 1 ? 'Save answers' : 'Next question',
      busy: _busy,
      onNext: () async {
        _answers[q.id] = _controller.text.trim();
        if (_index < demoQuestions.length - 1) {
          setState(() {
            _index++;
            _controller.text = _answers[demoQuestions[_index].id] ?? '';
          });
          return;
        }
        setState(() => _busy = true);
        try {
          await ref.read(repositoryProvider).submitAnswers(widget.claimId, _answers);
          if (mounted) context.push('/claims/evidence/${widget.claimId}');
        } catch (e) {
          if (mounted) showError(context, e);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
          if (q.hint != null) ...[
            const SizedBox(height: 8),
            Text(q.hint!),
          ],
          const SizedBox(height: 20),
          AppField(controller: _controller, label: 'Your answer', maxLines: 4),
        ],
      ),
    );
  }
}

class ClaimEvidenceScreen extends ConsumerWidget {
  const ClaimEvidenceScreen({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Optional: a purchase receipt or older photo of the item. Not a selfie with an ID unless a hub asks in person.',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Skip for now',
              onPressed: () => context.go('/claims/submitted/$claimId'),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Attach demo receipt',
              secondary: true,
              onPressed: () async {
                await ref.read(repositoryProvider).uploadEvidence(claimId, [img('receipt')]);
                if (context.mounted) context.go('/claims/submitted/$claimId');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ClaimSubmittedScreen extends StatelessWidget {
  const ClaimSubmittedScreen({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim sent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top, size: 64, color: AppColors.ink),
            const SizedBox(height: 16),
            Text('Waiting on a human', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'The finder or hub will review your answers. You will get a notification — we never auto-approve.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              label: 'View claim',
              onPressed: () => context.go('/claims/$claimId'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClaimDetailScreen extends ConsumerWidget {
  const ClaimDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).getClaim(id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? EmptyState(title: 'Claim unavailable', message: '${snap.error}')
                : const SkeletonList(count: 2),
          );
        }
        final c = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Claim')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              StatusChip(label: c.statusLabel, tone: 'coral'),
              const SizedBox(height: 8),
              Text(c.reportTitle ?? 'Item claim', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              ...c.timeline.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle, size: 10, color: AppColors.ink),
                  title: Text(e.label),
                  subtitle: Text(DateFormat.MMMd().add_jm().format(e.at)),
                ),
              ),
              const SizedBox(height: 12),
              if (c.status == ClaimStatus.accepted || c.status == ClaimStatus.handoverScheduled)
                AppButton(
                  label: 'Set up handover',
                  onPressed: () => context.push('/handover/setup/${c.id}'),
                ),
              if (c.status == ClaimStatus.submitted)
                AppButton(
                  label: 'Review as finder / hub',
                  secondary: true,
                  onPressed: () => context.push('/claims/${c.id}/review'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewClaimScreen extends ConsumerStatefulWidget {
  const ReviewClaimScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ReviewClaimScreen> createState() => _ReviewClaimScreenState();
}

class _ReviewClaimScreenState extends ConsumerState<ReviewClaimScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).getClaim(widget.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: SkeletonList(count: 2));
        }
        final c = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Review claim')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const TrustBanner(text: 'Accept only if the answers match what you hid on the item.'),
              const SizedBox(height: 12),
              ...c.answers.entries.map(
                (e) => ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Accept claim',
                busy: _busy,
                onPressed: () async {
                  setState(() => _busy = true);
                  try {
                    await ref.read(repositoryProvider).reviewClaim(widget.id, accept: true);
                    if (mounted) context.push('/handover/setup/${widget.id}');
                  } catch (e) {
                    if (mounted) showError(context, e);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Request more info',
                secondary: true,
                onPressed: () => context.push('/claims/${widget.id}/more-info'),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(repositoryProvider).reviewClaim(widget.id, accept: false);
                  if (context.mounted) context.pop();
                },
                child: const Text('Reject'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MoreInfoScreen extends ConsumerStatefulWidget {
  const MoreInfoScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<MoreInfoScreen> createState() => _MoreInfoScreenState();
}

class _MoreInfoScreenState extends ConsumerState<MoreInfoScreen> {
  final _msg = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request more info')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppField(
              controller: _msg,
              label: 'What should they add?',
              hint: 'Describe the keychain, not the address.',
              maxLines: 5,
            ),
            const Spacer(),
            AppButton(
              label: 'Send request',
              busy: _busy,
              onPressed: () async {
                if (_msg.text.trim().length < 4) {
                  showError(context, 'Ask a specific question.');
                  return;
                }
                setState(() => _busy = true);
                try {
                  await ref.read(repositoryProvider).requestMoreInfo(widget.id, _msg.text.trim());
                  if (mounted) context.pop();
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

class HandoverSetupScreen extends ConsumerStatefulWidget {
  const HandoverSetupScreen({super.key, required this.claimId});
  final String claimId;

  @override
  ConsumerState<HandoverSetupScreen> createState() => _HandoverSetupScreenState();
}

class _HandoverSetupScreenState extends ConsumerState<HandoverSetupScreen> {
  HandoverType _type = HandoverType.hubPickup;
  final _place = TextEditingController(text: 'City Mall Lost & Found, Level 2');
  DateTime _when = DateTime.now().add(const Duration(hours: 20));
  bool _busy = false;

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handover setup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...HandoverType.values.map(
            (t) => RadioListTile<HandoverType>(
              value: t,
              groupValue: _type,
              title: Text(t.name),
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),
          AppField(controller: _place, label: 'Place'),
          const SizedBox(height: 12),
          ListTile(
            title: Text(DateFormat.yMMMd().add_jm().format(_when)),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDate: _when,
              );
              if (d == null || !mounted) return;
              setState(() => _when = DateTime(d.year, d.month, d.day, 15));
            },
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Schedule',
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                final h = await ref.read(repositoryProvider).setupHandover(
                      claimId: widget.claimId,
                      type: _type,
                      place: _place.text.trim(),
                      when: _when,
                    );
                if (mounted) context.go('/handover/confirm/${h.id}');
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

class HandoverConfirmScreen extends ConsumerStatefulWidget {
  const HandoverConfirmScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<HandoverConfirmScreen> createState() => _HandoverConfirmScreenState();
}

class _HandoverConfirmScreenState extends ConsumerState<HandoverConfirmScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).getHandover(widget.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: snap.hasError
                ? EmptyState(title: 'Handover unavailable', message: '${snap.error}')
                : const SkeletonList(count: 1),
          );
        }
        final h = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Confirm handover')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Meet-up code', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  h.code ?? '——',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(h.place ?? ''),
                if (h.when != null) Text(DateFormat.yMMMd().add_jm().format(h.when!)),
                const SizedBox(height: 16),
                Text('Owner confirmed: ${h.ownerConfirmed ? 'yes' : 'not yet'}'),
                Text('Finder / hub confirmed: ${h.finderConfirmed ? 'yes' : 'not yet'}'),
                const Spacer(),
                AppButton(
                  label: 'I am the owner — confirm',
                  busy: _busy,
                  onPressed: () => _confirm(true, h.claimId),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'I am the finder / hub — confirm',
                  secondary: true,
                  onPressed: () => _confirm(false, h.claimId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirm(bool asOwner, String claimId) async {
    setState(() => _busy = true);
    try {
      final next = await ref.read(repositoryProvider).confirmHandover(widget.id, asOwner: asOwner);
      hapticSuccess();
      if (!mounted) return;
      if (next.status == HandoverStatus.completed) {
        context.go('/recovery/$claimId');
      } else {
        setState(() {});
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class RecoverySuccessScreen extends StatelessWidget {
  const RecoverySuccessScreen({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.celebration_outlined, size: 72, color: AppColors.success),
              const SizedBox(height: 16),
              Text('Returned', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Thank you for using the recovery network. Sharing is optional — never required.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: 'Send a thank-you note',
                onPressed: () => context.push('/tip/$claimId'),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Back home',
                secondary: true,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipScreen extends ConsumerStatefulWidget {
  const TipScreen({super.key, required this.claimId});
  final String claimId;

  @override
  ConsumerState<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends ConsumerState<TipScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thank you')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Payments are Phase 2. For now you can leave a short thank-you that the finder or hub will see.',
            ),
            const SizedBox(height: 16),
            AppField(controller: _note, label: 'Note', maxLines: 4),
            const Spacer(),
            AppButton(
              label: 'Send note',
              onPressed: () async {
                await ref.read(repositoryProvider).sendTip(widget.claimId, _note.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank-you saved. Payments coming later.')),
                  );
                  context.go('/home');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
