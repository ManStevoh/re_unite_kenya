import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/item_report.dart';
import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label),
            ],
          );
    if (secondary) {
      return OutlinedButton(onPressed: busy ? null : onPressed, child: child);
    }
    return FilledButton(onPressed: busy ? null : onPressed, child: child);
  }
}

/// Cream body with large rounded corners sitting on the ink header.
class RisingCreamSheet extends StatelessWidget {
  const RisingCreamSheet({super.key, required this.child});

  static const double radius = 40;
  static const double overlap = 28;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
        child: child,
      ),
    );
  }
}

class CurvedInkScaffold extends StatelessWidget {
  const CurvedInkScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.showBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final back = showBack ?? Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          ScoopInkHeader(
            title: title,
            subtitle: subtitle,
            actions: actions,
            showBack: back,
            compact: true,
            bottomInset: RisingCreamSheet.overlap + 8,
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
                      child: RisingCreamSheet(child: child),
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

class ScoopInkHeader extends StatelessWidget {
  const ScoopInkHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
    this.bottomInset = 12,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  final double bottomInset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 2, 4, bottomInset),
          child: compact ? _compactBar(context) : _greetingBar(context),
        ),
      ),
    );
  }

  Widget _compactBar(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showBack
                ? IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: (actions?.length ?? 0) > 1 ? 96 : 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [...?actions],
            ),
          ),
        ],
      ),
    );
  }

  Widget _greetingBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.white.withOpacity(0.78), height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ),
        ...?actions,
      ],
    );
  }
}

class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    );
  }
}

/// Ink header + cream body with a scooped curve.
class RisingSheetScaffold extends StatelessWidget {
  const RisingSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return CurvedInkScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: child,
    );
  }
}

class CircleIconRow extends StatelessWidget {
  const CircleIconRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone = AppColors.ink,
    this.unread = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color tone;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tone, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.ink.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (onTap != null)
                Icon(Icons.chevron_right, color: AppColors.ink.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroStatCard extends StatelessWidget {
  const HeroStatCard({
    super.key,
    required this.openCases,
    required this.matches,
    required this.nearby,
    this.onReport,
  });

  final int openCases;
  final int matches;
  final int nearby;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: AppColors.ink.withOpacity(0.18),
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your recovery',
              style: TextStyle(color: AppColors.ink.withOpacity(0.6), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('$openCases', 'open cases'),
                _stat('$matches', 'matches'),
                _stat('$nearby', 'nearby'),
              ],
            ),
            if (onReport != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onReport,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Report an item'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.ink, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(label, style: TextStyle(color: AppColors.ink.withOpacity(0.55), fontSize: 12)),
        ],
      ),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 180, radius: 24),
          SizedBox(height: 12),
          SkeletonBox(width: 220),
          SizedBox(height: 8),
          SkeletonBox(width: 140, height: 12),
        ],
      ),
    );
  }
}

class TrustBanner extends StatelessWidget {
  const TrustBanner({super.key, required this.text, this.icon = Icons.lock_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total, this.label});

  final int step;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? 'Step $step of $total',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 8,
            backgroundColor: AppColors.ink.withOpacity(0.1),
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = 'ink'});

  final String label;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      'success' => AppColors.success,
      'coral' => AppColors.coral,
      'danger' => AppColors.danger,
      'warn' => AppColors.warning,
      _ => AppColors.ink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.imageUrl,
    this.height = 200,
    this.onTap,
    this.heroTag,
  });

  final String? imageUrl;
  final double height;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Container(
                color: AppColors.ink.withOpacity(0.08),
                child: const Icon(Icons.image_outlined, size: 48, color: AppColors.ink),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SkeletonBox(height: 200, radius: 0),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.ink.withOpacity(0.08),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
    final wrapped = heroTag != null ? Hero(tag: heroTag!, child: child) : child;
    return GestureDetector(onTap: onTap, child: wrapped);
  }
}

class TeaserCard extends StatelessWidget {
  const TeaserCard({super.key, required this.item, this.large = true, this.onTap});

  final ItemReport item;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = item.occurredAt == null
        ? ''
        : DateFormat('MMM d').format(item.occurredAt!);
    return InkWell(
      onTap: onTap ?? () => context.push('/teaser/${item.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoCard(imageUrl: item.thumbnail, heroTag: 'teaser-${item.id}'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(
                        label: item.typeLabel,
                        tone: item.type == ReportType.lost ? 'coral' : 'success',
                      ),
                      const SizedBox(width: 8),
                      StatusChip(label: item.categoryName),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [item.area ?? item.placeName, date].where((e) => e != null && e.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.hubName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Held at ${item.hubName}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.total,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.onBack,
    this.busy = false,
  });

  final String title;
  final int step;
  final int total;
  final Widget child;
  final VoidCallback onNext;
  final String nextLabel;
  final VoidCallback? onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: title,
      subtitle: 'Step $step of $total',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: StepProgress(step: step, total: total),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: AppButton(label: nextLabel, onPressed: onNext, busy: busy),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72, this.boxed = true});

  final double size;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      painter: JoinMarkPainter(
        ringColor: boxed ? Colors.white : AppColors.ink,
        fillColor: boxed ? Colors.white : AppColors.coral,
      ),
      child: const SizedBox.expand(),
    );
    if (!boxed) {
      return SizedBox(width: size * 1.4, height: size, child: mark);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: mark,
      ),
    );
  }
}

class JoinMarkPainter extends CustomPainter {
  const JoinMarkPainter({
    this.ringColor = Colors.white,
    this.fillColor = Colors.white,
  });

  final Color ringColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.34;
    final stroke = size.shortestSide * 0.12;
    final cy = size.height / 2;
    final overlap = r * 0.72;
    final c1 = Offset(size.width / 2 - overlap, cy);
    final c2 = Offset(size.width / 2 + overlap, cy);
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c1, r, ring);
    canvas.drawCircle(c2, r, ring);
    final vesica = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: c1, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c2, radius: r)),
    );
    canvas.drawPath(vesica, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant JoinMarkPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.fillColor != fillColor;
}

Future<void> showFlagSheet(
  BuildContext context, {
  required Future<void> Function(String reason) onSubmit,
}) async {
  final reasons = ['Spam or scrape', 'Fake listing', 'Unsafe contact', 'Sensitive photo', 'Other'];
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flag this listing', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('We review reports within 24 hours. Hidden details stay hidden.'),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                title: Text(r),
                onTap: () async {
                  Navigator.pop(ctx);
                  await onSubmit(r);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks. A moderator will review this.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> confirmBlock(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Block this person?'),
      content: Text(
        'You will not see messages from $name. Existing claims stay visible to moderators.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Block')),
      ],
    ),
  );
  return ok ?? false;
}

void openLightbox(BuildContext context, String url, {String? tag}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => _Lightbox(url: url, tag: tag),
    ),
  );
}

class _Lightbox extends StatelessWidget {
  const _Lightbox({required this.url, this.tag});
  final String url;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: tag ?? url,
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }
}

void hapticSuccess() {
  HapticFeedback.mediumImpact();
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceAll('ApiException: ', ''))),
  );
}
