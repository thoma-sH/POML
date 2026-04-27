import 'package:first_flutter_app/features/activity/domain/entities/activity_trace.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// A single trace row used by both the profile "recent traces" preview
// and the full Traces page. Renders a colored kind-glyph, the trace text,
// and a relative timestamp on the right.
class TraceRow extends StatelessWidget {
  const TraceRow({required this.trace, super.key});

  final ActivityTrace trace;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = trace.colorArgb != null
        ? Color(trace.colorArgb!)
        : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Icon(iconForTraceKind(trace.kind), color: color, size: 13),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              trace.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            trace.timeAgoString,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// Maps a TraceKind to the Phosphor glyph used in the row's circular badge.
// Kept as a top-level helper (not an entity getter) because IconData is
// Flutter-coupled and entities are intentionally pure Dart.
IconData iconForTraceKind(TraceKind kind) {
  switch (kind) {
    case TraceKind.votedFits:
      return PhosphorIconsFill.check;
    case TraceKind.votedDoesntFit:
      return PhosphorIconsLight.x;
    case TraceKind.saved:
      return PhosphorIconsLight.bookmarkSimple;
    case TraceKind.posted:
      return PhosphorIconsLight.image;
    case TraceKind.wonGame:
      return PhosphorIconsFill.gameController;
    case TraceKind.lostGame:
      return PhosphorIconsLight.gameController;
    case TraceKind.followed:
      return PhosphorIconsLight.userPlus;
    case TraceKind.other:
      return PhosphorIconsLight.sparkle;
  }
}
