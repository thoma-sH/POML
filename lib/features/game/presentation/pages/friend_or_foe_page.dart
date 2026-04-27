import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/breathing_blob.dart';
import 'package:first_flutter_app/shared/widgets/grain_overlay.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum GameType {
  eightBall('8 Ball'),
  archery('Archery'),
  chess('Chess'),
  scrabble('Word Hunt');

  const GameType(this.label);
  final String label;
}

IconData _iconForGame(GameType type) => switch (type) {
  GameType.eightBall => PhosphorIconsFill.circle,
  GameType.archery => PhosphorIconsLight.crosshair,
  GameType.chess => PhosphorIconsLight.crown,
  GameType.scrabble => PhosphorIconsLight.puzzlePiece,
};

class GameStat {
  const GameStat({
    required this.type,
    required this.wins,
    required this.losses,
  });

  final GameType type;
  final int wins;
  final int losses;

  int get lacuna => wins - losses;
  int get played => wins + losses;
}

class GameRival {
  const GameRival({
    required this.handle,
    required this.avatarColor,
    required this.yourWins,
    required this.yourLosses,
    required this.recentGame,
  });

  final String handle;
  final Color avatarColor;
  final int yourWins;
  final int yourLosses;
  final String? recentGame;
}

const _mockStats = <GameStat>[
  GameStat(type: GameType.eightBall, wins: 12, losses: 3),
  GameStat(type: GameType.chess, wins: 4, losses: 1),
  GameStat(type: GameType.scrabble, wins: 7, losses: 6),
  GameStat(type: GameType.archery, wins: 0, losses: 0),
];

const _mockRivals = <GameRival>[
  GameRival(
    handle: 'mia.s',
    avatarColor: Color(0xFF4F6B8A),
    yourWins: 2,
    yourLosses: 1,
    recentGame: '8 Ball',
  ),
  GameRival(
    handle: 'theo.k',
    avatarColor: Color(0xFF7E5A8C),
    yourWins: 0,
    yourLosses: 0,
    recentGame: null,
  ),
  GameRival(
    handle: 'sam.r',
    avatarColor: Color(0xFF5C7A56),
    yourWins: 5,
    yourLosses: 3,
    recentGame: 'Chess',
  ),
  GameRival(
    handle: 'june.w',
    avatarColor: Color(0xFF7A5C3A),
    yourWins: 1,
    yourLosses: 4,
    recentGame: 'Word Hunt',
  ),
  GameRival(
    handle: 'cass.v',
    avatarColor: Color(0xFF8C4A3A),
    yourWins: 3,
    yourLosses: 2,
    recentGame: 'Archery',
  ),
];

class FriendOrFoePage extends StatefulWidget {
  const FriendOrFoePage({this.postLacuna = 247, super.key});

  final int postLacuna;

  @override
  State<FriendOrFoePage> createState() => _FriendOrFoePageState();
}

