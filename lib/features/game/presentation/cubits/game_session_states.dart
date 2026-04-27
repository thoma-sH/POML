import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';

sealed class GameSessionState {
  const GameSessionState();
}

class GameSessionLoading extends GameSessionState {
  const GameSessionLoading();
}

class GameSessionActive extends GameSessionState {
  const GameSessionActive({
    required this.session,
    this.submittingMove = false,
  });

  final GameSession session;
  final bool submittingMove;

  GameSessionActive copyWith({GameSession? session, bool? submittingMove}) {
    return GameSessionActive(
      session: session ?? this.session,
      submittingMove: submittingMove ?? this.submittingMove,
    );
  }
}

class GameSessionFailure extends GameSessionState {
  const GameSessionFailure(this.message);
  final String message;
}
