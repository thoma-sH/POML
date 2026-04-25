import 'package:first_flutter_app/features/activity/data/repos/mock_activity_repo.dart';
import 'package:first_flutter_app/features/activity/domain/entities/activity_trace.dart';
import 'package:first_flutter_app/features/activity/presentation/cubits/activity_cubit.dart';
import 'package:first_flutter_app/features/activity/presentation/cubits/activity_states.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/glass_surface.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TracesPage extends StatelessWidget {
  const TracesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityCubit>(
      create: (_) => ActivityCubit(repo: MockActivityRepo())..loadInitial(),
      child: const _TracesView(),
    );
  }
}

class _TracesView extends StatefulWidget {
  const _TracesView();

  @override
  State<_TracesView> createState() => _TracesViewState();
}

class _TracesViewState extends State<_TracesView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 320) {
      context.read<ActivityCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ActivityCubit, ActivityState>(
          builder: (context, state) => switch (state) {
            ActivityInitial() ||
            ActivityLoading() => const _LoadingView(),
            ActivityFailure(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<ActivityCubit>().refresh(),
              ),
            ActivityLoaded(:final traces) when traces.isEmpty =>
                const _EmptyView(),
            ActivityLoaded(:final traces, :final isLoadingMore) =>
                _TracesList(
                  traces: traces,
                  isLoadingMore: isLoadingMore,
                  scrollController: _scroll,
                ),
          },
        ),
      ),
    );
  }
}

class _TracesList extends StatelessWidget {
  const _TracesList({
    required this.traces,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<ActivityTrace> traces;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final sections = _groupByBucket(traces);
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        for (final section in sections) ...[
          SliverToBoxAdapter(child: _BucketLabel(label: section.label)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(child: _TraceGroup(traces: section.traces)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
        if (isLoadingMore)
          const SliverToBoxAdapter(child: _LoadMoreIndicator()),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.huge + AppSpacing.xl),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          TapBounce(
            scaleTo: 0.85,
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.arrowLeft,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'traces',
            style: t.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              'a deep history',
              style: t.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketLabel extends StatelessWidget {
  const _BucketLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _TraceGroup extends StatelessWidget {
  const _TraceGroup({required this.traces});

  final List<ActivityTrace> traces;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassSurface(
        thickness: GlassThickness.regular,
        borderRadius: AppSpacing.md,
        child: Column(
          children: [
            for (var i = 0; i < traces.length; i++) ...[
              _TraceRow(trace: traces[i]),
              if (i < traces.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderSubtle,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.trace});

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
            child: Icon(_iconFor(trace.kind), color: color, size: 13),
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

IconData _iconFor(TraceKind kind) {
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

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'no traces yet — your first vote will land here.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TapBounce(
              scaleTo: 0.92,
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'try again',
                  style: t.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── time bucketing ─────────────────────────────────────────

class _Section {
  const _Section({required this.label, required this.traces});
  final String label;
  final List<ActivityTrace> traces;
}

List<_Section> _groupByBucket(List<ActivityTrace> traces) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(const Duration(days: 7));
  final monthStart = today.subtract(const Duration(days: 30));

  final groups = <String, List<ActivityTrace>>{
    'today': [],
    'yesterday': [],
    'this week': [],
    'this month': [],
    'earlier': [],
  };

  for (final t in traces) {
    if (!t.createdAt.isBefore(today)) {
      groups['today']!.add(t);
    } else if (!t.createdAt.isBefore(yesterday)) {
      groups['yesterday']!.add(t);
    } else if (!t.createdAt.isBefore(weekStart)) {
      groups['this week']!.add(t);
    } else if (!t.createdAt.isBefore(monthStart)) {
      groups['this month']!.add(t);
    } else {
      groups['earlier']!.add(t);
    }
  }

  return groups.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => _Section(label: e.key, traces: e.value))
      .toList(growable: false);
}
