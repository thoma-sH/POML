import 'dart:async';

import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';
import 'package:first_flutter_app/features/game/domain/repos/game_repo.dart';
import 'package:first_flutter_app/features/game/presentation/cubits/game_session_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Drives a single in-progress game. Subscribes to the session row's
// realtime channel on init so opponent moves push in without polling,
// and exposes submitMove / forfeit as the only mutations. The state's
// `submittingMove` flag is purely UX — it prevents double-tap on slow
// networks and lets game widgets dim their controls while waiting.
class GameSessionCubit extends Cubit<GameSessionState> {
  GameSessionCubit({required GameRepo repo, required this.sessionId})
      : _repo = repo,
        super(const GameSessionLoading()) {
    _subscription = _repo.watchSession(sessionId).listen(
          _onSessionUpdate,
          onError: (Object e) =>
              emit(GameSessionFailure(_friendly(e))),
        );
  }

  final GameRepo _repo;
  final String sessionId;
  late final StreamSubscription<GameSession> _subscription;

  void _onSessionUpdate(GameSession session) {
    final current = state;
    if (current is GameSessionActive) {
      emit(current.copyWith(session: session, submittingMove: false));
    } else {
      emit(GameSessionActive(session: session));
    }
  }

  // Sends the next state for this session. Game widgets compute the new
  // state shape themselves and pass it in; this cubit doesn't know what
  // a tic-tac-toe board looks like and shouldn't.
  Future<void> submitMove({
    required Map<String, dynamic> newState,
    String? nextTurnId,
    String? winnerId,
  }) async {
    final current = state;
    if (current is! GameSessionActive) return;
    emit(current.copyWith(submittingMove: true));
    try {
      await _repo.submitMove(
        sessionId: sessionId,
        newState: newState,
        nextTurnId: nextTurnId,
        winnerId: winnerId,
      );
      // The realtime listener will emit the new session shortly; we
      // keep submittingMove true until then so the UI doesn't flicker
      // back to "your turn" before the server confirms.
    } catch (e) {
      emit(current.copyWith(submittingMove: false));
      emit(GameSessionFailure(_friendly(e)));
    }
  }

  Future<void> forfeit() async {
    try {
      await _repo.forfeit(sessionId);
    } catch (e) {
      emit(GameSessionFailure(_friendly(e)));
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('not_your_turn')) return 'Wait for your turn.';
    if (msg.contains('not_authenticated')) return 'Sign in to play.';
    if (msg.contains('not_found')) return 'This game has ended.';
    return 'Couldn\'t submit move. Try again.';
  }
}
