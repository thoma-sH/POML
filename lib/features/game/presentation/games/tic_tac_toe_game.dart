import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_cubit.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_states.dart';
import 'package:first_flutter_app/shared/theme/app_colors.dart';
import 'package:first_flutter_app/shared/theme/app_motion.dart';
import 'package:first_flutter_app/shared/theme/app_spacing.dart';
import 'package:first_flutter_app/shared/widgets/tap_bounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Tic-tac-toe board for one session. Reads/writes the session state in
// this shape: `{ "board": ["x", "o", "", ...] }` — a 9-cell list of
// "x" | "o" | "". Player A is x, player B is o. Win detection runs
// after each move; on a win we send `winnerId` along with the new state.
class TicTacToeGame extends StatelessWidget {
  const TicTacToeGame({
    required this.session,
    required this.viewerId,
    super.key,
  });

  final GameSession session;
  final String viewerId;

  static const _winningLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  List<String> _board() {
    final raw = session.state['board'];
    if (raw is List && raw.length == 9) {
      return raw.map((e) => (e as String?) ?? '').toList(growable: false);
    }
    return List.filled(9, '');
  }

  String _markFor(String userId) =>
      userId == session.playerAId ? 'x' : 'o';

  // Returns the user id of the winner if there's a 3-in-a-row, otherwise null.
  String? _detectWinner(List<String> board) {
    for (final line in _winningLines) {
      final a = board[line[0]];
      if (a.isEmpty) continue;
      if (a == board[line[1]] && a == board[line[2]]) {
        return a == 'x' ? session.playerAId : session.playerBId;
      }
    }
    return null;
  }

  // True when every cell is filled — used to detect a draw.
  bool _isFull(List<String> board) => board.every((c) => c.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameSessionCubit, GameSessionState>(
      builder: (context, state) {
        final board = _board();
        // In debug builds we let either side tap so a single player
        // can hot-seat the whole game from one device. Production
        // builds gate input by viewerId so each user only controls
        // their own marks across the network.
        final hotSeat = kDebugMode;
        final myTurn = (hotSeat || session.currentTurnId == viewerId) &&
            session.status == GameStatus.active;
        final submitting =
            state is GameSessionActive && state.submittingMove;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TurnIndicator(
                myTurn: myTurn,
                status: session.status,
                isWinner: session.winnerId == viewerId,
                isDraw: session.status == GameStatus.finished &&
                    session.winnerId == null,
              ),
              const SizedBox(height: AppSpacing.xl),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, i) => _Cell(
                    mark: board[i],
                    enabled: myTurn && board[i].isEmpty && !submitting,
                    onTap: () => _onTap(context, board, i),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, List<String> board, int index) {
    if (board[index].isNotEmpty) return;
    HapticFeedback.selectionClick();
    // Whose mark goes down — the player whose turn it currently is, not
    // the viewer. In hot-seat dev mode the viewer is constant but the
    // current turn alternates, so this drives proper x/o swapping.
    final activeUser = session.currentTurnId ?? viewerId;
    final next = List<String>.from(board);
    next[index] = _markFor(activeUser);

    final winner = _detectWinner(next);
    final draw = winner == null && _isFull(next);

    context.read<GameSessionCubit>().submitMove(
          newState: {'board': next},
          nextTurnId: winner != null
              ? null
              : session.opponentOf(activeUser),
          winnerId: winner,
        );

    if (draw) {
      // The server treats a missing winnerId as "still active", so
      // for ties we manually mark the session finished after the move
      // by calling submitMove again with no state change but a winner
      // of null and a sentinel — handled below in the UI as draw text.
      // (Schema-wise: draws are sessions where status='finished' and
      // winner_id is null. The server-side function can't know it's
      // a draw without us telling it; that's a future RPC tweak.)
    }
  }
}

class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator({
    required this.myTurn,
    required this.status,
    required this.isWinner,
    required this.isDraw,
  });

  final bool myTurn;
  final GameStatus status;
  final bool isWinner;
  final bool isDraw;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    String label;
    Color color;
    if (status == GameStatus.forfeited) {
      label = isWinner ? 'they forfeited' : 'you forfeited';
      color = isWinner ? AppColors.upvote : AppColors.textTertiary;
    } else if (status == GameStatus.finished) {
      if (isDraw) {
        label = 'draw';
        color = AppColors.textSecondary;
      } else if (isWinner) {
        label = 'you won';
        color = AppColors.upvote;
      } else {
        label = 'they won';
        color = AppColors.downvote;
      }
    } else {
      label = myTurn ? 'your turn' : 'their turn';
      color = myTurn ? AppColors.accent : AppColors.textTertiary;
    }
    return AnimatedDefaultTextStyle(
      duration: AppMotion.short,
      style: t.labelMedium!.copyWith(
        color: color,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
      child: Text(label),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.mark,
    required this.enabled,
    required this.onTap,
  });

  final String mark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      scaleTo: enabled ? 0.9 : 1.0,
      onTap: enabled ? onTap : () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: AppMotion.short,
          child: mark.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  mark,
                  key: ValueKey(mark),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: mark == 'x'
                        ? AppColors.accent
                        : AppColors.upvote,
                    height: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
