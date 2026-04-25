import 'package:first_flutter_app/features/auth/domain/entities/app_user.dart';
import 'package:first_flutter_app/features/feed/data/repos/mock_feed_repo.dart';
import 'package:first_flutter_app/features/feed/data/repos/supabase_feed_repo.dart';
import 'package:first_flutter_app/features/feed/domain/repos/feed_repo.dart';
import 'package:first_flutter_app/features/feed/presentation/cubits/feed_cubit.dart';
import 'package:first_flutter_app/features/feed/presentation/cubits/feed_states.dart';
import 'package:first_flutter_app/features/feed/presentation/widgets/immersive_feed_tile.dart';
import 'package:first_flutter_app/features/game/presentation/pages/friend_or_foe_page.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/frost_panel.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _headerReservedHeight = 52;
const double _navBarReservedHeight = 80;

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeedCubit>(
      create: (_) => FeedCubit(feedRepo: _resolveRepo())..loadInitial(),
      child: const _HomeFeedView(),
    );
  }

  static FeedRepo _resolveRepo() =>
      kDebugMode ? MockFeedRepo() : SupabaseFeedRepo();
}

class _HomeFeedView extends StatefulWidget {
  const _HomeFeedView();

  @override
  State<_HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<_HomeFeedView> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController()..addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _controller.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _currentIndex) setState(() => _currentIndex = rounded);

    final cubit = context.read<FeedCubit>();
    final state = cubit.state;
    if (state is FeedLoaded &&
        state.hasMore &&
        !state.isLoadingMore &&
        rounded >= state.posts.length - 2) {
      cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).padding.bottom + _navBarReservedHeight;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          return Stack(
            children: [
              switch (state) {
                FeedInitial() || FeedLoading() => const _FeedLoadingView(),
                FeedFailure(:final message) => _FeedErrorView(
                    message: message,
                    onRetry: () => context.read<FeedCubit>().refresh(),
                  ),
                FeedLoaded(:final posts) when posts.isEmpty =>
                    const _FeedEmptyView(),
                FeedLoaded(:final posts) => PageView.builder(
                    controller: _controller,
                    scrollDirection: Axis.vertical,
                    physics: const _ImmersivePageScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => ImmersiveFeedTile(
                      post: posts[i],
                      bottomInset: bottomInset,
                      headerInset: _headerReservedHeight,
                    ),
                  ),
              },
              if (state is FeedLoaded && state.posts.isNotEmpty)
                _PageProgressIndicator(
                  count: state.posts.length,
                  current: _currentIndex,
                ),
              AnimatedSlide(
                duration: AppMotion.medium,
                curve: Curves.easeOutCubic,
                offset:
                    _currentIndex == 0 ? Offset.zero : const Offset(0, -0.6),
                child: AnimatedOpacity(
                  duration: AppMotion.medium,
                  curve: Curves.easeOutCubic,
                  opacity: _currentIndex == 0 ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _currentIndex != 0,
                    child: SafeArea(child: _FloatingHeader()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedLoadingView extends StatelessWidget {
  const _FeedLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _FeedErrorView extends StatelessWidget {
  const _FeedErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TapBounce(
              scaleTo: 0.92,
              onTap: onRetry,
              child: FrostPanel(
                borderRadius: AppRadii.pill,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'try again',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
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

class _FeedEmptyView extends StatelessWidget {
  const _FeedEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'follow someone to fill the gap.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _ImmersivePageScrollPhysics extends PageScrollPhysics {
  const _ImmersivePageScrollPhysics({super.parent});

  static final SpringDescription _bouncySpring =
      SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100,
    ratio: 0.85,
  );

  @override
  _ImmersivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ImmersivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => _bouncySpring;
}

class _FloatingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          FrostPanel(
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lacuna',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterDot(label: 'following', active: true),
                const SizedBox(width: AppSpacing.xs),
                _FilterDot(label: 'live', active: false),
              ],
            ),
          ),
          const Spacer(),
          TapBounce(
            scaleTo: 0.85,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendOrFoePage(),
              ),
            ),
            child: FrostPanel(
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.gameController,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TapBounce(
            scaleTo: 0.85,
            onTap: () {},
            child: FrostPanel(
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Icon(
                PhosphorIconsLight.paperPlaneTilt,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDot extends StatelessWidget {
  const _FilterDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: AppMotion.short,
      style: TextStyle(
        color: active ? AppColors.textPrimary : AppColors.textTertiary,
        fontSize: 11,
        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
        letterSpacing: 0.4,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(label),
      ),
    );
  }
}

class _PageProgressIndicator extends StatelessWidget {
  const _PageProgressIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.xs,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final isActive = i == current;
            return AnimatedContainer(
              duration: AppMotion.short,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 3),
              width: 2,
              height: isActive ? 18 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}
