import 'package:first_flutter_app/features/feed/presentation/widgets/feed_post_card.dart'
    show FeedPost;
import 'package:first_flutter_app/features/feed/presentation/widgets/verdict_pill.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme.dart';
import 'package:first_flutter_app/shared/theme/lacuna_theme_provider.dart';
import 'package:first_flutter_app/shared/widgets/shimmer_box.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImmersiveFeedTile extends StatefulWidget {
  const ImmersiveFeedTile({
    required this.post,
    required this.bottomInset,
    required this.headerInset,
    super.key,
  });

  final FeedPost post;
  final double bottomInset;
  final double headerInset;

  @override
  State<ImmersiveFeedTile> createState() => _ImmersiveFeedTileState();
}

class _ImmersiveFeedTileState extends State<ImmersiveFeedTile>
    with SingleTickerProviderStateMixin {
  FitVote _vote = FitVote.none;
  bool _saved = false;
  bool _captionExpanded = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _photoFade;
  late final Animation<double> _headlineFade;
  late final Animation<double> _actionsFade;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _headlineFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _photoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
    );
    _actionsFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _voteFits() {
    setState(() => _vote = _vote == FitVote.fits ? FitVote.none : FitVote.fits);
  }

  void _voteDoesntFit() {
    setState(
      () => _vote = _vote == FitVote.doesntFit ? FitVote.none : FitVote.doesntFit,
    );
  }

  void _toggleSave() {
    HapticFeedback.lightImpact();
    setState(() => _saved = !_saved);
  }

  int get _displayFits =>
      widget.post.fitsCount + (_vote == FitVote.fits ? 1 : 0);
  int get _displayDoesntFit =>
      widget.post.doesntFitCount + (_vote == FitVote.doesntFit ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: widget.headerInset,
              bottom: widget.bottomInset,
            ),
            child: Column(
              children: [
                _TopBar(post: post),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _headlineFade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(_headlineFade),
                    child: _AlbumHeadline(post: post),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: FadeTransition(
                    opacity: _photoFade,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0)
                          .animate(_photoFade),
                      child: Center(child: _PhotoFrame(post: post)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _actionsFade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_actionsFade),
                    child: _BottomChrome(
                      post: post,
                      vote: _vote,
                      fitsCount: _displayFits,
                      doesntFitCount: _displayDoesntFit,
                      saved: _saved,
                      captionExpanded: _captionExpanded,
                      onFits: _voteFits,
                      onDoesntFit: _voteDoesntFit,
                      onSave: _toggleSave,
                      onToggleCaption: () => setState(
                        () => _captionExpanded = !_captionExpanded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final initial = post.author.isEmpty ? '?' : post.author[0].toUpperCase();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  Color.lerp(post.blobColor, Colors.white, 0.25) ??
                      post.blobColor,
                  Color.lerp(post.blobColor, Colors.black, 0.4) ??
                      post.blobColor,
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '@${post.author.toLowerCase()}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            post.timeAgo,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          TapBounce(
            scaleTo: 0.85,
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                PhosphorIconsLight.dotsThree,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumHeadline extends StatelessWidget {
  const _AlbumHeadline({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: post.blobColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  post.blobName.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            '"${post.themeDescription}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final theme = LacunaThemeScope.of(context);
    final isLight = theme.palette.brightness == Brightness.light;
    final isGlass = theme.surfaceStyle == SurfaceStyle.liquidGlass ||
        theme.surfaceStyle == SurfaceStyle.frosted;

    final borderColor = isGlass
        ? Colors.white.withValues(alpha: 0.22)
        : post.blobColor;
    final borderWidth = isGlass ? 0.8 : 1.5;
    final shadowColor = isLight
        ? Colors.black.withValues(alpha: 0.12 * theme.depthShadow + 0.04)
        : Colors.black.withValues(alpha: 0.35 * theme.depthShadow + 0.15);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AspectRatio(
        aspectRatio: post.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl - borderWidth),
            child: _PhotoContent(post: post),
          ),
        ),
      ),
    );
  }
}

class _PhotoContent extends StatelessWidget {
  const _PhotoContent({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      post.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ShimmerBox(tint: post.blobColor.withValues(alpha: 0.35));
      },
      errorBuilder: (context, error, stack) =>
          _GradientFallback(color: post.blobColor),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 1.5,
          colors: [
            Color.lerp(color, Colors.white, 0.18) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.7) ?? color,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.post,
    required this.vote,
    required this.fitsCount,
    required this.doesntFitCount,
    required this.saved,
    required this.captionExpanded,
    required this.onFits,
    required this.onDoesntFit,
    required this.onSave,
    required this.onToggleCaption,
  });

  final FeedPost post;
  final FitVote vote;
  final int fitsCount;
  final int doesntFitCount;
  final bool saved;
  final bool captionExpanded;
  final VoidCallback onFits;
  final VoidCallback onDoesntFit;
  final VoidCallback onSave;
  final VoidCallback onToggleCaption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggleCaption,
            behavior: HitTestBehavior.opaque,
            child: AnimatedSize(
              duration: AppMotion.short,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Text(
                post.caption,
                maxLines: captionExpanded ? null : 2,
                overflow: captionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (post.location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  PhosphorIconsLight.mapPin,
                  color: AppColors.textTertiary,
                  size: 11,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    post.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ActionCluster(
            post: post,
            vote: vote,
            fitsCount: fitsCount,
            doesntFitCount: doesntFitCount,
            saved: saved,
            onFits: onFits,
            onDoesntFit: onDoesntFit,
            onSave: onSave,
          ),
        ],
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.post,
    required this.vote,
    required this.fitsCount,
    required this.doesntFitCount,
    required this.saved,
    required this.onFits,
    required this.onDoesntFit,
    required this.onSave,
  });

  final FeedPost post;
  final FitVote vote;
  final int fitsCount;
  final int doesntFitCount;
  final bool saved;
  final VoidCallback onFits;
  final VoidCallback onDoesntFit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VerdictPill(
          vote: vote,
          fitsCount: fitsCount,
          doesntFitCount: doesntFitCount,
          themeColor: post.blobColor,
          onFits: onFits,
          onDoesntFit: onDoesntFit,
        ),
        const SizedBox(width: AppSpacing.md),
        _IconAction(
          icon: PhosphorIconsLight.chatCircle,
          label: '${post.commentCount}',
          color: AppColors.textSecondary,
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.md),
        _IconAction(
          icon: saved
              ? PhosphorIconsFill.bookmarkSimple
              : PhosphorIconsLight.bookmarkSimple,
          color: saved ? AppColors.accent : AppColors.textSecondary,
          onTap: onSave,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      scaleTo: 0.85,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.borderHairline, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.short,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(icon, key: ValueKey(icon), color: color, size: 18),
            ),
            if (label != null) ...[
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