class _FriendOrFoePageState extends State<FriendOrFoePage>
    with SingleTickerProviderStateMixin {
  static const _entranceMs = 800;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: _entranceMs),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  int get _gameLacuna => _mockStats.fold(0, (sum, s) => sum + s.lacuna);
  int get _totalLacuna => widget.postLacuna + _gameLacuna;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _PageHeader()),
                SliverToBoxAdapter(child: _PageTitle()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: _LacunaTotalCard(
                    total: _totalLacuna,
                    postLacuna: widget.postLacuna,
                    gameLacuna: _gameLacuna,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
                const SliverToBoxAdapter(
                  child: _SectionLabel(label: 'your record'),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                const SliverToBoxAdapter(child: _StatsCard(stats: _mockStats)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
                const SliverToBoxAdapter(
                  child: _SectionLabel(label: 'ready for a duel?'),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                _RivalsList(
                  rivals: _mockRivals,
                  entrance: _entranceCtrl,
                  totalDurationMs: _entranceMs,
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge + AppSpacing.xl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'friend or foe?',
                  style: t.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.0,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                PhosphorIconsLight.gameController,
                color: AppColors.accent,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'duel your friends. win lacuna. lose lacuna. fair is fair.',
            style: t.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LacunaTotalCard extends StatelessWidget {
  const _LacunaTotalCard({
    required this.total,
    required this.postLacuna,
    required this.gameLacuna,
  });

  final int total;
  final int postLacuna;
  final int gameLacuna;

  String _fmt(int n) => n >= 0 ? '+$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDeep.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BreathingBlob(color: AppColors.accent, size: 12),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'TOTAL LACUNA',
                  style: t.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.6,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _fmt(total),
              style: t.displayMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w300,
                letterSpacing: -2.0,
                height: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniStat(label: 'from posts', value: _fmt(postLacuna)),
                  VerticalDivider(
                    width: AppSpacing.xxl,
                    color: AppColors.borderSubtle,
                    thickness: 1,
                    indent: 4,
                    endIndent: 4,
                  ),
                  _MiniStat(label: 'from games', value: _fmt(gameLacuna)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: t.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final List<GameStat> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: Column(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              _StatRow(stat: stats[i]),
              if (i < stats.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderSubtle,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final GameStat stat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lacunaColor = stat.lacuna > 0
        ? AppColors.accent
        : stat.lacuna < 0
        ? AppColors.downvote
        : AppColors.textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface3,
            ),
            alignment: Alignment.center,
            child: Icon(
              _iconForGame(stat.type),
              color: AppColors.textSecondary,
              size: 14,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Spacer(),
          if (stat.played > 0) ...[
            Text(
              '${stat.wins}',
              style: t.bodyMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '  ·  ',
              style: t.bodyMedium?.copyWith(color: AppColors.textDisabled),
            ),
            Text(
              '${stat.losses}',
              style: t.bodyMedium?.copyWith(
                color: AppColors.downvote,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: lacunaColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                stat.lacuna >= 0 ? '+${stat.lacuna}' : '${stat.lacuna}',
                style: TextStyle(
                  color: lacunaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ] else
            Text(
              'never played',
              style: t.bodySmall?.copyWith(
                color: AppColors.textDisabled,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _RivalsList extends StatelessWidget {
  const _RivalsList({
    required this.rivals,
    required this.entrance,
    required this.totalDurationMs,
  });

  final List<GameRival> rivals;
  final AnimationController entrance;
  final int totalDurationMs;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final start = (index * 70) / totalDurationMs;
          final end = (start + 0.45).clamp(0.0, 1.0);
          final interval = CurvedAnimation(
            parent: entrance,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: interval,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(interval),
              child: _RivalTile(rival: rivals[index]),
            ),
          );
        }, childCount: rivals.length),
      ),
    );
  }
}

class _RivalTile extends StatelessWidget {
  const _RivalTile({required this.rival});

  final GameRival rival;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final played = rival.yourWins + rival.yourLosses;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [
                    Color.lerp(rival.avatarColor, Colors.white, 0.25) ??
                        rival.avatarColor,
                    Color.lerp(rival.avatarColor, Colors.black, 0.4) ??
                        rival.avatarColor,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                rival.handle[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${rival.handle}',
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (played > 0)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'you ',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          TextSpan(
                            text: '${rival.yourWins}',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' – ',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                          TextSpan(
                            text: '${rival.yourLosses}',
                            style: t.labelSmall?.copyWith(
                              color: AppColors.downvote,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (rival.recentGame != null)
                            TextSpan(
                              text: '  ·  ${rival.recentGame}',
                              style: t.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'never played. dare you?',
                      style: t.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _DuelButton(handle: rival.handle),
          ],
        ),
      ),
    );
  }
}

class _DuelButton extends StatelessWidget {
  const _DuelButton({required this.handle});

  final String handle;

  void _sendChallenge(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                PhosphorIconsLight.gameController,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('challenge sent to @$handle')),
            ],
          ),
          backgroundColor: AppColors.accentDeep,
          duration: AppMotion.long * 4,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.huge + AppSpacing.lg,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TapBounce(
      scaleTo: 0.85,
      onTap: () => _sendChallenge(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentDeep.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.55),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.18),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsLight.gameController,
              color: AppColors.accent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'duel',
              style: t.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
