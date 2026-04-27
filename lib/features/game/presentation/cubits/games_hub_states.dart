import 'package:first_flutter_app/features/game/domain/entities/game_invite.dart';
import 'package:first_flutter_app/features/game/domain/entities/game_session.dart';

sealed class GamesHubState {
  const GamesHubState();
}

class GamesHubInitial extends GamesHubState {
  const GamesHubInitial();
}

class GamesHubLoading extends GamesHubState {
  const GamesHubLoading();
}

class GamesHubLoaded extends GamesHubState {
  const GamesHubLoaded({
    required this.activeSessions,
    required this.pendingInvites,
  });

  final List<GameSession> activeSessions;
  final List<GameInvite> pendingInvites;
}

class GamesHubFailure extends GamesHubState {
  const GamesHubFailure(this.message);
  final String message;
}
